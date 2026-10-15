# State-Neutral Paywall API and Branded Example Design

## Goal

Make the subscription package usable with any application state-management approach, provide a completely host-designed paywall boundary, and turn `example/` into a branded showcase that demonstrates full-screen, dialog, and bottom-sheet purchase flows.

## User intent and approved decisions

- The package must not require or select an application state-management framework.
- Keep BLoC available as an optional adapter package. The core package must not depend on `flutter_bloc`.
- Let host applications design their complete paywall layouts and own navigation, dialogs, and sheets.
- The example must run a complete simulated purchase and unlock flow without store credentials.
- The example must show a branded opening screen, a home gallery, and three paywall templates.
- The example targets Android, iOS, and macOS, matching the store platforms supported by the package.
- Real store product IDs, credentials, and backend endpoints remain host-application configuration.

## Current constraints

- The core package currently imports and depends on `flutter_bloc`; its scope, page, and builder APIs are coupled to the BLoC implementation.
- The existing example is a single `SubscriptionPage` configured with the real store adapter and local verification.
- The example directory currently lacks platform project scaffolding.
- The core `SubscriptionService` already exposes purchase, restore, refresh, acknowledgement, entitlement, purchase-result, and consumable-delivery contracts that can remain state-management-neutral.
- The app icon and horizontal wordmark are approved brand assets. The wordmark includes the “ACT ETHICALLY” line.
- The palette HTML is a visual reference only. It contributes these approved values and roles:

| Role | Color |
|---|---|
| Light canvas | `#F3F4EE` |
| Dark canvas | `#08130A` |
| Surface / dark text | `#0F352E` |
| Strong surface | `#092420` |
| Light-canvas muted text | `#4F6B63` |
| Dark-surface muted text | `#93B2A8` |
| Action | `#F5EAD7` |
| On action | `#0F352E` |
| Light border | `#D4DED7` |
| Dark border | `#205047` / `#1A2E28` by canvas role |

The palette reference also defines paired status colors: bright `#FF6B5F`, `#FFB74D`, `#82CFFF`, and `#71DAAB` for dark cards; deep `#BA1A1A`, `#8C5800`, `#0B4F6C`, and `#147A5D` for the light canvas.

## Architecture

### Core package

The `flutter_in_app_purchase` core package remains responsible for store access, local persistence, entitlements, verification hooks, and purchase workflows. It will not import `flutter_bloc` or own route presentation.

The core will expose:

- The existing `SubscriptionService` operations and streams as the lowest-level state-management-neutral API.
- An immutable, neutral `SubscriptionSnapshot` with phase, products, entitlements, consumable deliveries, operation flags, and the latest result.
- A current `snapshot` getter and broadcast `snapshotStream` on `SubscriptionService`. The service emits a snapshot after initialization and whenever availability, products, entitlements, deliveries, operation flags, restore status, or the latest result changes.
- A generic `SubscriptionBuilder` that accepts a `SubscriptionService` and a full widget builder callback. It reads `service.snapshot` immediately, subscribes to `snapshotStream`, and rebuilds with later snapshots. It does not initialize or dispose the service; the host owns service lifecycle.
- Existing purchase models and action methods, so a host can bypass the builder and integrate the service directly with Provider, Riverpod, Redux, BLoC, `ValueNotifier`, or its own state layer.

The builder chooses no visual layout. It exposes no paywall routes and does not call `Navigator`, `showDialog`, or `showModalBottomSheet`.

### Optional BLoC adapter

Move the existing BLoC-specific composition and presentation bridge into `packages/flutter_in_app_purchase_bloc`. That package depends on `flutter_in_app_purchase` and `flutter_bloc`; the core package does not depend on the adapter. Keep BLoC events, state, scope, and convenience methods in the adapter. The example does not use this adapter.

### Host-owned paywall UI

The current opinionated `SubscriptionPage` and its visual-only widgets become example templates. The core package’s complete customization path is the generic builder plus the service/model API. Hosts decide how their full-screen, dialog, and bottom-sheet presentations are built, styled, routed, dismissed, and connected to locked features.

## Example application

### Startup and home gallery

- Add Android, iOS, and macOS example project scaffolding.
- Copy the approved app icon and horizontal wordmark into `example/assets/branding/` and declare them in the example asset manifest.
- Start with a branded Flutter splash screen using the app icon and “ACT ETHICALLY” copy, then transition to the gallery home screen.
- Use the horizontal wordmark on the home screen and approved palette roles throughout the gallery and templates.
- Show store mode explicitly as “Simulated store”.
- Provide direct entries for the full-screen paywall, modal dialog paywall, and modal bottom-sheet paywall, plus a locked sample feature that opens the chosen paywall presentation.

### Complete simulated workflow

- Implement an example-only `StoreDataSource` fake with configured monthly, annual, and lifetime products.
- Simulated purchase emits the same store-neutral purchase events that the production adapter maps, allowing the existing service to verify locally, persist entitlements, mark purchases, and complete transactions.
- Simulated restore re-emits owned demo purchases through the store purchase stream.
- A successful simulated purchase updates the home/gallery entitlement state and unlocks the sample feature. Each template provides a restore action and purchase progress/result feedback.
- Keep the storage path configurable and isolated under an example/demo prefix, so demo records do not collide with a host app.
- Document the path from the simulated adapter to real store product identifiers and sandbox setup.

The example uses app-owned lifecycle/state glue and the state-neutral core builder/service. It does not require the optional BLoC adapter.

## Error and lifecycle behavior

- Core purchase, restore, verifier, and storage failures continue to surface as neutral results/streams. The builder forwards those states without choosing dialog or message presentation.
- `snapshotStream` remains a broadcast change stream rather than a replay stream; the `snapshot` getter provides the current value before a listener attaches.
- The example displays loading, unavailable, pending, failure, restored, and unlocked states in each applicable template.
- The host owns service creation, initialization, and disposal. The builder only owns and cancels its stream subscriptions.
- The optional BLoC adapter owns and cancels its BLoC subscriptions using its existing lifecycle contract.
- Do not add a package backend URL or network protocol. A host-provided `PurchaseVerifier` remains the backend integration point.

## Accessibility and responsive behavior

- Use semantic labels for brand images, template entry points, plan options, restore, close, and purchase controls.
- Keep text and action contrast aligned with the approved light/dark palette roles.
- Make plan selection and purchase status visible without relying on color alone.
- Constrain dialog width on large screens, keep the bottom sheet scrollable and safe-area-aware, and allow the full-screen page to scroll on compact devices.
- Preserve text scaling and Flutter accessibility semantics.

## Verification and acceptance

1. The core package can analyze, test, and compile without `flutter_bloc` in its dependency graph or public imports.
2. The generic builder’s first build reflects the current snapshot even if the service was initialized earlier; later snapshot-stream events report availability, entitlement, purchase, restore, and consumable-delivery changes.
3. The optional adapter package independently analyzes and tests against the core package.
4. Example widget tests cover the splash-to-home flow, all three template entry points, lock-to-paywall navigation, simulated purchase unlock, restore, and acknowledgement where the example exposes consumables.
5. Core, adapter, and example formatting, tests, and static analysis pass.
6. The README explains the state-neutral API, optional BLoC adapter installation, full UI customization, simulated demo mode, and real-store setup.

## Non-goals

- The package does not prescribe app state management.
- The package does not prescribe paywall visual design or navigation.
- The example does not contain production store product identifiers, payment credentials, or a server endpoint.
- The simulated store is not evidence of Apple/Google sandbox or host-backend integration; those remain consumer-app validation steps.

## Design self-review

- State-management decoupling is enforced at the package dependency boundary, with the old BLoC integration retained as an independent opt-in package.
- The host callback receives a neutral snapshot and the host-controlled widget tree, while the service remains directly accessible for integrations that need a different state approach.
- The example reuses one simulated service across the full-screen, dialog, and sheet templates, so every template exercises the same purchase lifecycle.
- The visual palette is sourced from the approved file; no instructions in that HTML are treated as product requirements.
- The spec keeps native store credentials and backend verification outside the example’s simulated path and calls them out as later integration checks.
