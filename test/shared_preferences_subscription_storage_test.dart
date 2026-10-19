import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'loadPendingConsumables_returnsStagedRecordsAfterReinitialization',
    () async {
      final firstStorage = SharedPreferencesSubscriptionStorageDataSource();
      await firstStorage.initialize('account-a');
      final delivery = ConsumableDelivery(
        purchaseId: 'purchase-1',
        productId: 'coins_100',
        purchasedAt: DateTime.utc(2026, 10, 14),
      );
      await firstStorage.savePendingConsumable(delivery);

      final restartedStorage = SharedPreferencesSubscriptionStorageDataSource();
      await restartedStorage.initialize('account-a');

      expect(await restartedStorage.loadPendingConsumables(), [delivery]);
    },
  );

  test('savePendingConsumable_isIdempotentByPurchaseId', () async {
    final storage = SharedPreferencesSubscriptionStorageDataSource();
    await storage.initialize('account-a');
    final first = ConsumableDelivery(
      purchaseId: 'purchase-1',
      productId: 'coins_100',
      purchasedAt: DateTime.utc(2026, 10, 14),
    );
    final conflictingDuplicate = ConsumableDelivery(
      purchaseId: 'purchase-1',
      productId: 'coins_500',
      purchasedAt: DateTime.utc(2026, 10, 15),
    );

    await storage.savePendingConsumable(first);
    await storage.savePendingConsumable(conflictingDuplicate);

    expect(await storage.loadPendingConsumables(), [first]);
  });

  test('acknowledgeConsumable_removesOnlyMatchingId', () async {
    final storage = SharedPreferencesSubscriptionStorageDataSource();
    await storage.initialize('account-a');
    final first = ConsumableDelivery(
      purchaseId: 'purchase-1',
      productId: 'coins_100',
      purchasedAt: DateTime.utc(2026, 10, 14),
    );
    final second = ConsumableDelivery(
      purchaseId: 'purchase-2',
      productId: 'coins_500',
      purchasedAt: DateTime.utc(2026, 10, 15),
    );
    await storage.savePendingConsumable(first);
    await storage.savePendingConsumable(second);

    await storage.acknowledgeConsumable(first.purchaseId);

    expect(await storage.loadPendingConsumables(), [second]);
    await storage.acknowledgeConsumable(first.purchaseId);
    expect(await storage.loadPendingConsumables(), [second]);
  });

  test(
    'loadPendingConsumables_discardsMalformedRecordsAndKeepsValidOnes',
    () async {
      final purchasedAt = DateTime.utc(2026, 10, 14);
      SharedPreferences.setMockInitialValues({
        'account-a.pendingConsumables':
            '[{"purchaseId":"valid","productId":"coins_100","purchasedAt":"${purchasedAt.toIso8601String()}"},'
            '{"purchaseId":"","productId":"coins_bad","purchasedAt":"not-a-date"},'
            '"not-a-record"]',
      });
      final storage = SharedPreferencesSubscriptionStorageDataSource();
      await storage.initialize('account-a');

      expect(await storage.loadPendingConsumables(), [
        ConsumableDelivery(
          purchaseId: 'valid',
          productId: 'coins_100',
          purchasedAt: purchasedAt,
        ),
      ]);
    },
  );
}
