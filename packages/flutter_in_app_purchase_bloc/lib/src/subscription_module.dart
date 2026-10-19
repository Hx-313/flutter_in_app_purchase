import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import 'subscription_bloc.dart';

/// Composition helpers for applications choosing the optional BLoC adapter.
final class SubscriptionBlocModule {
  const SubscriptionBlocModule._();

  static SubscriptionBloc createBloc({
    required SubscriptionConfig config,
    SubscriptionRepository? repository,
    StoreDataSource? store,
    SubscriptionStorageDataSource? storage,
    PurchaseVerifier? verifier,
  }) => SubscriptionBloc(
    service: SubscriptionModule.createService(
      config: config,
      repository: repository,
      store: store,
      storage: storage,
      verifier: verifier,
    ),
  );
}
