import '../../domain/entities/product_definition.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/entities/store_purchase.dart';

/// Data-source contract for the platform purchase SDK.
abstract interface class StoreDataSource {
  bool get isAvailable;
  List<StoreProduct> get products;
  Stream<StorePurchase> get purchaseStream;

  Future<void> initialize(List<ProductDefinition> products);
  Future<void> purchase(String productId);
  Future<void> restore();
  Future<List<StorePurchase>> queryExistingPurchases();
  Future<void> complete(StorePurchase purchase);
  Future<void> dispose();
}

/// Backward-compatible public name for injected store fakes.
typedef SubscriptionStore = StoreDataSource;
