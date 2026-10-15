import 'dart:async';

import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local store simulator used by the example; no account or store setup needed.
final class SimulatedStoreDataSource implements StoreDataSource {
  static const _ledgerKey = 'flutter_in_app_purchase.example.demo_ledger.v1';

  final _updates = StreamController<StorePurchase>.broadcast();
  Set<String> _ownedProductIds = <String>{};
  Set<String> _configuredProductIds = <String>{};
  List<StoreProduct> _products = const <StoreProduct>[];
  bool _disposed = false;
  int completionCount = 0;

  @override
  bool get isAvailable => true;

  @override
  List<StoreProduct> get products => List.unmodifiable(_products);

  @override
  Stream<StorePurchase> get purchaseStream => _updates.stream;

  @override
  Future<void> initialize(List<ProductDefinition> products) async {
    _ensureOpen();
    _configuredProductIds = products.map((product) => product.id).toSet();
    final preferences = await SharedPreferences.getInstance();
    _ownedProductIds =
        preferences.getStringList(_ledgerKey)?.toSet() ?? <String>{};
    _products = [
      for (final product in products)
        StoreProduct(
          id: product.id,
          title: product.displayName ?? _titleFor(product.id),
          description: _descriptionFor(product.id),
          price: _priceFor(product.id),
          rawPrice: _rawPriceFor(product.id),
          currencyCode: 'USD',
        ),
    ];
  }

  @override
  Future<void> purchase(String productId) async {
    _ensureOpen();
    if (!_configuredProductIds.contains(productId)) {
      throw ArgumentError.value(productId, 'productId', 'Unknown demo product');
    }
    _ownedProductIds.add(productId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_ledgerKey, _ownedProductIds.toList());
    _updates.add(
      StorePurchase(
        productId: productId,
        purchaseId: _purchaseId(productId),
        transactionDate: DateTime.now(),
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    );
  }

  @override
  Future<void> restore() async {
    _ensureOpen();
  }

  @override
  Future<List<StorePurchase>> queryExistingPurchases() async {
    _ensureOpen();
    return [
      for (final productId in _ownedProductIds)
        if (_configuredProductIds.contains(productId))
          StorePurchase(
            productId: productId,
            purchaseId: _purchaseId(productId),
            status: StorePurchaseStatus.restored,
          ),
    ];
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    _ensureOpen();
    completionCount++;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _updates.close();
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Simulated store has been disposed.');
  }

  String _purchaseId(String productId) => 'simulated-$productId';

  String _titleFor(String productId) => switch (productId) {
    'pro_monthly' => 'Monthly',
    'pro_annual' => 'Annual',
    'pro_lifetime' => 'Lifetime',
    _ => productId,
  };

  String _descriptionFor(String productId) => switch (productId) {
    'pro_monthly' => 'Flexible access, billed monthly.',
    'pro_annual' => 'One simple annual plan.',
    'pro_lifetime' => 'A single purchase for permanent access.',
    _ => 'Demo access plan.',
  };

  String _priceFor(String productId) => switch (productId) {
    'pro_monthly' => r'$4.99 / month',
    'pro_annual' => r'$39.99 / year',
    'pro_lifetime' => r'$79.99 once',
    _ => r'$0.99',
  };

  double _rawPriceFor(String productId) => switch (productId) {
    'pro_monthly' => 4.99,
    'pro_annual' => 39.99,
    'pro_lifetime' => 79.99,
    _ => 0.99,
  };
}
