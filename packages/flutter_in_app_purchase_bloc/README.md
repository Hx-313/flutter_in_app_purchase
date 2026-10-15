# flutter_in_app_purchase_bloc

Optional BLoC integration for the state-neutral
[`flutter_in_app_purchase`](../../README.md) core package. This adapter contains
the BLoC, its event types, `SubscriptionScope`, and BLoC composition helpers.
The core package has no `flutter_bloc` dependency.

## Use from this checkout

Add both packages to the consuming app:

```yaml
dependencies:
  flutter_in_app_purchase:
    path: ../flutter_in_app_purchase
  flutter_in_app_purchase_bloc:
    path: ../flutter_in_app_purchase/packages/flutter_in_app_purchase_bloc
```

For published apps, use the package versions selected by your release setup.
The adapter currently has `publish_to: none` in this repository.

## Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';
import 'package:flutter_in_app_purchase_bloc/flutter_in_app_purchase_bloc.dart';

SubscriptionScope(
  config: SubscriptionConfig(
    products: const [
      ProductDefinition(
        id: 'pro_monthly',
        type: ProductType.autoRenewing,
        entitlementId: 'premium',
      ),
    ],
    defaultEntitlementId: 'premium',
    storageKeyPrefix: 'com.example.app.iap.$stableAccountId',
  ),
  child: const MaterialApp(home: MyPaywallScreen()),
)
```

The scope creates, initializes, exposes, and disposes its BLoC and service.
Read `SubscriptionSnapshot` from `SubscriptionBloc` and dispatch purchase,
restore, refresh, and consumable acknowledgement events or use its convenience
methods. Your widgets still own their complete layout and navigation.

If your app does not use BLoC, install only the core package and use
`SubscriptionService` or the generic `SubscriptionBuilder`.
