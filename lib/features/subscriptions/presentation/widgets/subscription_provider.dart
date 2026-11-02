import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../data/datasources/store_data_source.dart';
import '../../data/datasources/subscription_storage_data_source.dart';
import '../../domain/entities/subscription_config.dart';
import '../../domain/entities/verification.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../subscription_module.dart';
import '../controllers/subscription_controller.dart';
import '../entities/subscription_callbacks.dart';

/// Owns one subscription service for the whole app.
///
/// Place this above the widget tree that reads subscription state. The provider
/// creates the service, initializes it, keeps listening while the app runs,
/// dispatches [callbacks], and disposes the service. Purchases that finish while
/// no paywall is on screen are still processed.
///
/// ```dart
/// SubscriptionProvider(config: config, child: MyApp())
/// ```
class SubscriptionProvider extends StatefulWidget {
  const SubscriptionProvider({
    super.key,
    required this.config,
    required this.child,
    this.callbacks = const SubscriptionCallbacks(),
    this.messageBuilder,
    this.verifier,
    this.store,
    this.storage,
    this.repository,
    this.purchaseTimeout = const Duration(minutes: 2),
  });

  /// Products, entitlement ids, verification mode, and storage scope.
  ///
  /// `SubscriptionConfig` has value equality, so building an equal config inside
  /// `build()` does not recreate the service.
  final SubscriptionConfig config;

  final Widget child;

  /// Optional lifecycle hooks.
  final SubscriptionCallbacks callbacks;

  /// Optional localizer for host-facing result text.
  final SubscriptionMessageBuilder? messageBuilder;

  /// Optional injected purchase verifier for server-verified mode.
  final PurchaseVerifier? verifier;

  /// Optional injected store adapter, primarily for tests.
  final StoreDataSource? store;

  /// Optional injected storage adapter, primarily for tests.
  final SubscriptionStorageDataSource? storage;

  /// Optional injected repository, primarily for tests.
  final SubscriptionRepository? repository;

  /// How long `purchase()` waits for the store to report an outcome.
  final Duration purchaseTimeout;

  /// Reads the controller from the nearest [SubscriptionProvider].
  static SubscriptionController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'SubscriptionProvider.of() was called with a context that does not '
      'contain a SubscriptionProvider.',
    );
    return controller!;
  }

  /// Reads the controller if one is present, otherwise returns null.
  static SubscriptionController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SubscriptionScope>()
      ?.controller;

  @override
  State<SubscriptionProvider> createState() => _SubscriptionProviderState();
}

class _SubscriptionProviderState extends State<SubscriptionProvider> {
  late SubscriptionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  SubscriptionController _createController() {
    final service = SubscriptionModule.createService(
      config: widget.config,
      verifier: widget.verifier,
      store: widget.store,
      storage: widget.storage,
      repository: widget.repository,
      purchaseTimeout: widget.purchaseTimeout,
    );
    final controller = SubscriptionController(
      service: service,
      callbacks: widget.callbacks,
      messageBuilder: widget.messageBuilder,
    );
    unawaited(controller.initialize());
    return controller;
  }

  @override
  void didUpdateWidget(covariant SubscriptionProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final needsNewService =
        widget.config != oldWidget.config ||
        !identical(widget.verifier, oldWidget.verifier) ||
        !identical(widget.store, oldWidget.store) ||
        !identical(widget.storage, oldWidget.storage) ||
        !identical(widget.repository, oldWidget.repository) ||
        widget.purchaseTimeout != oldWidget.purchaseTimeout;

    if (needsNewService) {
      final previous = _controller;
      _controller = _createController();
      unawaited(previous.dispose());
      return;
    }

    if (!identical(widget.callbacks, oldWidget.callbacks) ||
        !identical(widget.messageBuilder, oldWidget.messageBuilder)) {
      _controller.updateCallbacks(
        callbacks: widget.callbacks,
        messageBuilder: widget.messageBuilder,
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      _SubscriptionScope(controller: _controller, child: widget.child);

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }
}

class _SubscriptionScope extends InheritedWidget {
  const _SubscriptionScope({required this.controller, required super.child});

  final SubscriptionController controller;

  @override
  bool updateShouldNotify(_SubscriptionScope oldWidget) =>
      controller != oldWidget.controller;
}
