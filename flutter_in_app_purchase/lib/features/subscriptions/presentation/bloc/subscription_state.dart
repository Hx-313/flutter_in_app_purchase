import 'package:equatable/equatable.dart';

import '../../domain/entities/entitlement.dart';
import '../../domain/entities/purchase_result.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/entities/subscription_types.dart';

/// Immutable presentation state for the subscription feature.
final class SubscriptionSnapshot extends Equatable {
  const SubscriptionSnapshot({
    this.phase = SubscriptionPhase.idle,
    this.products = const <StoreProduct>[],
    this.entitlements = const <String, Entitlement>{},
    this.defaultEntitlementId,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.lastResult,
    this.lastRestoreStatus,
    this.errorMessage,
    this.isStoreAvailable = false,
  });

  static const _unset = Object();

  final SubscriptionPhase phase;
  final List<StoreProduct> products;
  final Map<String, Entitlement> entitlements;
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

  SubscriptionSnapshot copyWith({
    SubscriptionPhase? phase,
    List<StoreProduct>? products,
    Map<String, Entitlement>? entitlements,
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
    defaultEntitlementId:
        defaultEntitlementId ?? this.defaultEntitlementId,
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
    defaultEntitlementId,
    isPurchasing,
    isRestoring,
    lastResult,
    lastRestoreStatus,
    errorMessage,
    isStoreAvailable,
  ];
}
