import 'data/datasources/in_app_purchase_store_data_source.dart';
import 'data/datasources/shared_preferences_subscription_storage_data_source.dart';
import 'data/datasources/store_data_source.dart';
import 'data/datasources/subscription_storage_data_source.dart';
import 'data/repositories/subscription_repository_impl.dart';
import 'domain/entities/subscription_config.dart';
import 'domain/entities/verification.dart';
import 'domain/repositories/subscription_repository.dart';
import 'domain/usecases/subscription_service.dart';

/// Composition root for the subscriptions feature.
final class SubscriptionModule {
  const SubscriptionModule._();

  /// Creates the state-management-neutral service used by a host application.
  static SubscriptionService createService({
    required SubscriptionConfig config,
    SubscriptionRepository? repository,
    StoreDataSource? store,
    SubscriptionStorageDataSource? storage,
    PurchaseVerifier? verifier,
  }) {
    final resolvedRepository =
        repository ??
        SubscriptionRepositoryImpl(
          store: store ?? InAppPurchaseStoreDataSource(),
          storage: storage ?? SharedPreferencesSubscriptionStorageDataSource(),
        );
    return SubscriptionService(
      config: config,
      repository: resolvedRepository,
      verifier: verifier,
    );
  }
}
