import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import 'support/subscription_test_fakes.dart';

SubscriptionConfig _config() => SubscriptionConfig(
  products: const [testLifetimeDefinition, testConsumableDefinition],
  defaultEntitlementId: 'premium',
);

StorePurchase _lifetimePurchase({String purchaseId = 'purchase-1'}) =>
    StorePurchase(
      productId: testLifetimeDefinition.id,
      purchaseId: purchaseId,
      status: StorePurchaseStatus.purchased,
      pendingCompletePurchase: true,
    );

StorePurchase _consumablePurchase({String purchaseId = 'coins-1'}) =>
    StorePurchase(
      productId: testConsumableDefinition.id,
      purchaseId: purchaseId,
      transactionDate: DateTime.utc(2026, 10, 14),
      status: StorePurchaseStatus.purchased,
      pendingCompletePurchase: true,
    );

Future<void> _settle() async {
  for (var index = 0; index < 4; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<SubscriptionController> _startController({
  SubscriptionCallbacks callbacks = const SubscriptionCallbacks(),
  SubscriptionConfig? config,
  SubscriptionMessageBuilder? messageBuilder,
  TestSubscriptionStore? store,
  TestSubscriptionStorage? storage,
}) async {
  final controller = SubscriptionController(
    service: SubscriptionModule.createService(
      config: config ?? _config(),
      store: store ?? TestSubscriptionStore(),
      storage: storage ?? TestSubscriptionStorage(),
    ),
    callbacks: callbacks,
    messageBuilder: messageBuilder,
  );
  await controller.initialize();
  return controller;
}

bool _decline(ConsumableDelivery delivery) => false;

FutureOr<bool> _throwOnFulfill(ConsumableDelivery delivery) =>
    throw StateError('inventory offline');

void main() {
  group('SubscriptionConfig', () {
    test('equal values compare equal so inline configs stay stable', () {
      final first = _config();
      final second = _config();

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different values do not compare equal', () {
      final first = _config();
      final second = SubscriptionConfig(
        products: const [testConsumableDefinition],
      );

      expect(first, isNot(second));
    });
  });

  group('SubscriptionController', () {
    test('beforePurchase returning false cancels without contacting the store',
        () async {
      final store = TestSubscriptionStore();
      final controller = await _startController(
        store: store,
        callbacks: const SubscriptionCallbacks(beforePurchase: _declinePurchase),
      );

      final result = await controller.purchase(testLifetimeDefinition.id);

      expect(result.status, PurchaseStatus.canceled);
      expect(store.purchaseCount, 0);
      await controller.dispose();
    });

    test('beforePurchase returning true lets the store purchase continue',
        () async {
      final store = TestSubscriptionStore();
      final controller = await _startController(
        store: store,
        callbacks: const SubscriptionCallbacks(
          beforePurchase: _allowPurchase,
        ),
      );

      final purchase = controller.purchase(testLifetimeDefinition.id);
      await _settle();
      store.emit(_lifetimePurchase());
      await _settle();

      expect((await purchase).status, PurchaseStatus.success);
      expect(store.purchaseCount, 1);
      await controller.dispose();
    });

    test('returning false from onConsumablePurchased keeps it pending',
        () async {
      final store = TestSubscriptionStore();
      final storage = TestSubscriptionStorage();
      final controller = await _startController(
        store: store,
        storage: storage,
        callbacks: const SubscriptionCallbacks(
          onConsumablePurchased: _decline,
        ),
      );

      store.emit(_consumablePurchase());
      await _settle();

      expect(controller.currentState.pendingConsumables, hasLength(1));
      expect(storage.pending, contains('coins-1'));
      expect(store.completionCount, 0);
      await controller.dispose();
    });

    test('throwing from onConsumablePurchased keeps it pending', () async {
      final store = TestSubscriptionStore();
      final storage = TestSubscriptionStorage();
      final controller = await _startController(
        store: store,
        storage: storage,
        callbacks: const SubscriptionCallbacks(
          onConsumablePurchased: _throwOnFulfill,
        ),
      );

      store.emit(_consumablePurchase());
      await _settle();

      expect(controller.currentState.pendingConsumables, hasLength(1));
      expect(storage.pending, contains('coins-1'));
      expect(store.completionCount, 0);
      await controller.dispose();
    });

    test('returning true acknowledges and completes the consumable', () async {
      final store = TestSubscriptionStore();
      final storage = TestSubscriptionStorage();
      final fulfilled = <ConsumableDelivery>[];
      final controller = await _startController(
        store: store,
        storage: storage,
        callbacks: SubscriptionCallbacks(
          onConsumablePurchased: (delivery) async {
            fulfilled.add(delivery);
            return true;
          },
        ),
      );

      store.emit(_consumablePurchase());
      await _settle();

      expect(fulfilled.single.purchaseId, 'coins-1');
      expect(controller.currentState.pendingConsumables, isEmpty);
      expect(storage.pending, isEmpty);
      expect(store.completionCount, 1);
      await controller.dispose();
    });

    test('retryPendingConsumables reattempts a declined delivery', () async {
      final store = TestSubscriptionStore();
      var allow = false;
      final controller = await _startController(
        store: store,
        callbacks: SubscriptionCallbacks(
          onConsumablePurchased: (delivery) => allow,
        ),
      );

      store.emit(_consumablePurchase());
      await _settle();
      expect(controller.currentState.pendingConsumables, hasLength(1));

      allow = true;
      await controller.retryPendingConsumables();
      await _settle();

      expect(controller.currentState.pendingConsumables, isEmpty);
      expect(store.completionCount, 1);
      await controller.dispose();
    });

    test('messageBuilder rewrites the host-facing status text', () async {
      final controller = await _startController(
        messageBuilder: (result) => 'localized:${result.status.name}',
      );

      final result = await controller.purchase('missing-product');
      await _settle();

      expect(result.status, PurchaseStatus.notAvailable);
      expect(controller.currentState.statusMessage, 'localized:notAvailable');
      await controller.dispose();
    });

    test('actions stay graceful before initialization', () async {
      final controller = SubscriptionController(
        service: SubscriptionModule.createService(
          config: _config(),
          store: TestSubscriptionStore(),
          storage: TestSubscriptionStorage(),
        ),
      );

      expect((await controller.restore()).status, RestoreStatus.failure);
      expect(
        (await controller.purchase(testLifetimeDefinition.id)).status,
        PurchaseStatus.notAvailable,
      );
      await controller.acknowledgeConsumable('missing');

      await controller.dispose();
    });
  });

  group('SubscriptionProvider', () {
    testWidgets('a purchase finishes with no SubscriptionView mounted', (
      tester,
    ) async {
      final store = TestSubscriptionStore();
      final storage = TestSubscriptionStorage();
      final results = <PurchaseResult>[];
      late SubscriptionController controller;

      await tester.pumpWidget(
        SubscriptionProvider(
          config: _config(),
          store: store,
          storage: storage,
          callbacks: SubscriptionCallbacks(
            onPurchaseSuccess: results.add,
          ),
          child: Builder(
            builder: (context) {
              controller = SubscriptionProvider.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(controller.currentState.phase, SubscriptionPhase.ready);

      store.emit(_lifetimePurchase());
      await tester.pump();
      await tester.pump();

      expect(results.single.status, PurchaseStatus.success);
      expect(controller.currentState.hasAccess, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('equal config values do not recreate the service', (
      tester,
    ) async {
      final store = TestSubscriptionStore();
      final storage = TestSubscriptionStorage();
      const probeKey = ValueKey<String>('probe');

      Widget app(SubscriptionConfig config) => SubscriptionProvider(
        config: config,
        store: store,
        storage: storage,
        child: const Builder(
          key: probeKey,
          builder: _emptyBuilder,
        ),
      );

      await tester.pumpWidget(app(_config()));
      await tester.pump();
      await tester.pump();
      final first = SubscriptionProvider.of(
        tester.element(find.byKey(probeKey)),
      );
      expect(store.initializeCount, 1);

      await tester.pumpWidget(app(_config()));
      await tester.pump();
      final second = SubscriptionProvider.of(
        tester.element(find.byKey(probeKey)),
      );

      expect(identical(first, second), isTrue);
      expect(store.initializeCount, 1);

      await tester.pumpWidget(
        app(SubscriptionConfig(products: const [testConsumableDefinition])),
      );
      await tester.pump();
      final third = SubscriptionProvider.of(
        tester.element(find.byKey(probeKey)),
      );

      expect(identical(first, third), isFalse);
      expect(store.initializeCount, 2);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('PremiumGate swaps locked content for granted access', (
      tester,
    ) async {
      final store = TestSubscriptionStore();

      await tester.pumpWidget(
        SubscriptionProvider(
          config: _config(),
          store: store,
          storage: TestSubscriptionStorage(),
          child: const MaterialApp(
            home: PremiumGate(locked: _lockedBuilder, child: Text('PRO')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);

      store.emit(_lifetimePurchase());
      await tester.pump();
      await tester.pump();

      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('LOCKED'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}

bool _declinePurchase(String productId) => false;

bool _allowPurchase(String productId) => true;

Widget _emptyBuilder(BuildContext context) => const SizedBox.shrink();

Widget _lockedBuilder(BuildContext context) => const Text('LOCKED');
