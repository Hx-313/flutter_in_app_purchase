# flutter_in_app_purchase

Cross-platform in-app purchases, durable entitlements, verification hooks, and a theme-aware subscription UI for Flutter.

The package uses Flutter's official `in_app_purchase` implementations for Android, iOS, and macOS. It does not add custom BillingClient or StoreKit channels.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

void main() {
  runApp(
    SubscriptionScope(
      config: SubscriptionConfig(
        products: const [
          ProductDefinition(
            id: 'pro_lifetime',
            type: ProductType.lifetime,
            entitlementId: 'pro',
            priority: 10,
          ),
          ProductDefinition(
            id: 'pro_monthly',
            type: ProductType.autoRenewing,
            entitlementId: 'pro',
            priority: 8,
          ),
        ],
        defaultEntitlementId: 'pro',
      ),
      child: const MaterialApp(home: SubscriptionPage()),
    ),
  );
}
```

`SubscriptionScope` creates, initializes, and disposes the package BLoC. Use `SubscriptionScope.of(context)` when a custom canvas is preferred, or use the bundled `SubscriptionPage` for the complete lifecycle UI.

## Architecture

The implementation lives under `lib/features/subscriptions/`:

- `domain/` contains immutable entities, repository contracts, and purchase use-case orchestration.
- `data/` contains the official store adapter, preferences data source, and repository composition.
- `presentation/` contains the BLoC events/state, scope, page, body, and feature widgets.

The default `SubscriptionScope` is the composition root for consumers; custom canvases only depend on `SubscriptionBloc` state and events.

## Product types

| Type | Behavior |
| --- | --- |
| `consumable` | Emits a one-shot successful purchase result. It is never persisted as access. |
| `nonConsumable` | Grants permanent access. |
| `lifetime` | Grants permanent lifetime access. |
| `nonRenewing` | Grants access until the configured positive `duration`. |
| `autoRenewing` | Grants renewable access. Local mode keeps access active with unknown expiry; verified mode uses verifier data. |

Consumables must not define `entitlementId`. Every durable product must define one. Product IDs must be unique.

## Verification

Local mode is the default and is useful for prototypes or apps that accept store-driven client state:

```dart
SubscriptionConfig(
  products: products,
  verificationMode: VerificationMode.local,
)
```

For production access control, inject a verifier and use server-verified mode:

```dart
class AppPurchaseVerifier implements PurchaseVerifier {
  @override
  Future<VerificationResult> verify(
    PurchaseVerificationRequest request,
  ) async {
    // Send request.purchase.verificationData to your backend.
    return const VerificationResult.valid(
      expiresAt: null,
      isExpiryKnown: false,
      willRenew: true,
    );
  }
}
```

In local mode, auto-renewing products expose only active/inactive access. The package does not guess `expired`, `paused`, `gracePeriod`, `canceled`, or `refunded` without verified lifecycle data.

## Custom presentation

The BLoC exposes an immutable snapshot for a custom canvas:

```dart
return SubscriptionBuilder(
  builder: (context, state) => Text(
    state.hasAccess('pro') ? 'Pro enabled' : 'Upgrade',
  ),
);
```

For advanced rebuild control, the exported `SubscriptionBloc` can also be used with `BlocSelector` or `BlocBuilder` from `flutter_bloc`:

```dart
BlocSelector<SubscriptionBloc, SubscriptionSnapshot, bool>(
  selector: (state) => state.hasAccess('pro'),
  builder: (context, hasAccess) => Text(
    hasAccess ? 'Pro enabled' : 'Upgrade',
  ),
);
```

The bundled UI reads the host app's `ThemeData` and accepts `SubscriptionTheme` and `SubscriptionStrings` overrides. Navigation and store-management URLs remain app-owned through `onManageSubscription`.

## Store setup

Before running a real purchase:

1. Create matching product IDs in Google Play Console for Android.
2. Create matching products in App Store Connect for iOS and macOS.
3. Configure signing, store entitlements, tester accounts, and sandbox/test tracks in each platform project.
4. Use the exact same IDs in `ProductDefinition`.
5. Test pending, canceled, restored, duplicate, and interrupted purchases on real store environments.

The package targets Android SDK 24+, iOS 13+, and macOS 10.15+, matching the current official plugin support matrix.

## Testing

The package includes domain, use-case, BLoC, and widget tests. Inject store and storage fakes into `SubscriptionRepositoryImpl` to test without a real store. The `example/` app demonstrates the minimal consumer setup.
