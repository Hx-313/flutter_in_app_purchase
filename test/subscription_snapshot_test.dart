import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import 'support/subscription_test_fakes.dart';

void main() {
  test('snapshot copies collections and compares values', () {
    final sourceProducts = <StoreProduct>[
      const StoreProduct(
        id: 'pro_lifetime',
        title: 'Lifetime',
        description: 'Lifetime access',
        price: r'$29.99',
        rawPrice: 29.99,
        currencyCode: 'USD',
      ),
    ];
    final entitlement = Entitlement.active(
      id: 'premium',
      productId: 'pro_lifetime',
      productType: ProductType.lifetime,
    );
    final sourceEntitlements = <String, Entitlement>{'premium': entitlement};
    final snapshot = SubscriptionSnapshot(
      phase: SubscriptionPhase.ready,
      products: sourceProducts,
      entitlements: sourceEntitlements,
      defaultEntitlementId: 'premium',
      isStoreAvailable: true,
    );

    sourceProducts.clear();
    sourceEntitlements.clear();

    expect(snapshot.products, hasLength(1));
    expect(snapshot.entitlements.keys, ['premium']);
    expect(
      snapshot,
      SubscriptionSnapshot(
        phase: SubscriptionPhase.ready,
        products: const [
          StoreProduct(
            id: 'pro_lifetime',
            title: 'Lifetime',
            description: 'Lifetime access',
            price: r'$29.99',
            rawPrice: 29.99,
            currencyCode: 'USD',
          ),
        ],
        entitlements: {'premium': entitlement},
        defaultEntitlementId: 'premium',
        isStoreAvailable: true,
      ),
    );
    expect(() => snapshot.products.clear(), throwsUnsupportedError);
    expect(() => snapshot.entitlements.clear(), throwsUnsupportedError);
  });

  test('copyWith can clear a result, restore status, and error', () {
    final snapshot = SubscriptionSnapshot(
      lastResult: PurchaseResult(status: PurchaseStatus.success),
      lastRestoreStatus: RestoreStatus.failure,
      errorMessage: 'Restore failed',
    );

    final cleared = snapshot.copyWith(
      lastResult: null,
      lastRestoreStatus: null,
      errorMessage: null,
    );

    expect(cleared.lastResult, isNull);
    expect(cleared.lastRestoreStatus, isNull);
    expect(cleared.errorMessage, isNull);
  });

  test('service factory exposes initial store availability', () async {
    final store = TestSubscriptionStore();
    final service = SubscriptionModule.createService(
      config: SubscriptionConfig(products: const [testLifetimeDefinition]),
      store: store,
      storage: TestSubscriptionStorage(),
    );

    expect(service.snapshot.isStoreAvailable, isTrue);
    await service.dispose();
  });
}
