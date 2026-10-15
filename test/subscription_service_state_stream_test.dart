import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

import 'support/subscription_test_fakes.dart';

void main() {
  test(
    'unavailable initialization emits and can retry without extra listeners',
    () async {
      final store = TestSubscriptionStore(available: false);
      final service = createTestSubscriptionService(store: store);
      final snapshots = <SubscriptionSnapshot>[];
      final subscription = service.snapshotStream.listen(snapshots.add);

      await service.initialize();
      await flushSubscriptionEvents();
      expect(service.snapshot.phase, SubscriptionPhase.unavailable);
      expect(snapshots.last.phase, SubscriptionPhase.unavailable);

      store.available = true;
      await service.initialize();
      await flushSubscriptionEvents();
      store.emit(
        const StorePurchase(
          productId: 'pro_lifetime',
          purchaseId: 'purchase-on-retry',
          status: StorePurchaseStatus.purchased,
          pendingCompletePurchase: true,
        ),
      );
      await flushSubscriptionEvents();

      expect(service.snapshot.phase, SubscriptionPhase.ready);
      expect(snapshots.last.phase, SubscriptionPhase.ready);
      expect(store.completionCount, 1);
      await subscription.cancel();
      await service.dispose();
    },
  );

  test(
    'purchase and consumable delivery changes appear in snapshots',
    () async {
      final store = TestSubscriptionStore();
      final service = createTestSubscriptionService(
        store: store,
        products: const [testLifetimeDefinition, testConsumableDefinition],
      );
      final snapshots = <SubscriptionSnapshot>[];
      final subscription = service.snapshotStream.listen(snapshots.add);
      await service.initialize();

      await service.purchase('pro_lifetime');
      expect(service.snapshot.isPurchasing, isTrue);
      store.emit(
        const StorePurchase(
          productId: 'pro_lifetime',
          purchaseId: 'purchase-lifetime',
          status: StorePurchaseStatus.purchased,
        ),
      );
      await flushSubscriptionEvents();
      expect(service.snapshot.isPurchasing, isFalse);
      expect(service.snapshot.hasAccess('premium'), isTrue);
      expect(service.snapshot.lastResult?.status, PurchaseStatus.success);

      store.emit(
        StorePurchase(
          productId: 'coins_100',
          purchaseId: 'purchase-coins',
          transactionDate: DateTime.utc(2026, 10, 14),
          status: StorePurchaseStatus.purchased,
        ),
      );
      await flushSubscriptionEvents();
      expect(
        service.snapshot.pendingConsumables.single.purchaseId,
        'purchase-coins',
      );
      expect(
        snapshots.any((snapshot) => snapshot.pendingConsumables.isNotEmpty),
        isTrue,
      );

      await service.acknowledgeConsumablePurchase('purchase-coins');
      expect(service.snapshot.pendingConsumables, isEmpty);
      await subscription.cancel();
      await service.dispose();
    },
  );

  test('restore reports progress and the final restore result', () async {
    final store = TestSubscriptionStore()..restoreGate = Completer<void>();
    store.restorePurchases = const [
      StorePurchase(
        productId: 'pro_lifetime',
        purchaseId: 'purchase-restored',
        status: StorePurchaseStatus.restored,
      ),
    ];
    final service = createTestSubscriptionService(store: store);
    final snapshots = <SubscriptionSnapshot>[];
    final subscription = service.snapshotStream.listen(snapshots.add);
    await service.initialize();

    final restore = service.restore();
    expect(service.snapshot.isRestoring, isTrue);
    store.restoreGate!.complete();
    final result = await restore;

    expect(result.status, RestoreStatus.restored);
    expect(service.snapshot.isRestoring, isFalse);
    expect(service.snapshot.lastRestoreStatus, RestoreStatus.restored);
    expect(service.snapshot.lastResult?.status, PurchaseStatus.restored);
    expect(snapshots.any((snapshot) => snapshot.isRestoring), isTrue);
    await subscription.cancel();
    await service.dispose();
  });
}
