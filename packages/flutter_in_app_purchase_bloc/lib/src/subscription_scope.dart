import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

import 'subscription_bloc.dart';
import 'subscription_event.dart';
import 'subscription_module.dart';

/// Creates, initializes, exposes, and disposes an optional BLoC adapter.
class SubscriptionScope extends StatelessWidget {
  const SubscriptionScope({
    super.key,
    required this.config,
    required this.child,
    this.repository,
    this.store,
    this.storage,
    this.verifier,
  });

  final SubscriptionConfig config;
  final SubscriptionRepository? repository;
  final StoreDataSource? store;
  final SubscriptionStorageDataSource? storage;
  final PurchaseVerifier? verifier;
  final Widget child;

  static SubscriptionBloc of(BuildContext context) =>
      context.read<SubscriptionBloc>();

  @override
  Widget build(BuildContext context) => BlocProvider<SubscriptionBloc>(
    create: (_) {
      final bloc = SubscriptionBlocModule.createBloc(
        config: config,
        repository: repository,
        store: store,
        storage: storage,
        verifier: verifier,
      );
      bloc.add(const SubscriptionInitializeRequested());
      return bloc;
    },
    child: child,
  );
}
