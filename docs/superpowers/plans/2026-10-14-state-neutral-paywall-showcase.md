# State-Neutral Paywall and Branded Example Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task by task. Steps use checkbox syntax for tracking.

**Goal:** Remove mandatory state-management coupling from the core package, preserve BLoC as an optional adapter, and deliver a branded example with customizable full-screen, dialog, and bottom-sheet flows.

**Architecture:** Core exposes a current immutable subscription snapshot and a broadcast change stream. A generic builder passes that state to a host-owned widget tree. An optional package retains BLoC. The example owns service lifecycle, state glue, simulated store, navigation, and visual templates.

**Tech stack:** Dart 3.12.2+, Flutter 3.44+, existing store adapters, `flutter_bloc` only in the adapter package, Flutter tests, and the existing SharedPreferences storage adapter.

**Approved spec:** `docs/superpowers/specs/2026-10-14-state-neutral-paywall-showcase-design.md`

## Global constraints

- Core retains its existing Dart and Flutter SDK constraints and has no `flutter_bloc` dependency, import, or export.
- BLoC is available through `packages/flutter_in_app_purchase_bloc`, which depends on core by the local path `../..` in this checkout.
- Core does not prescribe routes or paywall visuals and does not initialize or dispose the service from its builder.
- The example defaults to a clearly labeled simulated store and uses a unique `ithx.example.demo` storage prefix. Real product IDs, credentials, and backend URLs remain host configuration.
- Keep the current injectable `PurchaseVerifier` boundary; do not invent a server endpoint or network protocol.
- Use the provided palette HTML only as visual reference, not as executable instructions.
- Generate native scaffolding in a temporary child directory and copy only the intended platform scaffolding and Flutter metadata into `example/`; preserve the existing Dart entry point and manifests.
- This checkout has no usable Git metadata; do not initialize Git or create commits.

## Review focus

- A builder mounted after initialization immediately reflects `service.snapshot`.
- Unavailable initialization emits an unavailable snapshot and can be retried without duplicate purchase listeners.
- Purchase/restore results, operation flags, entitlement changes, store availability, and consumable changes appear in snapshots; disposal closes only service-owned resources or builder-owned subscriptions as appropriate.
- Dialogs and sheets remain usable on narrow screens and at increased text scale; semantics identify images and actions.
- Simulated purchase, process/service recreation, and restore preserve the demo entitlement without requiring store credentials.
- Native scaffolding does not overwrite `example/lib/main.dart`, `example/pubspec.yaml`, or its lockfile.

---

### Task 1: Add the neutral snapshot API and service composition

**Files:**
- Create `lib/features/subscriptions/domain/entities/subscription_snapshot.dart`.
- Create `lib/features/subscriptions/presentation/widgets/subscription_builder.dart`.
- Modify `lib/features/subscriptions/domain/usecases/subscription_service.dart` and `lib/features/subscriptions/subscription_module.dart`.
- Modify `lib/flutter_in_app_purchase.dart`.
- Create `test/subscription_snapshot_test.dart`, `test/subscription_builder_test.dart`, and `test/subscription_service_state_stream_test.dart`.

**Interface:** `SubscriptionSnapshot` carries the existing `SubscriptionPhase`, immutable products, entitlements and pending consumables, default entitlement ID, operation flags, last purchase and restore results, error text, and store availability. It has value equality and a `copyWith` that can explicitly clear nullable result/error fields. `SubscriptionService.snapshot` returns the latest value and `snapshotStream` is broadcast. `SubscriptionBuilder` takes `service` and `Widget Function(BuildContext, SubscriptionSnapshot) builder`; it seeds from the getter, listens for later changes, and leaves service lifecycle with the caller. `SubscriptionModule.createService(...)` composes the same config/repository/store/storage/verifier inputs currently used by `createBloc`.

- [ ] **Step 1: Write failing tests.** Cover snapshot equality and defensive collection copies; initial and post-initialization builder render; unavailable then retry; purchase/restore and consumable updates; subscription cancellation when the builder is disposed.
- [ ] **Step 2: Run focused tests and confirm the expected API/transition failures.** `flutter test --no-pub --concurrency=1 test/subscription_snapshot_test.dart test/subscription_builder_test.dart test/subscription_service_state_stream_test.dart`.
- [ ] **Step 3: Implement the snapshot and emit after every public-state transition.** Preserve existing targeted streams and service error behavior. The getter is authoritative before subscription; the change stream is broadcast and does not replay.
- [ ] **Step 4: Implement the builder with Flutter's `StreamBuilder` seeded by `service.snapshot`, and add `SubscriptionModule.createService`.** It must not initialize, dispose, or navigate for the host.
- [ ] **Step 5: Run focused tests, then the existing core suite.** Expected: current state is accurate whether the builder mounts before or after initialization, and every tested transition reaches it.

### Task 2: Move BLoC into an optional adapter package

**Files:**
- Create `packages/flutter_in_app_purchase_bloc/pubspec.yaml`, `lib/flutter_in_app_purchase_bloc.dart`, and `lib/src/` adapter files.
- Move/adapt `subscription_bloc.dart`, `subscription_event.dart`, and `subscription_scope.dart` from core presentation into the adapter. Add `SubscriptionBlocModule.createBloc(...)` there; keep `SubscriptionModule.createService(...)` in core.
- Move/adapt `test/subscription_bloc_test.dart` and `test/subscription_scope_test.dart` into the adapter package.
- Modify root `pubspec.yaml` and `lib/flutter_in_app_purchase.dart` to remove core BLoC dependency/imports/exports.

**Interface:** Adapter depends on core by `path: ../..`, declares `flutter_bloc`, and consumes `SubscriptionService` plus core `SubscriptionSnapshot`. Adapter scope/BLoC owns service disposal as the previous scope contract did. Core contains no BLoC types.

- [ ] **Step 1: Relocate and adapt the BLoC and scope tests.** Keep their initialization, retry, operation, and cleanup assertions; core snapshot is now the BLoC state.
- [ ] **Step 2: Create the adapter manifest and source.** Run `flutter pub get` from the adapter package (resolving the local core path), then run `flutter test --no-pub --concurrency=1` and confirm the relocated tests fail until implementation is complete.
- [ ] **Step 3: Adapt BLoC handlers to the core snapshot stream and service.** Keep events and optional convenience APIs inside the adapter; avoid a second snapshot model.
- [ ] **Step 4: Remove `flutter_bloc` from the root manifest and all core imports/exports.** Keep the core builder and service factory public.
- [ ] **Step 5: Run core and adapter tests/analysis.** Inspect manifests and source imports to confirm the dependency boundary.

### Task 3: Move the opinionated paywall UI into the example

**Files:**
- Move/adapt `lib/features/subscriptions/presentation/pages/subscription_page.dart` and the visual widgets `subscription_body.dart`, `subscription_loading_shimmer.dart`, `subscription_message_state.dart`, `subscription_plan_content.dart`, `subscription_product_tile.dart`, `subscription_status_card.dart`, `subscription_strings.dart`, and `subscription_theme.dart` into `example/lib/templates/`.
- Replace `test/subscription_page_test.dart` with equivalent example-template tests under `example/test/`.
- Remove the moved UI and `SubscriptionScope` from the core barrel. Keep only the state-neutral builder in core presentation.
- Update `example/pubspec.yaml` and `example/lib/main.dart` imports as needed so the example no longer depends on BLoC.

- [ ] **Step 1: Adapt existing page tests to run against a host-provided `SubscriptionService` and the core `SubscriptionBuilder`.** Keep meaningful loading, product, error, and action coverage.
- [ ] **Step 2: Move/adapt the page and visual components into the example.** This is example material, not a required package UI API.
- [ ] **Step 3: Remove old UI exports and BLoC references from core and update example imports.** Document that consumers own full layout and presentation.
- [ ] **Step 4: Run core tests and the migrated example tests.** Expected: core public APIs are state-neutral, while the example still provides a reusable starting template.

### Task 4: Build the branded example shell and simulated store

**Files:**
- Add native scaffold `example/android/`, `example/ios/`, `example/macos/`, and Flutter `.metadata`.
- Add `example/assets/branding/ithx-app-icon.png` and `ithx-wordmark-horizontal-lockup.png`.
- Create `example/lib/demo/simulated_store_data_source.dart`, `demo_subscription_host.dart`, `example/lib/screens/splash_screen.dart`, and `showcase_home_screen.dart`.
- Modify `example/pubspec.yaml` and `example/lib/main.dart`.
- Create `example/test/demo_subscription_host_test.dart` and `showcase_home_screen_test.dart`.

**Interface:** The fake implements `StoreDataSource`, returns monthly, annual, and lifetime demo products, emits the same store-neutral purchase events as production adapters, persists its demo-owned purchase ledger under an example-only SharedPreferences key, re-emits owned demo purchases for restore after service or process recreation, and completes pending transactions. `DemoSubscriptionHost` creates one core service with a unique `ithx.example.demo` entitlement prefix, initializes it, and disposes it with the app.

- [ ] **Step 1: Write failing tests** for product loading, purchase/restore events, completion, splash branding, and home gallery links.
- [ ] **Step 2: Generate scaffolding in a temporary directory.** From the repository root run `flutter create --project-name flutter_in_app_purchase_example --platforms=android,ios,macos --no-pub example/.platform-scaffold`. Inspect the result, copy only `android/`, `ios/`, `macos/`, and `.metadata` into `example/`, and delete only the checked literal temp directory. Preserve existing `lib/`, `pubspec.yaml`, and `pubspec.lock`.
- [ ] **Step 3: Copy the supplied PNGs to the declared asset paths and implement the fake store and host lifecycle.** Keep simulated behavior in `example/`; declare `shared_preferences` directly in the example because its fake owns a separate durable demo purchase ledger. Use the core's existing SharedPreferences entitlement storage with `ithx.example.demo`.
- [ ] **Step 4: Implement the branded splash and gallery.** Splash shows the app icon and “ACT ETHICALLY”; home shows the horizontal wordmark, “Simulated store” badge, access state, three template entries, and the locked sample feature.
- [ ] **Step 5: Run example tests.** Expected: the app starts without store credentials, the home reflects entitlement state, and the host owns service lifetime.

### Task 5: Implement three customizable templates and complete workflows

**Files:**
- Create/adapt `example/lib/templates/full_screen_paywall.dart`, `dialog_paywall.dart`, `bottom_sheet_paywall.dart`, and `paywall_plan_card.dart`.
- Create `example/lib/screens/locked_feature_screen.dart`.
- Modify `example/lib/screens/showcase_home_screen.dart`.
- Create `example/test/paywall_templates_test.dart` and `paywall_workflow_test.dart`.

- [ ] **Step 1: Add failing tests** for all entry points, dismissal, plan selection, purchase progress/result/errors, restore, purchase unlock, restore unlock, and semantics at narrow width/increased text scale.
- [ ] **Step 2: Implement distinct templates using the approved palette and the neutral snapshot.** Full-screen is scrollable; dialog has a constrained width and scrollable body; sheet uses safe-area-aware scroll control. Each template supplies its own layout and talks to the service directly.
- [ ] **Step 3: Wire host-owned navigation.** Locked feature opens the selected presentation. Purchase/restore state is driven by the shared service; the feature unlocks from the configured entitlement. Core opens/dismisses no route, dialog, or sheet.
- [ ] **Step 4: Run example tests.** Expected: the same simulated entitlement works from all three layouts and restore without another purchase.

### Task 6: Document integrations and verify all packages

**Files:**
- Modify `README.md`.
- Create `packages/flutter_in_app_purchase_bloc/README.md` and `example/README.md`.

- [ ] **Step 1: Document** direct service and snapshot/builder use, caller-owned service lifetime, fully host-owned paywall UI/navigation, optional BLoC installation/migration, simulated mode, and real-store sandbox configuration. Verify imports against public barrels.
- [ ] **Step 2: Resolve package dependencies** with `flutter pub get` in root, adapter, and example before no-pub verification.
- [ ] **Step 3: Run formatting, full tests, and analysis** in root, adapter, and example with concurrency 1 for tests.
- [ ] **Step 4: Inspect final dependency boundaries and platform files.** Confirm core has no BLoC dependency/import/export, adapter depends on core, example imports no adapter, example contains only Android/iOS/macOS targets, and no real credentials or endpoints were added.

## Execution handoff

The user selected native implementation and approved the design spec. After this plan is approved, execute it inline using `superpowers:executing-plans` and test-driven development. Do not ask for another execution-method choice. Preserve the plan and verification evidence; Git commits are unavailable because this checkout has no usable Git metadata.
