import 'package:equatable/equatable.dart';

import 'subscription_types.dart';

/// Persisted access rights granted by a durable product.
final class Entitlement extends Equatable {
  const Entitlement({
    required this.id,
    required this.productId,
    required this.productType,
    required this.isActive,
    required this.state,
    this.expiresAt,
    this.isExpiryKnown = true,
    this.willRenew = false,
    this.grantedAt,
    this.lastVerifiedAt,
  });

  final String id;
  final String productId;
  final ProductType productType;
  final bool isActive;
  final SubscriptionState state;
  final DateTime? expiresAt;
  final bool isExpiryKnown;
  final bool willRenew;
  final DateTime? grantedAt;
  final DateTime? lastVerifiedAt;

  factory Entitlement.active({
    required String id,
    required String productId,
    required ProductType productType,
    DateTime? expiresAt,
    bool isExpiryKnown = true,
    bool willRenew = false,
    DateTime? grantedAt,
    DateTime? lastVerifiedAt,
  }) => Entitlement(
    id: id,
    productId: productId,
    productType: productType,
    isActive: true,
    state: SubscriptionState.active,
    expiresAt: expiresAt,
    isExpiryKnown: isExpiryKnown,
    willRenew: willRenew,
    grantedAt: grantedAt ?? DateTime.now(),
    lastVerifiedAt: lastVerifiedAt,
  );

  factory Entitlement.inactive({
    required String id,
    required String productId,
    required ProductType productType,
    SubscriptionState state = SubscriptionState.none,
    DateTime? expiresAt,
    bool isExpiryKnown = true,
    DateTime? lastVerifiedAt,
  }) => Entitlement(
    id: id,
    productId: productId,
    productType: productType,
    isActive: false,
    state: state,
    expiresAt: expiresAt,
    isExpiryKnown: isExpiryKnown,
    lastVerifiedAt: lastVerifiedAt,
  );

  bool get hasAccess => isActive && state.hasAccess;
  bool get isLifetime => productType == ProductType.lifetime;
  bool get isPermanent =>
      productType == ProductType.lifetime ||
      productType == ProductType.nonConsumable;
  bool get isExpired =>
      isExpiryKnown && expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get hasDetailedLifecycle =>
      productType != ProductType.autoRenewing || isExpiryKnown;
  int? get daysUntilExpiry => expiresAt?.difference(DateTime.now()).inDays;

  Entitlement copyWith({
    bool? isActive,
    SubscriptionState? state,
    DateTime? expiresAt,
    bool? isExpiryKnown,
    bool? willRenew,
    DateTime? lastVerifiedAt,
  }) => Entitlement(
    id: id,
    productId: productId,
    productType: productType,
    isActive: isActive ?? this.isActive,
    state: state ?? this.state,
    expiresAt: expiresAt ?? this.expiresAt,
    isExpiryKnown: isExpiryKnown ?? this.isExpiryKnown,
    willRenew: willRenew ?? this.willRenew,
    grantedAt: grantedAt,
    lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'productId': productId,
    'productType': productType.name,
    'isActive': isActive,
    'state': state.name,
    'expiresAt': expiresAt?.toIso8601String(),
    'isExpiryKnown': isExpiryKnown,
    'willRenew': willRenew,
    'grantedAt': grantedAt?.toIso8601String(),
    'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
  };

  factory Entitlement.fromJson(Map<String, dynamic> json) => Entitlement(
    id: json['id'] as String,
    productId: json['productId'] as String,
    productType: ProductType.values.byName(json['productType'] as String),
    isActive: json['isActive'] as bool? ?? false,
    state: SubscriptionState.values.byName(json['state'] as String),
    expiresAt: _date(json['expiresAt']),
    isExpiryKnown: json['isExpiryKnown'] as bool? ?? true,
    willRenew: json['willRenew'] as bool? ?? false,
    grantedAt: _date(json['grantedAt']),
    lastVerifiedAt: _date(json['lastVerifiedAt']),
  );

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  @override
  List<Object?> get props => [
    id,
    productId,
    productType,
    isActive,
    state,
    expiresAt,
    isExpiryKnown,
    willRenew,
    grantedAt,
    lastVerifiedAt,
  ];
}
