import '../../domain/entities/entitlement.dart';
import '../../domain/entities/product_definition.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/entities/store_purchase.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/store_data_source.dart';
import '../datasources/subscription_storage_data_source.dart';

/// Composes store and persistence data sources behind one domain contract.
final class SubscriptionRepositoryImpl implements SubscriptionRepository {
  const SubscriptionRepositoryImpl({
    required this.store,
    required this.storage,
  });

  final StoreDataSource store;
  final SubscriptionStorageDataSource storage;

  @override
  bool get isAvailable => store.isAvailable;

  @override
  List<StoreProduct> get products => store.products;

  @override
  Stream<StorePurchase> get purchaseStream => store.purchaseStream;

  @override
  Future<void> initialize(
    List<ProductDefinition> products,
    String storageKeyPrefix,
  ) async {
    await storage.initialize(storageKeyPrefix);
    await store.initialize(products);
  }

  @override
  Future<void> purchase(String productId) => store.purchase(productId);

  @override
  Future<void> restore() => store.restore();

  @override
  Future<List<StorePurchase>> queryExistingPurchases() =>
      store.queryExistingPurchases();

  @override
  Future<void> complete(StorePurchase purchase) => store.complete(purchase);

  @override
  Future<Map<String, Entitlement>> loadEntitlements() =>
      storage.loadEntitlements();

  @override
  Future<void> saveEntitlement(Entitlement entitlement) =>
      storage.saveEntitlement(entitlement);

  @override
  Future<void> removeEntitlement(String entitlementId) =>
      storage.removeEntitlement(entitlementId);

  @override
  Future<bool> isPurchaseProcessed(String purchaseId) =>
      storage.isPurchaseProcessed(purchaseId);

  @override
  Future<void> markPurchaseProcessed(String purchaseId) =>
      storage.markPurchaseProcessed(purchaseId);

  @override
  Future<void> dispose() async {
    await store.dispose();
    await storage.dispose();
  }
}
