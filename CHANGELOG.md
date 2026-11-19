## 0.1.0

* **Hands-off Subscription Integration**:
  * Added `SubscriptionProvider`, `SubscriptionView`, and `PremiumGate` so host applications supply only UI while the package manages service creation, initialization, stream listening, callbacks, and disposal.
  * Added `SubscriptionCallbacks`, `SubscriptionViewState` with guarded commands, and optional `SubscriptionMessageBuilder` for localized notifications.
* **Consumable & Lifecycle Hardening**:
  * Consumable purchases are acknowledged only after `onConsumablePurchased` returns `true`, persisting unfulfilled records until successfully delivered.
  * `SubscriptionService.purchase` returns a strongly-typed `PurchaseResult` that resolves when the store reports an outcome.
  * Restore and acknowledge operations report structured failures instead of throwing before initialization.
  * Persist verified purchases before native store completion and report rejected restores as failures.
  * Anchor local non-renewing subscription expiry to store transaction dates and expose store retry state.
* **Architectural Decoupling**:
  * Moved BLoC state management adapter into companion package `smart_inapp_purchase_bloc`.
  * Moved demonstration UI templates, showcase screens, and design assets into the `example` app.
* **Dependency Updates**:
  * Upgraded dependencies to latest releases (`equatable: ^3.0.0`, `in_app_purchase_android: ^0.5.5`, `in_app_purchase_storekit: ^0.4.17`, `shared_preferences: ^2.5.6`).

## 0.0.1

* Initial release with cross-platform store abstraction for Android, iOS, and macOS.
* Added consumable delivery results, durable entitlements, restore handling, and verification hooks.
* Added `ChangeNotifier` scope/controller integration and theme-aware subscription page.
* Added example app and platform setup documentation.
