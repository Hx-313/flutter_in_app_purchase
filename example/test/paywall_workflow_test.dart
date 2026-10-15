import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

import 'package:flutter_in_app_purchase_example/demo/demo_subscription_host.dart';
import 'package:flutter_in_app_purchase_example/ithx_theme.dart';
import 'package:flutter_in_app_purchase_example/screens/locked_feature_screen.dart';
import 'package:flutter_in_app_purchase_example/templates/full_screen_paywall.dart';

void main() {
  testWidgets('locked feature purchase unlocks content and returns to it', (
    tester,
  ) async {
    late _WorkflowStore store;
    late SubscriptionService service;
    late Future<PurchaseResult> success;
    await tester.runAsync(() async {
      store = _WorkflowStore();
      service = SubscriptionModule.createService(
        config: demoSubscriptionConfig,
        store: store,
        storage: _MemoryStorage(),
      );
      await service.initialize();
      success = service.purchaseResultStream.firstWhere(
        (result) => result.status == PurchaseStatus.success,
      );
    });
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildIthxTheme(),
          home: Builder(
            builder: (context) => LockedFeatureScreen(
              service: service,
              onUnlock: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (routeContext) => FullScreenPaywall(
                    service: service,
                    onClose: () => Navigator.of(routeContext).pop(),
                    onAccessGranted: () => Navigator.of(routeContext).pop(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A quieter space for you'), findsOneWidget);

      await tester.tap(find.text('See unlock options'));
      await tester.pumpAndSettle();
      expect(find.text('Make room for your best work.'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Unlock premium'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock premium'));
      await tester.pump();
      expect(store.purchaseCount, 1);
      store.emitPurchased('pro_annual');
      await tester.runAsync(() => success.timeout(const Duration(seconds: 2)));
      await tester.pump();
      await tester.idle();
      expect(service.snapshot.hasAccess('premium'), isTrue);
      expect(find.text('You’re unlocked.'), findsOneWidget);

      await tester.tap(find.text('Continue to feature'));
      await tester.pumpAndSettle();
      expect(find.text('Your space is ready'), findsOneWidget);
      expect(find.text('Unlocked sample content'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(service.dispose);
    }
  });
}

class _WorkflowStore implements StoreDataSource {
  final _updates = StreamController<StorePurchase>.broadcast();
  List<StoreProduct> _products = const [];
  int purchaseCount = 0;

  @override
  bool get isAvailable => true;

  @override
  List<StoreProduct> get products => _products;

  @override
  Stream<StorePurchase> get purchaseStream => _updates.stream;

  @override
  Future<void> initialize(List<ProductDefinition> products) async {
    _products = [
      for (final product in products)
        StoreProduct(
          id: product.id,
          title: product.displayName ?? product.id,
          description: 'Demo plan',
          price: r'$39.99',
          rawPrice: 39.99,
          currencyCode: 'USD',
        ),
    ];
  }

  @override
  Future<void> purchase(String productId) async => purchaseCount++;

  void emitPurchased(String productId) => _updates.add(
    StorePurchase(
      productId: productId,
      purchaseId: 'workflow-$productId',
      status: StorePurchaseStatus.purchased,
    ),
  );

  @override
  Future<void> restore() async {}

  @override
  Future<List<StorePurchase>> queryExistingPurchases() async => const [];

  @override
  Future<void> complete(StorePurchase purchase) async {}

  @override
  Future<void> dispose() => _updates.close();
}

class _MemoryStorage implements SubscriptionStorageDataSource {
  final _entitlements = <String, Entitlement>{};
  final _processed = <String>{};
  final _pending = <String, ConsumableDelivery>{};

  @override
  Future<void> initialize(String keyPrefix) async {}

  @override
  Future<Map<String, Entitlement>> loadEntitlements() async =>
      Map.of(_entitlements);

  @override
  Future<void> saveEntitlement(Entitlement entitlement) async {
    _entitlements[entitlement.id] = entitlement;
  }

  @override
  Future<void> removeEntitlement(String entitlementId) async {
    _entitlements.remove(entitlementId);
  }

  @override
  Future<List<ConsumableDelivery>> loadPendingConsumables() async =>
      _pending.values.toList();

  @override
  Future<void> savePendingConsumable(ConsumableDelivery delivery) async {
    _pending.putIfAbsent(delivery.purchaseId, () => delivery);
  }

  @override
  Future<void> acknowledgeConsumable(String purchaseId) async {
    _pending.remove(purchaseId);
  }

  @override
  Future<bool> isPurchaseProcessed(String purchaseId) async =>
      _processed.contains(purchaseId);

  @override
  Future<void> markPurchaseProcessed(String purchaseId) async {
    _processed.add(purchaseId);
  }

  @override
  Future<void> dispose() async {}
}
