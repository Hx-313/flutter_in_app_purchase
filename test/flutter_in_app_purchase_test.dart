import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

void main() {
  test('ConsumableDelivery compares by value', () {
    final purchasedAt = DateTime.utc(2026, 10, 14);
    final first = ConsumableDelivery(
      purchaseId: 'purchase-1',
      productId: 'coins_100',
      purchasedAt: purchasedAt,
    );
    final second = ConsumableDelivery(
      purchaseId: 'purchase-1',
      productId: 'coins_100',
      purchasedAt: purchasedAt,
    );

    expect(first, equals(second));
    expect(first.props, ['purchase-1', 'coins_100', purchasedAt]);
  });

  test('publicApi_exportsConfigurationAndDeliveryTypes', () {
    final delivery = ConsumableDelivery(
      purchaseId: 'purchase-1',
      productId: 'coins_100',
      purchasedAt: DateTime.utc(2026, 10, 14),
    );
    final config = SubscriptionConfig(
      products: const [
        ProductDefinition(
          id: 'pro_monthly',
          type: ProductType.autoRenewing,
          entitlementId: 'premium',
        ),
        ProductDefinition(id: 'coins_100', type: ProductType.consumable),
      ],
    );

    expect(delivery.purchaseId, 'purchase-1');
    expect(config.productIds, {'pro_monthly', 'coins_100'});
  });

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
