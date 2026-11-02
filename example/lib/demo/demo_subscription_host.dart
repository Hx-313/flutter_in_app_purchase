import 'package:flutter/widgets.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import 'simulated_store_data_source.dart';

/// Builds an example app with one provider-owned subscription service.
///
/// This is the hands-off setup: `SubscriptionProvider` creates, initializes,
/// listens to, and disposes the service while the app runs.
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
  late final StoreDataSource _store =
      widget.store ?? SimulatedStoreDataSource();

  @override
  Widget build(BuildContext context) => SubscriptionProvider(
    config: demoSubscriptionConfig,
    store: _store,
    storage: widget.storage,
    child: Builder(
      builder: (context) =>
          widget.builder(context, SubscriptionProvider.of(context).service),
    ),
  );
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
