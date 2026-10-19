# State-neutral in-app purchases for Flutter

Manage Apple App Store and Google Play purchases and entitlement access from
Flutter. **Your app owns the paywall design, navigation, and backend.**

> **Security:** local verification is the default for development and
> device-local access. Do not use it to protect server resources. For protected
> content, inject a `PurchaseVerifier` that validates transactions through
> your backend.

## Contents

- [What this package does](#what-this-package-does)
- [Supported features](#supported-features)
- [Developer and support](#developer-and-support)
- [Requirements](#requirements)
- [Install](#install)
- [Quick start](#quick-start)
- [Build your own paywall](#build-your-own-paywall)
- [Handle purchases and consumables](#handle-purchases-and-consumables)
- [Add backend verification](#add-backend-verification)
- [Platform setup guides](#platform-setup-guides)
- [Optional BLoC adapter](#optional-bloc-adapter)
- [Example app](#example-app)
- [License](#license)

## What this package does

`smart_inapp_purchase` gives a Flutter app a store-neutral API for loading
products, starting purchases, restoring purchases, tracking durable access,
and handing off consumable purchases for fulfillment. It is built on Flutter's
[`in_app_purchase`](https://pub.dev/packages/in_app_purchase) plugin.

The core package has no dependency on BLoC or another state-management library.
It does not impose a paywall screen, dialog, bottom sheet, route system, or
visual style. Use the provided service and snapshot builder with `setState`,
`StreamBuilder`, Provider, Riverpod, Redux, BLoC, or your own architecture.

## Supported features

| Feature | Details |
| --- | --- |
| Store platforms | Android, iOS, and macOS through the platform store plugin. |
| Product types | Consumable, non-consumable, lifetime, and subscriptions. |
| Purchase state | Loading, results, pending transactions, store availability. |
| Entitlements | Durable access snapshots, expiry checks, and restore flow. |
| Consumables | Pending delivery, fulfillment handoff, and acknowledgement. |
| Verification | Device-local default or an app-injected server verifier. |
| UI and navigation | Host-owned; no bundled paywall or routes. |
| State management | Core has no state-manager dependency. |

An optional BLoC adapter is maintained separately in this repository.

The subscription product types are `nonRenewing` and `autoRenewing`.

This package does not provide a backend, receipt-validation endpoint, account
system, subscription-management page, or payment UI. Store products and
backend verification must be configured by the host application.

## Developer and support

**Developer and maintainer:** ITHX

For support, use the issue tracker linked from the repository or package page
where you obtained this package. Include the package version, Flutter and Dart
versions, affected platform, a minimal reproduction, and sanitized logs. Never
include store receipts, purchase tokens, credentials, or personal data in a
public report.

## Requirements

| Requirement | Minimum |
| --- | --- |
| Flutter | 3.44.0 |
| Dart | 3.12.2 |
| Android | API 24 (Android 7.0) |
| iOS | 13.0 |
| macOS | 10.15 |

The platform minimums follow the underlying
[`in_app_purchase` platform support][plugin-platforms].
The example project currently uses iOS 15.0 and macOS 12.0 deployment targets.
Building iOS or macOS apps requires macOS and a compatible Xcode installation;
Android builds require the Android SDK and a compatible Flutter toolchain.
Web, Windows, and Linux store purchasing are not supported by this package.

## Install

From your Flutter app directory, run:

```sh
flutter pub add smart_inapp_purchase
```

Or add the dependency manually to `pubspec.yaml` and run `flutter pub get`:

```yaml
dependencies:
  smart_inapp_purchase: ^0.0.1
```

> This package is currently pre-1.0.0. Review release notes before upgrading;
> public APIs may change before the first stable release.

## Quick start

### 1. Define your store products

Use product IDs that exactly match the IDs you create in App Store Connect and
Google Play Console. Entitlement IDs are names chosen by your app; several
products can grant the same entitlement.

```dart
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

final config = SubscriptionConfig(
  products: const [
    ProductDefinition(
      id: 'pro_monthly',
      type: ProductType.autoRenewing,
      entitlementId: 'premium',
      displayName: 'Monthly',
    ),
    ProductDefinition(
      id: 'pro_lifetime',
      type: ProductType.lifetime,
      entitlementId: 'premium',
      displayName: 'Lifetime',
    ),
  ],
  defaultEntitlementId: 'premium',
  // Use a stable, app-specific value. Add an account identifier when each
  // signed-in user should have separate local state.
  storageKeyPrefix: 'com.example.myapp.purchases',
);
```

Product IDs must be unique. Durable products (`nonConsumable`, `lifetime`,
`nonRenewing`, and `autoRenewing`) need an `entitlementId`. Consumables must
not have one. `nonRenewing` products also require a positive `duration`;
`autoRenewing` products must not set a local duration.

### 2. Create and initialize the service

Create one service for the lifetime of the signed-in account or app scope.
Initialize it once and dispose it when that scope ends:

```dart
final service = SubscriptionModule.createService(config: config);
await service.initialize();

// When the owning account/app scope is disposed:
await service.dispose();
```

The default composition uses the platform store adapter and local preferences
storage. You can inject your own store, repository, storage, or verifier when
your application needs different implementations.

### 3. Show products and current access

`SubscriptionBuilder` rebuilds your widget from the latest snapshot. It does
not initialize or dispose the service, and it does not perform navigation.

```dart
SubscriptionBuilder(
  service: service,
  builder: (context, snapshot) {
    if (snapshot.phase == SubscriptionPhase.initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!snapshot.isStoreAvailable) {
      return const Text('The app store is not available.');
    }

    return Column(
      children: [
        Text(snapshot.hasAccess('premium')
            ? 'Premium is active'
            : 'Choose a plan'),
        for (final product in snapshot.products)
          ListTile(
            title: Text(product.definition?.displayName ?? product.title),
            subtitle: Text(product.price),
            onTap: snapshot.isPurchasing
                ? null
                : () => service.purchase(product.id),
          ),
        TextButton(
          onPressed: snapshot.isRestoring ? null : () => service.restore(),
          child: const Text('Restore purchases'),
        ),
      ],
    );
  },
)
```

`purchase(productId)` returns whether the store accepted the purchase request;
it does not mean the purchase completed. Observe `snapshot.lastResult` or
`service.purchaseResultStream` for the eventual success, pending, cancellation,
or error result. `restore()` returns a `RestoreResult` and also updates the
snapshot.

## Build your own paywall

The package exposes purchase state and operations, not a paywall design. Your
app can use any widget and navigation flow:

- a full-screen subscription page;
- a dialog or bottom sheet opened by your app's router;
- a locked-feature screen that opens a paywall and refreshes after purchase;
- a custom design system or remotely configured presentation.

Use `snapshot.hasAccess('premium')` to gate app features. Keep the service in
an app-owned dependency scope and pass it to whichever widgets need it. See the
[example app](example/README.md) for three customizable templates and a
simulated lock → paywall → purchase → unlock flow.

## Handle purchases and consumables

Durable products update the entitlement snapshot after verification. For
consumables, the package creates a pending delivery; fulfill it idempotently
before acknowledging it so the app can safely recover after interruption:

```dart
for (final delivery in service.snapshot.pendingConsumables) {
  await yourApp.fulfillPurchaseOnce(
    idempotencyKey: delivery.purchaseId,
    productId: delivery.productId,
  );
  await service.acknowledgeConsumablePurchase(delivery.purchaseId);
}
```

`fulfillPurchaseOnce` represents your app's own inventory or backend call.
Pending deliveries are at-least-once, so use `purchaseId` as an idempotency
key. Keep a server-side ledger if consumables must follow an account across
devices. The default local preferences storage does not persist receipt data.

## Add backend verification

`VerificationMode.local` is intended for prototypes and device-local access.
Local preferences can be changed by the device owner and do not provide
authoritative renewal or cancellation state for auto-renewing subscriptions.
Do not use local entitlements to authorize protected backend resources.

For protected resources, select `VerificationMode.serverVerified` and provide
an implementation of `PurchaseVerifier` that sends the transaction to your
backend. Your backend should validate it with Apple or Google, bind it to the
authenticated user, and return normalized access state. This package does not
define an endpoint, authentication method, or server implementation.

```dart
final class AppPurchaseVerifier implements PurchaseVerifier {
  const AppPurchaseVerifier(this.verifyWithBackend);

  final Future<VerificationResult> Function(
    PurchaseVerificationRequest request,
  ) verifyWithBackend;

  @override
  Future<VerificationResult> verify(
    PurchaseVerificationRequest request,
  ) =>
      verifyWithBackend(request);
}

final secureConfig = SubscriptionConfig(
  products: config.products,
  defaultEntitlementId: config.defaultEntitlementId,
  verificationMode: VerificationMode.serverVerified,
  storageKeyPrefix: config.storageKeyPrefix,
);

final secureService = SubscriptionModule.createService(
  config: secureConfig,
  verifier: AppPurchaseVerifier(yourBackend.verifyPurchase),
);
await secureService.initialize();
```

`yourBackend.verifyPurchase` is an app-owned method that implements your
backend contract. Map a successful server response to
`VerificationResult.valid(...)`, a rejected transaction to
`VerificationResult.invalid(...)`, and a temporary backend outage to
`VerificationResult.unavailable(...)`. The package fails closed when a
transaction cannot be verified. Treat receipt and transaction data as
sensitive; do not log it.

## Platform setup guides

Before testing real payments, create the application and products in the
relevant store console. Product IDs in `SubscriptionConfig` must match the
store exactly. Configure pricing, availability, agreements, signing, and
testing accounts in the store console. Purchases cannot be tested with live
store products until these steps are complete. The same Dart configuration
and service API is used on every platform; the plugin supplies the native
store bridge, so the host app does not need custom purchase-channel code.

### Android (Google Play)

1. Set the Android `applicationId` in your app to the package name registered
   in Google Play Console. These values must match.
2. Use Android API 24 or newer, then fetch Flutter dependencies:

   ```sh
   flutter pub get
   flutter devices
   ```

3. In Play Console, create and activate the in-app products or subscriptions
   used by your app. For subscriptions, configure an active base plan. Use the
   exact product IDs in `SubscriptionConfig`.
4. Add license testers or internal-test-track testers in Play Console. For
   release-like testing, upload a build to an internal test track and install
   it from the tester's Play Store link.
5. Run the app on a supported Android device:

   ```sh
   flutter run -d <android-device-id>
   ```

6. Test a successful purchase, pending payment, cancellation, already-owned
   product, restore, and store-unavailable behavior. Use a license tester or
   test track account to avoid making real purchases.

The Flutter store plugin supplies the platform billing integration; do not add
a second billing client to the app. See
[Google's billing test guide][android-billing-test] and the
[Play in-app product guide][play-products].

### iOS (App Store)

1. Build from macOS with Xcode. Set the Runner bundle identifier to the app
   identifier registered in Apple Developer and App Store Connect.
2. In Xcode, select the Runner target and enable the **In-App Purchase**
   capability. Confirm the iOS deployment target is 13.0 or newer.
3. In App Store Connect, accept the required agreements and create the
   consumable, non-consumable, or subscription products. Add the same product
   IDs to `SubscriptionConfig` and make the products available for testing.
4. In Xcode, you can attach a StoreKit Configuration file to the Run scheme
   for local StoreKit testing. This does not require App Store Connect products
   to complete a local simulation.
5. For sandbox testing, configure a Sandbox Apple Account, sign the app with
   the matching team, and run on a supported device. Use TestFlight for
   release-like testing.
6. Run the app and test purchase, cancellation, restore, and interrupted
   purchase behavior:

   ```sh
   flutter pub get
   flutter run -d <ios-device-id>
   ```

Apple guides: [configure in-app purchases][app-store-iap-overview],
[create products][app-store-create-iap],
[StoreKit testing in Xcode][storekit-testing], and
[sandbox testing][sandbox-iap].

### macOS (App Store)

1. Build from macOS with Xcode. Register the macOS app and set the Runner
   bundle identifier to the identifier configured for that app.
2. Confirm the macOS deployment target is 10.15 or newer and enable **In-App
   Purchase** for the app's App ID in Apple Developer settings.
3. Configure the products in App Store Connect and use matching IDs in
   `SubscriptionConfig`. Make sure the products are available for the macOS
   app and the account used for testing.
4. Attach a StoreKit Configuration file to the Xcode Run scheme for local
   testing, or use Apple's sandbox/TestFlight flow for store-backed tests.
5. Run on a Mac:

   ```sh
   flutter pub get
   flutter run -d macos
   ```

The package example scaffold currently targets macOS 12.0. A host app can use
the plugin's lower supported minimum when its other dependencies permit it.

## Optional BLoC adapter

The core package has no BLoC dependency. The separate
[BLoC adapter docs][bloc-docs] describe the optional adapter for apps that use
`flutter_bloc`. It is marked `publish_to: none`, so it is available in this
repository but is not separately published on pub.dev.

## Example app

The [example app guide](example/README.md) explains how to run the branded
sample on Android, iOS, or macOS. It uses a simulated store by default, so the
complete purchase and restore flow works without store credentials and does
not make real payments. Replace the simulator with the platform adapter and
complete the platform setup above before shipping a host app.

## License

This package is available under the [MIT License](LICENSE).

[plugin-platforms]: https://pub.dev/packages/in_app_purchase
[android-billing-test]: https://developer.android.com/google/play/billing/test
[play-products]: https://support.google.com/googleplay/android-developer/answer/1153481?hl=en
[app-store-iap-overview]: https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchase-settings/
[app-store-create-iap]: https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/
[storekit-testing]: https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode
[sandbox-iap]: https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox
[bloc-docs]: packages/flutter_in_app_purchase_bloc/README.md
