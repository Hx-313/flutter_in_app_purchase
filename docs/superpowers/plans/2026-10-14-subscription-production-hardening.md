# Subscription Package Production Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax.

**Goal:** Make the subscription package's store, entitlement, consumable-delivery, and paywall flows reliable and release-checkable while keeping local verification as the default.

**Architecture:** Keep the current `subscriptions/domain`, `data`, and `presentation` boundaries. Add a durable consumable-delivery record to the domain/storage contract, make the service replay-safe, then expose the state/actions through BLoC and the existing paywall. Store APIs remain behind the official plugin adapter; secure verification remains a host-injected `PurchaseVerifier`.

**Tech Stack:** Dart 3.12.2+, Flutter 3.44+, `in_app_purchase`, `flutter_bloc`, `shared_preferences`, `flutter_test`. No new runtime dependency is planned.

**Spec:** `docs/superpowers/specs/2026-10-14-subscription-production-hardening-design.md`

## Global Constraints

- Preserve the package constraints `sdk: ^3.12.2` and `flutter: ">=3.44.0"`.
- Keep the built-in store adapter limited to Android, iOS, and macOS.
- Keep `VerificationMode.local` as the default; `serverVerified` must fail closed without an injected verifier.
- Do not add a concrete network verifier or assume a backend request/response protocol.
- Do not add custom BillingClient or StoreKit implementations.
- Do not persist raw receipt/verification payloads in the default preferences storage.
- Pending consumable delivery is at-least-once; host apps must fulfill idempotently using the stable purchase ID, then acknowledge.
- Do not select a license or release version, and do not claim live-store validation without sandbox runs.
- Git commands currently fail because this checkout has no usable Git metadata; do not initialize or rewrite repository metadata as part of this plan.

## Review Focus

- A purchase with neither a store purchase ID nor a transaction date must produce a visible error, remain unmarked, and remain incomplete; test in Task 3.
- A transient verifier or storage error must not complete the transaction or grant access; test in Task 3.
- A restored non-renewing purchase whose transaction date is in the past must stay expired immediately; test in Task 3.
- A duplicate consumable delivery after restart must appear once in the pending outbox and remain until acknowledgement; test in Tasks 2–3.
- A store that changes from unavailable to available must recover through retry and reach ready with products; test in Task 4.

---

### Task 1: Define durable consumable delivery and storage contracts

**Files:**
- Create: `lib/features/subscriptions/domain/entities/consumable_delivery.dart`
- Modify: `lib/features/subscriptions/data/datasources/subscription_storage_data_source.dart`
- Modify: `lib/features/subscriptions/domain/repositories/subscription_repository.dart`
- Modify: `lib/flutter_in_app_purchase.dart`
- Modify: `test/flutter_in_app_purchase_test.dart`
- Modify: storage fakes in `test/subscription_service_test.dart`, `test/subscription_scope_test.dart`, and `test/subscription_page_test.dart`

**Interfaces:**
- Produces `ConsumableDelivery({required String purchaseId, required String productId, required DateTime purchasedAt})`, an immutable Equatable value.
- Storage and repository expose `Future<List<ConsumableDelivery>> loadPendingConsumables()`, `Future<void> savePendingConsumable(ConsumableDelivery delivery)`, and `Future<void> acknowledgeConsumable(String purchaseId)`.

- [x] **Step 1: Write the failing model and contract tests.** Add `expect(first, equals(second))` and `expect(first.props, [purchaseId, productId, purchasedAt])` to the `ConsumableDelivery compares by value` test. Update memory fakes with the three new contract methods.
- [x] **Step 2: Run the targeted test and confirm the missing type/API failure.** Run `flutter test test/flutter_in_app_purchase_test.dart --plain-name "ConsumableDelivery compares by value" --concurrency=1`. Expected: FAIL because `ConsumableDelivery` is not defined.
- [x] **Step 3: Implement the entity and contracts.** Add the exact fields above, Equatable `props`, and export the entity from the public barrel.
- [x] **Step 4: Run the targeted test and update dependent fakes.** Run `flutter test test/flutter_in_app_purchase_test.dart --concurrency=1`, `flutter test test/subscription_service_test.dart --concurrency=1`, `flutter test test/subscription_scope_test.dart --concurrency=1`, and `flutter test test/subscription_page_test.dart --concurrency=1`. Expected: PASS with all repository/storage fakes implementing the new interface.

### Task 2: Persist and replay pending consumable deliveries

**Files:**
- Modify: `lib/features/subscriptions/data/datasources/shared_preferences_subscription_storage_data_source.dart`
- Create: `test/shared_preferences_subscription_storage_test.dart`

**Interfaces:** Consume the Task 1 storage contract.

- [x] **Step 1: Write failing storage tests.** With `SharedPreferences.setMockInitialValues({})`, add tests `loadPendingConsumables_returnsStagedRecordsAfterReinitialization`, `savePendingConsumable_isIdempotentByPurchaseId`, `acknowledgeConsumable_removesOnlyMatchingId`, and `loadPendingConsumables_discardsMalformedRecordsAndKeepsValidOnes`.
- [x] **Step 2: Run the new storage tests and confirm they fail.** Run `flutter test test/shared_preferences_subscription_storage_test.dart --concurrency=1`. Expected: FAIL because the adapter does not implement pending-delivery persistence.
- [x] **Step 3: Implement JSON-backed pending delivery storage.** Namespace it under the configured storage prefix; deduplicate by `purchaseId`; persist only the fields in `ConsumableDelivery`, never receipt data.
- [x] **Step 4: Run the storage tests and existing package tests.** Expected: PASS; pending deliveries survive adapter reinitialization and acknowledgement is idempotent.

### Task 3: Make purchase processing replay-safe and expiry-correct

**Files:**
- Modify: `lib/features/subscriptions/domain/usecases/subscription_service.dart`
- Create: `test/subscription_service_reliability_test.dart`

**Interfaces:** Consume Task 1–2 storage methods. Add `List<ConsumableDelivery> get pendingConsumables`, `Stream<List<ConsumableDelivery>> get consumableDeliveryStream`, and `Future<void> acknowledgeConsumablePurchase(String purchaseId)` to `SubscriptionService`.

- [x] **Step 1: Write failing service tests.** Add `processPurchase_persistsEntitlementBeforeMarkerAndCompletion` (call log equals `['saveEntitlement', 'markPurchaseProcessed', 'complete']`), `processPurchase_doesNotCompleteWhenVerifierUnavailable`, `processPurchase_doesNotCompleteWhenStorageSaveFails`, `processPurchase_withoutStableIdEmitsErrorWithoutMarking`, `processPurchase_emitsPendingWithoutCompleting`, `processPurchase_emitsCanceledWithoutGranting`, `processPurchase_emitsErrorWithoutGranting`, `processPurchase_stagesConsumableBeforeCompletion`, `restore_nonRenewingUsesTransactionDateForExpiry`, `restore_expiredNonRenewingIsInactiveImmediately`, `initialize_replaysConsumableUntilAcknowledged`, `restore_noPurchasesReturnsNone`, `restore_storeFailureReturnsFailure`, and `refresh_reverifiesProcessedDurablePurchaseWithoutDuplicateSuccess`.
- [x] **Step 2: Run the reliability tests and confirm each failure is behavioral.** Run `flutter test test/subscription_service_reliability_test.dart --concurrency=1`. Expected: FAIL on current ordering, expiry, retry, or delivery behavior.
- [x] **Step 3: Implement minimal replay-safe processing.** Use a nonempty `purchaseId`; otherwise use `'$productId:${transactionDate.toUtc().microsecondsSinceEpoch}'`; if both are absent, emit an error without marking or completing. Persist a durable entitlement or pending consumable delivery before marking the transaction processed; complete only after a terminal verified outcome is durable; leave transient verifier/storage failures incomplete; safely retry already-saved state; in `serverVerified` mode only, reverify processed durable records during explicit refresh/restore while suppressing duplicate success events.
- [x] **Step 4: Correct expiry evaluation.** For local non-renewing products, calculate expiry as transaction date plus configured duration, falling back to current time only when the store has no transaction date; set expired state/access before publishing the entitlement.
- [x] **Step 5: Run service reliability, existing service, and domain tests.** Expected: PASS; completion only follows durable outcomes, replay does not duplicate grants/deliveries, and expired restored access is inactive at once.

### Task 4: Correct availability, retry, restore, and BLoC state/actions

**Files:**
- Modify: `lib/features/subscriptions/data/datasources/in_app_purchase_store_data_source.dart`
- Modify: `lib/features/subscriptions/domain/entities/subscription_config.dart`
- Modify: `lib/features/subscriptions/domain/usecases/subscription_service.dart`
- Modify: `lib/features/subscriptions/presentation/bloc/subscription_event.dart`
- Modify: `lib/features/subscriptions/presentation/bloc/subscription_state.dart`
- Modify: `lib/features/subscriptions/presentation/bloc/subscription_bloc.dart`
- Modify: `test/subscription_scope_test.dart`
- Create: `test/subscription_bloc_test.dart`

**Interfaces:** `SubscriptionSnapshot` adds immutable `pendingConsumables`. `SubscriptionBloc` adds `void purchase(String productId)`, `void restore()`, `void refresh()`, and `void acknowledgeConsumablePurchase(String purchaseId)`, each dispatching its existing/new event.

- [x] **Step 1: Write failing retry/unavailable/BLoC tests.** Add `initialize_unavailableStoreEmitsUnavailable`, `initialize_retriesAfterStoreBecomesAvailable`, `purchase_dispatchesPurchaseRequested`, `restore_dispatchesRestoreRequested`, `refresh_dispatchesRefreshRequested`, and `acknowledgeConsumable_updatesSnapshot`. Assert unavailable/ready phases, fake operation counts, and the pending delivery list after acknowledgement.
- [x] **Step 2: Run the new tests and confirm they fail.** Run `flutter test test/subscription_bloc_test.dart --concurrency=1` and `flutter test test/subscription_scope_test.dart --concurrency=1`. Expected: FAIL because unavailable state is never emitted, initialization cannot retry, and convenience methods/state are absent.
- [x] **Step 3: Implement retryable initialization and availability reporting.** Reuse one purchase-stream subscription, but retry availability/product queries on subsequent initialization after unavailable or failed setup; load saved entitlements and create the expiry timer only on the first successful initialization.
- [x] **Step 4: Make restore completion-driven.** Remove the fixed `restoreSettleTimeout` setting and await the official plugin restore future, then drain queued purchase processing before returning restored/none/failure.
- [x] **Step 5: Add BLoC consumable state and convenience methods.** Subscribe/cancel the delivery stream with the other service streams; dispatch acknowledgement and update `SubscriptionSnapshot` without adding UI logic to the BLoC.
- [x] **Step 6: Run BLoC, scope, restore, and service tests.** Expected: PASS, including unavailable-to-ready retry and restore without a fixed multi-second wait.

### Task 5: Complete paywall plan content and ordering

**Files:**
- Create: `lib/features/subscriptions/presentation/widgets/subscription_plan_content.dart`
- Modify: `lib/features/subscriptions/presentation/pages/subscription_page.dart`
- Modify: `lib/features/subscriptions/presentation/widgets/subscription_body.dart`
- Modify: `lib/features/subscriptions/presentation/widgets/subscription_product_tile.dart`
- Modify: `lib/features/subscriptions/domain/entities/product_definition.dart` to remove unused `tags` and preserve `displayName`/`priority` behavior
- Modify: `lib/flutter_in_app_purchase.dart`
- Modify: `test/subscription_page_test.dart`

**Interfaces:** `final class SubscriptionPlanContent extends Equatable` with `SubscriptionPlanContent({required this.productId, this.title, this.description, this.perks = const [], this.badge, this.purchaseLabel})`; `SubscriptionPage` accepts `List<SubscriptionPlanContent> planContent = const []` and exports the model through the package barrel.

- [x] **Step 1: Write failing widget tests.** Add `rendersPlanContentOverrides`, `fallsBackToDefinitionAndStoreMetadata`, and `sortsByPriorityStably`; assert title, description, each perk, badge, button label, store price, and original order for equal priorities.
- [x] **Step 2: Run the focused widget tests and confirm they fail.** Run `flutter test test/subscription_page_test.dart --plain-name "renders plan content overrides" --concurrency=1`. Expected: FAIL because the model and rendering do not exist.
- [x] **Step 3: Implement the presentation-only content value and render path.** Store price/currency remain store-provided; products without overrides retain current behavior; sort by configured priority with stable source order for ties; remove the unused `tags` field from constructor, props, and README examples.
- [x] **Step 4: Run all page tests.** Expected: PASS, including existing product/restore rendering.

### Task 6: Unit-test the official purchase mapping boundary

**Files:**
- Create: `lib/features/subscriptions/data/datasources/in_app_purchase_purchase_mapper.dart`
- Modify: `lib/features/subscriptions/data/datasources/in_app_purchase_store_data_source.dart`
- Create: `test/in_app_purchase_purchase_mapper_test.dart`

**Interfaces:** `final class InAppPurchasePurchaseMapper` exposes `StorePurchase map(iap.PurchaseDetails purchase)` and is used by both purchase-stream mapping and Android past-purchase mapping.

- [x] **Step 1: Write mapper tests.** Construct platform-interface `PurchaseDetails` values and add `mapsPurchaseStatusesAndMetadata`; assert mappings for pending, purchased, restored, canceled, error, transaction date, verification fields, completion flag, and store error metadata.
- [x] **Step 2: Run mapper tests and confirm they fail.** Run `flutter test test/in_app_purchase_purchase_mapper_test.dart --concurrency=1`. Expected: FAIL because the mapper does not exist.
- [x] **Step 3: Implement the pure mapping boundary and replace the adapter's private mapping body.** Preserve current platform-specific purchase/query/complete calls.
- [x] **Step 4: Run mapper and package tests.** Expected: PASS for every status and metadata mapping.

### Task 7: Update consumer docs, example, and release checks

**Files:**
- Modify: `README.md`
- Modify: `example/lib/main.dart`
- Modify: `CHANGELOG.md`
- Modify: `test/flutter_in_app_purchase_test.dart`

**Interfaces:** Use the public `SubscriptionPlanContent`, BLoC convenience methods, pending consumable acknowledgement, and injected `PurchaseVerifier` APIs from Tasks 3–5. Keep local mode explicit in the example.

- [x] **Step 1: Add/adjust `publicApi_exportsPlanAndDeliveryTypes`.** Assert `SubscriptionPlanContent` and `ConsumableDelivery` are available from the package barrel and the example's configured products satisfy domain validation.
- [x] **Step 2: Run the focused API tests and confirm missing exports/behavior fail.** Run `flutter test test/flutter_in_app_purchase_test.dart --concurrency=1`. Expected: FAIL if public exports or documented API are incomplete.
- [x] **Step 3: Rewrite the README/example for implemented behavior.** Include local-mode security limits, verifier example sending neutral data to an app-owned backend, account-specific `storageKeyPrefix`, stable consumable ID + acknowledgement, supported platforms, setup, and sandbox test matrix. Remove any claim not covered by implementation.
- [x] **Step 4: Run formatter, analyzer, package tests, example analysis, and publish dry-run.** Commands: `dart format --output=none --set-exit-if-changed .`; `flutter analyze`; `flutter test --no-pub --concurrency=1`; from `example/`, `flutter analyze`; from the package root, `flutter pub publish --dry-run`. Expected: all code checks pass; publish dry-run reports only maintainer-owned metadata/license actions, if any.
- [x] **Step 5: Record external release gates.** Do not replace `LICENSE` or change `version` without maintainer direction. Record that concrete backend credentials/contracts and live Android/iOS/macOS sandbox checks remain external release work.

## Implementation Notes

- The pinned `in_app_purchase` plugin documents restore results on `purchaseStream`; its platform restore future is the completion boundary. Tests must await service processing after that future rather than sleep for the current two-second default.
- The new persistent consumable record is a delivery outbox, not an entitlement or a substitute for the app's reward ledger.
- Current Git operations fail in this checkout. Keep changes reviewable and uncommitted unless repository metadata is restored by the environment.
