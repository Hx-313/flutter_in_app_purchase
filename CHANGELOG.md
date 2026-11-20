## 0.2.0

* **Flutter Framework Modularization Compatibility**:
  * Decoupled core library and test suites from deprecated monolithic `package:flutter/material.dart` and `package:flutter/cupertino.dart`.
  * Core library relies exclusively on `package:flutter/widgets.dart` with `Directionality` in tests, ensuring forward compatibility with `material_ui` and `cupertino_ui` modular packages in Flutter 3.50+.
* **BLoC 9.x Ecosystem Modernization**:
  * Companion adapter `smart_inapp_purchase_bloc` updated to support `flutter_bloc: ">=8.1.6 <10.0.0"`.
  * Verified full compatibility with `bloc: ^9.2.1` and `flutter_bloc: ^9.1.1`.
* **Android Modern Build Toolchain**:
  * Upgraded Gradle wrapper to `9.5.0` (from `9.3.1`).
  * Upgraded Android Gradle Plugin (AGP) to `9.3.1` (from `9.1.0`).
  * Upgraded Kotlin Android Plugin to `2.4.20` (from `2.4.0`).
* **iOS Human Interface Guidelines (HIG) Paywall Template**:
  * Added native iOS Cupertino Paywall template (`CupertinoPaywall`) in the example app featuring inset grouped layout, Cupertino dynamic system colors, tactile haptic feedback (`HapticFeedback.selectionClick()`), and verified responsive high-text-scale support.
* **Transitive Dependency Alignments**:
  * Upgraded transitive dependencies (`shared_preferences_android: 2.5.5`, `shared_preferences_foundation: 2.6.2`, `vector_math: 2.4.4`, `vm_service: 15.4.0`, `web: 1.1.2`).

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
  * Upgraded dependencies to latest releases (`equatable: ^3.0.0`, `in_app_purchase: ^3.3.1`, `in_app_purchase_android: ^0.5.5`, `in_app_purchase_storekit: ^0.4.17`, `shared_preferences: ^2.5.6`).

## 0.0.1

* Initial release with cross-platform store abstraction for Android, iOS, and macOS.
* Added consumable delivery results, durable entitlements, restore handling, and verification hooks.
* Added `ChangeNotifier` scope/controller integration and theme-aware subscription page.
* Added example app and platform setup documentation.
