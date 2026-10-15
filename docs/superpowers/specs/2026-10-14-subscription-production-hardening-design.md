# Subscription Package Production Hardening Design

## Goal

Raise the existing Flutter subscription package from an architecture prototype
to a reliable, well-tested package suitable for host apps to integrate with
real stores. Local verification remains the default. Apps that require trusted
entitlements can inject a `PurchaseVerifier` that sends store data to their own
backend. This package will not invent a backend protocol or claim that local
verification is secure.

## Approved scope

- Preserve the current feature boundaries and official `in_app_purchase`
  adapters for Android, iOS, and macOS.
- Make purchase processing replay-safe: persist a verified result before
  completing a store transaction, and do not lose a transaction when storage
  or verification is unavailable.
- Anchor local non-renewing access to the store transaction date and evaluate
  expiry immediately when a purchase is restored or processed.
- Reconcile already-seen durable purchases during explicit refresh/restore
  without emitting duplicate purchase success or consumable delivery events.
- Report store unavailability as an unavailable phase rather than a ready
  state with an empty product list.
- Make consumable delivery durable and at-least-once, with a stable transaction
  identifier and an explicit acknowledgement API. The host app remains
  responsible for idempotent reward fulfillment, preferably on its backend.
- Complete the documented paywall content model (title, description, perks,
  badge, and purchase label) and BLoC convenience actions.
- Add deterministic tests for domain rules, purchase recovery, verification,
  restore, BLoC state, storage, store mapping, and widgets.
- Update the README and example to document local-mode limitations, backend
  verifier injection, account-specific storage prefixes, consumable
  acknowledgement, supported platforms, and real-store manual checks.

## Out of scope

- A concrete HTTP verifier, endpoint URL, payload schema, authentication
  scheme, or server implementation. These are host-app/backend decisions.
- Custom BillingClient or StoreKit implementations.
- Exactly-once reward delivery across a Flutter app and a remote backend. The
  package will provide durable at-least-once delivery with a stable ID; the
  host must make fulfillment idempotent before acknowledging it.
- Claims of local-mode expiry, cancellation, refund, grace-period, or pause
  detection for auto-renewing products.
- Selecting a software license or release version on behalf of the maintainer.
- Automated testing against live App Store Connect or Google Play accounts.

## Verification modes and trust boundary

`VerificationMode.local` remains the default for compatibility and prototypes.
It derives only the state the client can know. Documentation must say clearly
that locally persisted entitlements are editable client state and must not be
used as the authority for paid server resources.

`VerificationMode.serverVerified` requires an injected `PurchaseVerifier`.
The service fails closed when no verifier exists, passes neutral purchase data
to the verifier, and applies its normalized result. Transient verifier or
storage failures leave the store transaction unfinished for retry. Confirmed
valid or invalid outcomes are persisted before the native purchase is
completed. Reprocessing the same transaction is idempotent.

In `serverVerified` mode, explicit refresh/restore can reverify an already
processed durable purchase to refresh its entitlement state. Duplicate
purchase-success notifications are suppressed. Local mode does not re-verify
store history to infer a renewal or cancellation. Server notifications,
account binding, and backend reconciliation outside explicit client refresh
remain host-owned.

## Purchase persistence and delivery

Storage gains a durable record for pending consumable delivery. A valid
consumable purchase is staged before native completion and becomes available
to the BLoC as a pending delivery. The consumer acknowledges it only after
fulfillment. The record includes the configured product ID and stable store
purchase ID; it does not persist raw receipt material. Pending deliveries are
replayed after initialization until acknowledged. If the store does not
provide a stable purchase ID, processing must not silently invent a shared
fallback key that could suppress a later purchase.

Durable entitlement writes are idempotent by entitlement ID. The service saves
the entitlement and the processed transaction marker before completing the
store transaction. If a later write or completion fails, store redelivery can
resume safely. Invalid verification is recorded and completed so a rejected
transaction does not loop. Pending transactions are never completed.

## Expiry and lifecycle

For local non-renewing purchases, expiry is transaction date plus the
configured duration. If the transaction date is absent, the documented
fallback is the current time. Restored products that are already expired do
not receive active access while waiting for the periodic timer. Server
verification can provide an authoritative expiry and lifecycle state.

Local auto-renewing purchases continue to expose active access with unknown
expiry until store/backend data says otherwise. The service does not infer
refund, cancellation, pause, grace period, or renewal state from missing local
events.

## Store availability and restore

Initialization distinguishes available, unavailable, and failed store setup.
The UI renders the unavailable message when the platform store reports
unavailable. Restore waits for the pinned plugin's restore future and drains
the service's queued purchase processing; it does not rely on an arbitrary
two-second delay. StoreKit's completion callback and Android's restore query
remain the adapter boundary. A restore failure remains distinguishable from
no purchases found.

## Presentation API

Add a presentation-only `SubscriptionPlanContent` value with required
`productId` and optional title, description, perks, badge, and purchase button
label. `SubscriptionPage` accepts a list of content values and matches them by
product ID. Store-provided price and currency remain authoritative. Products
without custom content use `ProductDefinition.displayName` when present, then
store metadata; `priority` orders plans descending with source order preserved
for ties. Remove the currently unused `ProductDefinition.tags` field. Add
`SubscriptionBloc` convenience methods for purchase, restore, refresh, and
consumable acknowledgement while retaining events for advanced users.

## Test and release checks

- Domain/configuration tests cover product constraints, local expiry, and
  known/unknown lifecycle state.
- Service tests cover purchase statuses, idempotency, staged consumables,
  verification valid/invalid/unavailable/throwing cases, transaction
  completion, restore, refresh, expiry, and disposal.
- Data tests cover preferences round trips, pending delivery replay, malformed
  values, transaction completion, and purchase mapping.
- BLoC/scope/widget tests cover unavailable state, convenience methods,
  content overrides, restore outcomes, and disposal.
- Run formatter, analyzer, package tests, example analysis, and
  `flutter pub publish --dry-run` after implementation.
- Keep Android/iOS/macOS sandbox purchase verification as a separate manual
  release checklist.

## Acceptance criteria

- No verified transaction is completed before its durable outcome is saved.
- A retry cannot duplicate entitlement grants or silently lose a consumable
  delivery; pending delivery remains available until acknowledged.
- Restoring an old non-renewing purchase cannot extend its local expiry.
- Server-verified mode fails closed and can refresh a previously processed
  durable entitlement without duplicating success events.
- Store unavailability is represented accurately in state and UI.
- All public examples compile against the exported API and tests exercise the
  changed layer boundaries.
- README claims match implemented behavior and distinguish local mode from
  backend-verified access.
- License choice, production backend, and live store checks are reported as
  maintainer/host release responsibilities.
