import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/consumable_delivery.dart';
import '../../domain/entities/purchase_result.dart';
import '../../domain/entities/subscription_snapshot.dart';
import '../../domain/entities/subscription_types.dart';
import '../../domain/usecases/subscription_service.dart';
import '../entities/subscription_callbacks.dart';
import '../entities/subscription_view_state.dart';

/// Neutral host-facing message used when no [SubscriptionMessageBuilder] is
/// supplied.
String defaultPurchaseStatusMessage(PurchaseResult result) =>
    switch (result.status) {
      PurchaseStatus.success => 'Purchase completed.',
      PurchaseStatus.restored => 'Purchases restored.',
      PurchaseStatus.pending => 'The purchase is pending approval.',
      PurchaseStatus.canceled => 'The purchase was canceled.',
      PurchaseStatus.alreadyOwned => 'You already own this item.',
      PurchaseStatus.notAvailable => 'The item is not available right now.',
      PurchaseStatus.networkError => 'The network connection failed.',
      PurchaseStatus.verificationFailed =>
        'The purchase could not be verified.',
      PurchaseStatus.error => 'The purchase could not be completed.',
    };

/// Owns a [SubscriptionService] for the lifetime of [SubscriptionProvider].
///
/// Hosts rarely construct this directly; use `SubscriptionProvider` and read
/// `SubscriptionViewState` inside a `SubscriptionView`.
final class SubscriptionController implements SubscriptionActions {
  SubscriptionController({
    required SubscriptionService service,
    SubscriptionCallbacks callbacks = const SubscriptionCallbacks(),
    SubscriptionMessageBuilder? messageBuilder,
  }) : _service = service {
    _callbacks = callbacks;
    _messageBuilder = messageBuilder;
    _state = ValueNotifier<SubscriptionViewState>(_buildState(service.snapshot));
    _snapshotSubscription = service.snapshotStream.listen(_onSnapshot);
    _consumableSubscription = service.consumableDeliveryStream.listen(
      _onConsumables,
    );
  }

  final SubscriptionService _service;
  late SubscriptionCallbacks _callbacks;
  SubscriptionMessageBuilder? _messageBuilder;

  late final ValueNotifier<SubscriptionViewState> _state;
  StreamSubscription<SubscriptionSnapshot>? _snapshotSubscription;
  StreamSubscription<List<ConsumableDelivery>>? _consumableSubscription;

  final Set<String> _attemptedConsumables = <String>{};
  PurchaseResult? _lastDispatchedResult;
  bool _disposed = false;

  /// The underlying service, for advanced integrations and tests.
  SubscriptionService get service => _service;

  /// Current state, for hosts outside a `SubscriptionView`.
  SubscriptionViewState get currentState => _state.value;

  /// Notifies listeners whenever the view state changes.
  ValueListenable<SubscriptionViewState> get state => _state;

  /// Whether the underlying service has finished initializing.
  bool get isInitialized => _service.isInitialized;

  /// Initializes the underlying service and reports failures through
  /// `SubscriptionCallbacks.onInitializationFailed`.
  Future<void> initialize() async {
    try {
      await _service.initialize();
    } on Object catch (error, stackTrace) {
      _callbacks.onInitializationFailed?.call(error, stackTrace);
    }
  }

  /// Replaces the callbacks and message builder without recreating the service.
  void updateCallbacks({
    required SubscriptionCallbacks callbacks,
    SubscriptionMessageBuilder? messageBuilder,
  }) {
    _callbacks = callbacks;
    _messageBuilder = messageBuilder;
    _state.value = _buildState(_service.snapshot);
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    final gate = _callbacks.beforePurchase;
    if (gate != null) {
      final allowed = await gate(productId);
      if (!allowed) {
        return PurchaseResult(
          status: PurchaseStatus.canceled,
          productId: productId,
          message: 'The purchase was canceled before it started.',
        );
      }
    }
    return _service.purchase(productId);
  }

  @override
  Future<RestoreResult> restore() async {
    final result = await _service.restore();
    _callbacks.onRestoreFinished?.call(result);
    return result;
  }

  @override
  Future<void> acknowledgeConsumable(String purchaseId) =>
      _service.acknowledgeConsumablePurchase(purchaseId);

  /// Retries every staged consumable delivery that is still pending.
  Future<void> retryPendingConsumables() async {
    _attemptedConsumables.clear();
    for (final delivery in _service.pendingConsumables) {
      _startFulfillment(delivery);
    }
  }

  /// Releases the underlying service and stops dispatching callbacks.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    // Starts synchronously so the service cancels its own timers immediately.
    final serviceDisposal = _service.dispose();
    await _snapshotSubscription?.cancel();
    await _consumableSubscription?.cancel();
    await serviceDisposal;
    _state.dispose();
  }

  SubscriptionViewState _buildState(SubscriptionSnapshot snapshot) =>
      SubscriptionViewState(
        actions: this,
        phase: snapshot.phase,
        products: snapshot.products,
        entitlements: snapshot.entitlements,
        pendingConsumables: snapshot.pendingConsumables,
        defaultEntitlementId: snapshot.defaultEntitlementId,
        isPurchasing: snapshot.isPurchasing,
        isRestoring: snapshot.isRestoring,
        lastResult: snapshot.lastResult,
        lastRestoreStatus: snapshot.lastRestoreStatus,
        errorMessage: snapshot.errorMessage,
        statusMessage: _messageFor(snapshot.lastResult),
        isStoreAvailable: snapshot.isStoreAvailable,
      );

  String? _messageFor(PurchaseResult? result) {
    if (result == null) return null;
    final builder = _messageBuilder;
    return builder != null ? builder(result) : defaultPurchaseStatusMessage(result);
  }

  void _onSnapshot(SubscriptionSnapshot snapshot) {
    if (_disposed) return;
    final previous = _state.value;
    final next = _buildState(snapshot);
    _state.value = next;
    _dispatch(previous, next);
  }

  void _dispatch(SubscriptionViewState previous, SubscriptionViewState next) {
    if (next.phase != previous.phase) {
      switch (next.phase) {
        case SubscriptionPhase.ready:
          _callbacks.onReady?.call(next);
        case SubscriptionPhase.unavailable:
          _callbacks.onStoreUnavailable?.call();
        default:
          break;
      }
    }

    if (next.hasAccess != previous.hasAccess) {
      _callbacks.onAccessChanged?.call(next.hasAccess);
    }

    final result = next.lastResult;
    if (result == null || identical(result, _lastDispatchedResult)) return;
    _lastDispatchedResult = result;
    switch (result.status) {
      case PurchaseStatus.success:
      case PurchaseStatus.restored:
        _callbacks.onPurchaseSuccess?.call(result);
      case PurchaseStatus.pending:
        _callbacks.onPurchasePending?.call(result);
      case PurchaseStatus.canceled:
        _callbacks.onPurchaseCanceled?.call(result);
      case PurchaseStatus.error:
      case PurchaseStatus.networkError:
      case PurchaseStatus.verificationFailed:
        _callbacks.onPurchaseError?.call(result);
      case PurchaseStatus.alreadyOwned:
      case PurchaseStatus.notAvailable:
        break;
    }
  }

  void _onConsumables(List<ConsumableDelivery> deliveries) {
    if (_disposed) return;
    for (final delivery in deliveries) {
      _startFulfillment(delivery);
    }
  }

  void _startFulfillment(ConsumableDelivery delivery) {
    if (_callbacks.onConsumablePurchased == null) return;
    if (!_attemptedConsumables.add(delivery.purchaseId)) return;
    unawaited(_fulfill(delivery));
  }

  Future<void> _fulfill(ConsumableDelivery delivery) async {
    final callback = _callbacks.onConsumablePurchased;
    if (callback == null) return;

    bool handled;
    try {
      handled = await callback(delivery);
    } on Object {
      return;
    }
    if (!handled || _disposed) return;

    try {
      await _service.acknowledgeConsumablePurchase(delivery.purchaseId);
    } on Object {
      // Leave the delivery staged so a later retry can acknowledge it.
      _attemptedConsumables.remove(delivery.purchaseId);
    }
  }
}
