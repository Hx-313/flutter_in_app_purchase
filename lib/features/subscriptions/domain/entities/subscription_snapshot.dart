import 'package:equatable/equatable.dart';

import 'consumable_delivery.dart';
import 'entitlement.dart';
import 'purchase_result.dart';
import 'store_product.dart';
import 'subscription_types.dart';

/// Immutable view of the subscription state currently held by the service.
final class SubscriptionSnapshot extends Equatable {
  SubscriptionSnapshot({
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
    this.isStoreAvailable = false,
  }) : products = List.unmodifiable(products),
       entitlements = Map.unmodifiable(entitlements),
       pendingConsumables = List.unmodifiable(pendingConsumables);

  static const _unset = Object();

  final SubscriptionPhase phase;
  final List<StoreProduct> products;
  final Map<String, Entitlement> entitlements;
  final List<ConsumableDelivery> pendingConsumables;
  final String? defaultEntitlementId;
  final bool isPurchasing;
  final bool isRestoring;
  final PurchaseResult? lastResult;
  final RestoreStatus? lastRestoreStatus;
  final String? errorMessage;
  final bool isStoreAvailable;

  bool get isReady => phase == SubscriptionPhase.ready;
  bool get hasError => phase == SubscriptionPhase.failure;
  bool hasAccess(String entitlementId) =>
      entitlements[entitlementId]?.hasAccess ?? false;

  /// Copies this snapshot, allowing nullable result fields to be cleared.
  SubscriptionSnapshot copyWith({
    SubscriptionPhase? phase,
    List<StoreProduct>? products,
    Map<String, Entitlement>? entitlements,
    List<ConsumableDelivery>? pendingConsumables,
    String? defaultEntitlementId,
    bool? isPurchasing,
    bool? isRestoring,
    Object? lastResult = _unset,
    Object? lastRestoreStatus = _unset,
    Object? errorMessage = _unset,
    bool? isStoreAvailable,
  }) => SubscriptionSnapshot(
    phase: phase ?? this.phase,
    products: products ?? this.products,
    entitlements: entitlements ?? this.entitlements,
    pendingConsumables: pendingConsumables ?? this.pendingConsumables,
    defaultEntitlementId: defaultEntitlementId ?? this.defaultEntitlementId,
    isPurchasing: isPurchasing ?? this.isPurchasing,
    isRestoring: isRestoring ?? this.isRestoring,
    lastResult: identical(lastResult, _unset)
        ? this.lastResult
        : lastResult as PurchaseResult?,
    lastRestoreStatus: identical(lastRestoreStatus, _unset)
        ? this.lastRestoreStatus
        : lastRestoreStatus as RestoreStatus?,
    errorMessage: identical(errorMessage, _unset)
        ? this.errorMessage
        : errorMessage as String?,
    isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
  );

  @override
  List<Object?> get props => [
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
    isStoreAvailable,
  ];
}
