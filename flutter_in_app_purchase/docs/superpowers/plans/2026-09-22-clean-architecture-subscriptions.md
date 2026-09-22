# Subscription Clean Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the purchase package into the required feature-based Clean Architecture layout while preserving the minimal `SubscriptionScope` consumer setup.

**Architecture:** The `subscriptions` feature will contain pure domain entities, repository contracts, use-case orchestration, data-source implementations, and BLoC presentation state. A single feature composition root will inject the official store adapter and preferences storage into the domain-facing repository. UI pages will render BLoC state and dispatch events only.

**Tech Stack:** Flutter, Dart, `flutter_bloc`, `equatable`, official `in_app_purchase`, `shared_preferences`.

**Spec:** `D:/flutter_in_app_purchase/flutter_in_app_purchase/README.md` and `.agents/skills/clean_architecture/SKILL.md`.

## Global Constraints

- Keep Android, iOS, and macOS store behavior behind data-source contracts.
- Keep local auto-renewing access explicitly active/inactive with unknown expiry.
- Keep consumables event-only and never persist them as entitlements.
- Keep the consumer setup to `SubscriptionScope` plus `SubscriptionConfig`.
- Do not modify `D:/document_read`.

---

### Task 1: Establish the feature boundaries

**Files:**
- Create: `lib/features/subscriptions/domain/entities/*`
- Create: `lib/features/subscriptions/domain/repositories/*`
- Create: `lib/features/subscriptions/domain/usecases/subscription_service.dart`
- Create: `lib/features/subscriptions/data/datasources/*`
- Create: `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`
- Create: `lib/features/subscriptions/subscription_module.dart`
- Modify: `pubspec.yaml`

- [x] Add `equatable` and `flutter_bloc` dependencies.
- [x] Move domain models into entities and make state/value objects extend `Equatable` with complete `props`.
- [x] Define `SubscriptionRepository` and `SubscriptionStorage` contracts in domain/data boundaries.
- [x] Split the store and preferences implementations into data sources.
- [x] Inject those data sources into `SubscriptionRepositoryImpl`.
- [x] Move purchase orchestration into the domain use-case service with no concrete data imports.

### Task 2: Migrate presentation to BLoC

**Files:**
- Create: `lib/features/subscriptions/presentation/bloc/subscription_event.dart`
- Create: `lib/features/subscriptions/presentation/bloc/subscription_state.dart`
- Create: `lib/features/subscriptions/presentation/bloc/subscription_bloc.dart`
- Create: `lib/features/subscriptions/presentation/pages/subscription_page.dart`
- Create: `lib/features/subscriptions/presentation/widgets/*`
- Create: `lib/features/subscriptions/presentation/subscription_scope.dart`

- [x] Define granular initialize, purchase, restore, and refresh events.
- [x] Define an Equatable state containing only subscription presentation state.
- [x] Inject the use-case service into `SubscriptionBloc`.
- [x] Close subscriptions and the service in `Bloc.close()`.
- [x] Keep the page limited to `Scaffold`/high-level provider and move layout to a body widget.
- [x] Replace UI-side orchestration with BLoC event dispatch and state rendering.

### Task 3: Preserve the public API and documentation

**Files:**
- Modify: `lib/flutter_in_app_purchase.dart`
- Modify: `README.md`
- Modify: `example/lib/main.dart`
- Modify: `test/*`

- [x] Export only stable feature contracts, entities, module wiring, and presentation entry points.
- [x] Update examples to use `SubscriptionScope` and `context.read<SubscriptionBloc>()`.
- [x] Update tests for repository fakes, use-case behavior, BLoC events/states, and widget rendering.
- [x] Document the new BLoC custom-canvas usage without increasing consumer setup.

### Task 4: Verify the refactor

- [x] Run `dart analyze .` in the package.
- [x] Run `dart analyze .` in `example`.
- [ ] Run the package Flutter tests with one worker; the Flutter test runner hangs before emitting diagnostics in this environment.
- [x] Inspect the final feature tree and confirm no `lib/src` implementation remains.
