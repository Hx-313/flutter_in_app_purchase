# Unreleased

* Expose immutable subscription snapshots and a state-neutral widget builder.
* Move BLoC integration into the optional `smart_inapp_purchase_bloc` package.
* Keep paywall presentation and navigation in the host app; move UI templates to the example.
* Add an ITHX-branded showcase with a durable simulated purchase and restore flow.
* Persist verified purchases before native completion and report rejected restores as failures.
* Stage consumable deliveries until the host acknowledges fulfillment.
* Anchor local non-renewing expiry to the store transaction date and expose store retry state.
* Preserve purchase mapping diagnostics and cover purchase lifecycle reliability.

This release removes the BLoC and opinionated paywall UI exports from the core
package. Add `smart_inapp_purchase_bloc` separately if your app uses BLoC.

## 0.0.1

* Added configurable Android, iOS, and macOS purchase orchestration.
* Added consumable delivery results, durable entitlements, restore handling, and verification hooks.
* Added `ChangeNotifier` scope/controller integration and a theme-aware subscription page.
* Added an example app and platform setup documentation.
