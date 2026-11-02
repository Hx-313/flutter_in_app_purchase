# ITHX subscription showcase

This example demonstrates the hands-off setup: one `SubscriptionProvider` owns
the subscription service, and the app supplies only UI. The splash screen, home
gallery, three paywall presentations, and locked-feature navigation all live in
the example app. The package handles initialization, purchase and restore state,
consumable fulfillment, and disposal.

## Run

```sh
cd example
flutter pub get
flutter run
```

Run on Android, iOS, or macOS. The app starts with a branded ITHX splash and
continues to a gallery of paywall templates and a sample locked feature.

## Simulated store

The default store is the example-only `SimulatedStoreDataSource`. It provides
monthly, annual, and lifetime demo plans, marks purchases as owned, and stores a
separate demo purchase ledger in `SharedPreferences`. Purchases are simulated;
no real payment is made and no store account is required. Purchase and
entitlement records use the example prefix `ithx.example.demo`.

The simulator persists owned demo plans so the example can restore access
after service or process recreation. It is for development and demonstrations;
do not ship it in a production app.

## Use the templates as a starting point

- `templates/full_screen_paywall.dart` shows a full-screen purchase flow.
- `templates/dialog_paywall.dart` shows a constrained, scrollable dialog.
- `templates/bottom_sheet_paywall.dart` shows a safe-area-aware sheet.
- `templates/paywall_offer_panel.dart` shows the shared plan picker built with
  `SubscriptionView`.
- `screens/locked_feature_screen.dart` shows entitlement gating with
  `PremiumGate`.

`DemoSubscriptionHost` wraps the app in `SubscriptionProvider`, which creates,
initializes, listens to, and disposes the service. The templates never create or
dispose a service: they render `SubscriptionViewState` and call the guarded
`state.purchase` and `state.restore` commands. `SubscriptionBuilder` and
`SubscriptionService` remain available for custom architectures.

Copy the pieces that fit your app and replace their colors, text, product
selection, and interaction behavior. Add `SubscriptionCallbacks` for analytics,
a `messageBuilder` for localized status text, and `PremiumGate` around premium
features. The optional BLoC package is not used here.

## Connect real products

For a host app, configure product IDs that match App Store Connect and Google
Play Console, configure signing and store entitlements, and test with the
platform sandbox accounts. Compose the service with the built-in platform store
adapter instead of the simulator. Use a stable account-specific storage prefix.

If the app backend must validate transactions, set
`VerificationMode.serverVerified` and inject an app-owned `PurchaseVerifier`.
The package does not prescribe a backend URL or request protocol. Verify the
authenticated account and transaction with your backend before granting
protected access.
