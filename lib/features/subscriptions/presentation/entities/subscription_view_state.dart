import 'package:equatable/equatable.dart';

import '../../domain/entities/consumable_delivery.dart';
import '../../domain/entities/entitlement.dart';
import '../../domain/entities/purchase_result.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/entities/subscription_types.dart';
import '../../domain/usecases/subscription_service.dart' show RestoreResult;

/// Commands exposed to host UI by [SubscriptionViewState].
///
/// Implementations guard against double firing, so a host can call these
/// directly from a button without tracking operation state itself.
abstract interface class SubscriptionActions {
  /// Starts a purchase and resolves with the store outcome for that product.
  Future<PurchaseResult> purchase(String productId);

  /// Restores previous purchases and resolves with the restore outcome.
  Future<RestoreResult> restore();

  /// Manually acknowledges a staged consumable delivery.
  ///
  /// The provider acknowledges automatically when
  /// `SubscriptionCallbacks.onConsumablePurchased` returns `true`; this is the
  /// advanced escape hatch for hosts that manage fulfillment themselves.
  Future<void> acknowledgeConsumable(String purchaseId);
}

/// Immutable view of the subscription state handed to host UI.
///
/// This is the only state a host needs to read, and it never requires
/// subscribing to stores, streams, or listeners directly.
final class SubscriptionViewState extends Equatable {
  SubscriptionViewState({
    required this.actions,
    this.phase = SubscriptionPhase.idle,
    Iterable<StoreProduct> products = const <StoreProduct>[],
    Map<String, Entitlement> entitlements = const <String, Entitlement>{},
    Iterable<ConsumableDelivery> pendingConsumables =
        const <ConsumableDelivery>[],
    this.defaultEntitlementId,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.lastResult,
    this.lastRestoreStatus,
    this.errorMessage,
    this.statusMessage,
    this.isStoreAvailable = false,
  }) : products = List.unmodifiable(products),
       entitlements = Map.unmodifiable(entitlements),
       pendingConsumables = List.unmodifiable(pendingConsumables);

  /// Guarded commands for this state.
  final SubscriptionActions actions;

  /// Current lifecycle phase.
  final SubscriptionPhase phase;

  /// Store products with their configured definitions attached.
  final List<StoreProduct> products;

  /// Durable entitlements keyed by entitlement id.
  final Map<String, Entitlement> entitlements;

  /// Consumable purchases waiting for host fulfillment.
  final List<ConsumableDelivery> pendingConsumables;

  /// Entitlement id exposed by [entitlement] and used by `PremiumGate`.
  final String? defaultEntitlementId;

  /// A purchase request is in flight.
  final bool isPurchasing;

  /// A restore request is in flight.
  final bool isRestoring;

  /// Last purchase or restore result reported by the package.
  final PurchaseResult? lastResult;

  /// Last restore status, when the last operation was a restore.
  final RestoreStatus? lastRestoreStatus;

  /// Raw error text reported by the store or verifier.
  ///
  /// This value can come from the platform store and may not be localizable;
  /// use [statusMessage] for host-facing text.
  final String? errorMessage;

  /// Host-facing, localizable message for [lastResult].
  ///
  /// The provider uses `SubscriptionProvider.messageBuilder` when supplied and
  /// falls back to a neutral English message otherwise.
  final String? statusMessage;

  /// Whether the platform store is available on this device.
  final bool isStoreAvailable;

  /// Configured entitlement, when [defaultEntitlementId] resolves to one.
  Entitlement? get entitlement =>
      defaultEntitlementId == null ? null : entitlements[defaultEntitlementId];

  /// Whether the default entitlement currently grants access.
  bool get hasAccess => entitlement?.hasAccess ?? false;

  /// Whether [entitlementId] currently grants access.
  bool hasAccessTo(String entitlementId) =>
      entitlements[entitlementId]?.hasAccess ?? false;

  /// The service finished initializing successfully.
  bool get isReady => phase == SubscriptionPhase.ready;

  /// Initialization has not finished yet.
  bool get isLoading =>
      phase == SubscriptionPhase.idle ||
      phase == SubscriptionPhase.initializing;

  /// Initialization failed.
  bool get hasError => phase == SubscriptionPhase.failure;

  /// The platform store is unavailable on this device.
  bool get isStoreUnavailable => phase == SubscriptionPhase.unavailable;

  /// A purchase or restore is in flight.
  bool get isBusy => isPurchasing || isRestoring;

  /// Finds a loaded product by id, with its configured definition attached.
  StoreProduct? product(String productId) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  /// Starts a purchase. Delegates to [actions] and is safe to call repeatedly.
  Future<PurchaseResult> purchase(String productId) =>
      actions.purchase(productId);

  /// Restores purchases. Delegates to [actions] and is safe to call repeatedly.
  Future<RestoreResult> restore() => actions.restore();

  /// Manually acknowledges a staged consumable delivery.
  Future<void> acknowledgeConsumable(String purchaseId) =>
      actions.acknowledgeConsumable(purchaseId);

  @override
  List<Object?> get props => [
    actions,
    phase,
    products,
    entitlements,
    pendingConsumables,
    defaultEntitlementId,
    isPurchasing,
    isRestoring,
    lastResult,
    lastRestoreStatus,
    errorMessage,
    statusMessage,
    isStoreAvailable,
  ];
}
