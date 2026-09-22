import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

void main() {
  group('ProductDefinition', () {
    test('allows consumables without an entitlement', () {
      const product = ProductDefinition(
        id: 'coins_100',
        type: ProductType.consumable,
      );

      expect(product.entitlementId, isNull);
      expect(product.grantsEntitlement, isFalse);
    });

    test('requires an entitlement for durable products', () {
      expect(
        () => SubscriptionConfig(
          products: const [
            ProductDefinition(
              id: 'pro_monthly',
              type: ProductType.autoRenewing,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate product IDs', () {
      expect(
        () => SubscriptionConfig(
          products: const [
            ProductDefinition(
              id: 'pro',
              type: ProductType.lifetime,
              entitlementId: 'premium',
            ),
            ProductDefinition(
              id: 'pro',
              type: ProductType.nonConsumable,
              entitlementId: 'premium',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  test('local auto-renewing entitlement keeps unknown expiry explicit', () {
    final entitlement = Entitlement.active(
      id: 'premium',
      productId: 'pro_monthly',
      productType: ProductType.autoRenewing,
      isExpiryKnown: false,
    );

    expect(entitlement.isActive, isTrue);
    expect(entitlement.state, SubscriptionState.active);
    expect(entitlement.expiresAt, isNull);
    expect(entitlement.isExpiryKnown, isFalse);
    expect(entitlement.hasDetailedLifecycle, isFalse);
  });
}
