import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import 'simulated_store_data_source.dart';

/// Builds an example app with one initialized, app-owned subscription service.
class DemoSubscriptionHost extends StatefulWidget {
  const DemoSubscriptionHost({
    super.key,
    required this.builder,
    this.store,
    this.storage,
  });

  final Widget Function(BuildContext context, SubscriptionService service)
  builder;
  final StoreDataSource? store;
  final SubscriptionStorageDataSource? storage;

  @override
  State<DemoSubscriptionHost> createState() => _DemoSubscriptionHostState();
}

class _DemoSubscriptionHostState extends State<DemoSubscriptionHost> {
  late final SubscriptionService _service = SubscriptionModule.createService(
    config: demoSubscriptionConfig,
    store: widget.store ?? SimulatedStoreDataSource(),
    storage: widget.storage,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _service.initialize();
    } catch (_) {
      // The service exposes initialization failures through its snapshot.
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _service);

  @override
  void dispose() {
    unawaited(_service.dispose());
    super.dispose();
  }
}

final demoSubscriptionConfig = SubscriptionConfig(
  products: const [
    ProductDefinition(
      id: 'pro_monthly',
      type: ProductType.autoRenewing,
      entitlementId: 'premium',
      displayName: 'Monthly',
      priority: 1,
    ),
    ProductDefinition(
      id: 'pro_annual',
      type: ProductType.autoRenewing,
      entitlementId: 'premium',
      displayName: 'Annual',
      priority: 2,
    ),
    ProductDefinition(
      id: 'pro_lifetime',
      type: ProductType.lifetime,
      entitlementId: 'premium',
      displayName: 'Lifetime',
      priority: 3,
    ),
  ],
  defaultEntitlementId: 'premium',
  verificationMode: VerificationMode.local,
  storageKeyPrefix: 'ithx.example.demo',
);
