import '../entities/entitlement.dart';
import '../entities/product_definition.dart';
import '../entities/store_product.dart';
import '../entities/store_purchase.dart';

/// Domain-facing contract for store access and durable purchase state.
abstract interface class SubscriptionRepository {
  bool get isAvailable;
  List<StoreProduct> get products;
  Stream<StorePurchase> get purchaseStream;

  Future<void> initialize(
    List<ProductDefinition> products,
    String storageKeyPrefix,
  );
  Future<void> purchase(String productId);
  Future<void> restore();
  Future<List<StorePurchase>> queryExistingPurchases();
  Future<void> complete(StorePurchase purchase);

  Future<Map<String, Entitlement>> loadEntitlements();
  Future<void> saveEntitlement(Entitlement entitlement);
  Future<void> removeEntitlement(String entitlementId);
  Future<bool> isPurchaseProcessed(String purchaseId);
  Future<void> markPurchaseProcessed(String purchaseId);
  Future<void> dispose();
}
