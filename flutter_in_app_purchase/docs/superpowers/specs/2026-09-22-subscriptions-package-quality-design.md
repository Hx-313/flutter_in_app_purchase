# Subscription Package Quality and Consumer Modes Design

## Goal

Make the Flutter in-app-purchase package publishable-quality by documenting its
real behavior clearly, providing two deliberate presentation modes, and
covering the highest-risk purchase, verification, restore, persistence, and
lifecycle paths with deterministic tests.

## Scope

This change applies only to the package at
`D:/flutter_in_app_purchase/flutter_in_app_purchase`.

It covers:

- A built-in subscription page that can display consumer-provided plan copy,
  product information, badges, and perks.
- A custom-UI integration path based on `SubscriptionScope`, immutable
  `SubscriptionSnapshot`, and simple public purchase/restore/refresh actions.
- Deep unit, service, BLoC, scope, and widget coverage using injected fakes.
- A Pub.dev-quality README modeled on the information architecture of
  `smart_google_ads`, without copying its text or making unsupported claims.
- Verification commands and a manual store-test matrix for Android, iOS, and
  macOS.

## Non-goals

- No custom BillingClient or StoreKit implementation.
- No backend or receipt-verification server implementation.
- No attempt to automate purchases against Google Play or App Store sandbox
  environments from local unit tests.
- No redesign of the package's domain model beyond what is required for the
  two presentation modes and testability.
- No claim that local mode can determine exact subscription expiry, refund,
  grace-period, or pause state.

## Consumer modes

### Mode 1: built-in UI

The package will keep `SubscriptionPage` as the ready-made paywall. It will
accept an optional presentation-only list of plan content objects keyed by
configured product ID.

The content model will contain:

- `productId` — required store product ID.
- `title` — optional override; store title remains the fallback.
- `description` — optional explanatory copy.
- `perks` — zero or more user-provided benefit strings.
- `badge` — optional label such as `Popular` or `Best value`.
- `purchaseLabel` — optional per-plan CTA override.

The model belongs under presentation, not domain, because perks and marketing
copy do not affect entitlement or purchase decisions. The bundled page will
continue to work when no content is supplied by falling back to store product
metadata. When content is supplied, it will render only configured products,
preserve store-provided pricing, and invoke the existing package purchase and
restore workflows.

The page will continue to accept `SubscriptionStrings`, `SubscriptionTheme`,
and `onManageSubscription` so host applications control localization, visual
overrides, and platform account-management navigation.

### Mode 2: custom UI

Consumers will wrap their application or paywall in `SubscriptionScope` and
use `SubscriptionBuilder` or `BlocBuilder` with `SubscriptionSnapshot`.

`SubscriptionBloc` will expose small convenience methods that dispatch the
existing events:

```dart
void purchase(String productId);
void restore();
void refresh();
```

This keeps custom canvases independent of event-class construction while
preserving the existing BLoC state flow. The custom UI can read:

- `phase`, `products`, and `isStoreAvailable`;
- `isPurchasing` and `isRestoring`;
- `entitlements` and `hasAccess(entitlementId)`;
- `lastResult`, `lastRestoreStatus`, and `errorMessage`.

One-time effects such as purchase success, pending, cancellation, restore
completion, and verification failure remain represented as state data for the
widget layer to display. No navigation, dialogs, or snackbars will be added to
the BLoC or domain service.

## Architecture

The existing feature layout remains the source of truth:

```text
lib/features/subscriptions/
  domain/
    entities/
    repositories/
    usecases/
  data/
    datasources/
    repositories/
  presentation/
    bloc/
    pages/
    widgets/
```

Domain entities remain immutable and platform-independent. Store and storage
implementations remain behind datasource contracts. `SubscriptionRepository`
continues to be the injectable boundary used by `SubscriptionService`, and
`SubscriptionModule` remains the composition root for default production
implementations and test fakes.

The presentation additions must not import `in_app_purchase` directly. The
page consumes `StoreProduct` and `SubscriptionSnapshot` only.

## Behavior contract

The README and tests will state these rules explicitly:

- Consumables emit a one-shot result and do not persist entitlement access.
- Lifetime and non-consumable products create permanent entitlements.
- Non-renewing products require a positive configured duration.
- Local auto-renewing products may be active with `isExpiryKnown == false`.
- Local mode does not invent expired, paused, grace-period, canceled, or
  refunded states.
- Server-verified mode requires an injected `PurchaseVerifier`.
- Confirmed invalid verification revokes an existing entitlement; unavailable
  or transient verification does not silently revoke cached access.
- Duplicate purchase IDs are ignored after the first successful processing.
- A pending store purchase is completed exactly once when the adapter marks it
  as requiring completion.
- Restore results distinguish restored, none, and failure.
- `SubscriptionScope` owns and disposes the BLoC/service it creates.

## README structure

`README.md` will be rewritten with a Pub.dev-oriented structure:

1. Package summary and supported platforms.
2. What the package handles versus what the host app must configure.
3. Installation.
4. Five-minute built-in UI example with product definitions and plan perks.
5. Built-in UI customization: strings, theme, badges, descriptions, and
   manage-subscription callback.
6. Custom UI example using `SubscriptionScope`, `SubscriptionBuilder`, state,
   purchase, restore, and refresh actions.
7. Product-type behavior table.
8. Local versus server-verified mode, including a verifier example and honest
   limitations.
9. Android, iOS, and macOS store setup.
10. Testing guidance with fake store/storage/verifier examples.
11. Troubleshooting for unavailable stores, missing products, pending
    purchases, restore behavior, and unknown local expiry.
12. API/lifecycle notes, changelog, license, and support guidance. Repository
    and issue links will be included only when the package has verified URLs.

Examples will use the public barrel import and must compile against the actual
public API. README examples will not depend on private implementation classes.

## Test strategy

All new behavioral tests follow red-green-refactor. Tests must be deterministic
and use injected fakes rather than real store plugins.

### Domain and configuration tests

- Consumables may omit entitlement IDs.
- Durable products require entitlement IDs.
- Duplicate product IDs are rejected.
- Non-renewing products require a positive duration.
- Auto-renewing products reject local durations.
- Empty configuration and invalid storage/timing values are rejected.
- Local auto-renewing entitlements preserve unknown expiry explicitly.
- Lifetime status is based on product type, not merely a null expiry.

### Service tests

- Initialization loads storage, initializes the store, exposes products, and
  can be safely called twice.
- Successful lifetime and auto-renewing purchases grant the correct
  entitlement.
- Consumable purchases emit success without persisting access.
- Pending, canceled, and error purchases emit the correct result.
- Duplicate purchase IDs do not grant or emit twice.
- Purchase completion is called exactly once when required and never called
  when not required.
- Restore handles restored purchases, no purchases, and failures.
- Restore suppresses per-purchase noise while still returning a final result.
- Server verification handles valid, confirmed invalid, unavailable, and
  thrown/transient verifier outcomes.
- Existing access is not revoked for unavailable/transient verification.
- Known expiry changes active access to expired.
- Unknown local expiry is not expired by the local timer.
- Dispose cancels streams/timers and is idempotent.

### BLoC and scope tests

- Initialization transitions to ready or failure.
- Public convenience methods dispatch purchase, restore, and refresh work.
- Snapshot properties remain complete and equatable.
- Purchase and restore flags return to false after completion/failure.
- Entitlement and purchase-result streams update the snapshot.
- `SubscriptionScope` initializes exactly once and disposes its owned service.
- A scope does not dispose an injected repository before the BLoC owns it
  according to the documented ownership contract.

### Built-in UI tests

- Store products render when no plan-content overrides are provided.
- Custom title, description, badge, CTA, and perk text render for matching
  product IDs.
- Products without content still fall back to store metadata.
- Purchase buttons are disabled while purchasing.
- Restore button reflects restoring state.
- Loading, unavailable, failure, empty-product, active-entitlement, and
  result-message states render safely.
- Theme and string overrides are honored.

### Adapter and packaging verification

- Store adapter maps consumable, non-consumable, pending, restored, canceled,
  and error purchase details into neutral `StorePurchase` values.
- Storage adapter round-trips entitlements and processed purchase IDs.
- `dart analyze .` passes.
- `dart format --output=none --set-exit-if-changed .` passes.
- `flutter test --no-pub --concurrency=1` passes, or any environment blocker
  is reported with the exact command and output.
- `flutter pub publish --dry-run` passes before publication work is considered
  complete.
- Android, iOS, and macOS sandbox/manual verification remains a separate
  release checklist and is not represented as passing unit-test coverage.

## Acceptance criteria

- Both consumer modes are represented by public, documented examples.
- Built-in UI accepts user-owned product copy and perks without coupling that
  content to domain entities.
- Custom UI can purchase, restore, and refresh without constructing internal
  BLoC events.
- All listed core scenarios have automated tests or are explicitly marked as
  manual platform tests.
- README examples match the exported API and contain no incomplete setup that
  would mislead a package consumer.
- Static analysis, formatting, test, and publish dry-run results are reported
  from fresh command output.
