import '../../domain/entities/entitlement.dart';

/// Data-source contract for persisted entitlements and processed transactions.
abstract interface class SubscriptionStorageDataSource {
  Future<void> initialize(String keyPrefix);
  Future<Map<String, Entitlement>> loadEntitlements();
  Future<void> saveEntitlement(Entitlement entitlement);
  Future<void> removeEntitlement(String entitlementId);
  Future<bool> isPurchaseProcessed(String purchaseId);
  Future<void> markPurchaseProcessed(String purchaseId);
  Future<void> dispose();
}

/// Backward-compatible public name for injected storage fakes.
typedef SubscriptionStorage = SubscriptionStorageDataSource;
