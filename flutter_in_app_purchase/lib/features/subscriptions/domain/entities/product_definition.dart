import 'package:equatable/equatable.dart';

import 'subscription_types.dart';

/// Consumer-provided definition for one store product.
final class ProductDefinition extends Equatable {
  const ProductDefinition({
    required this.id,
    required this.type,
    this.entitlementId,
    this.duration,
    this.displayName,
    this.priority = 0,
    this.tags = const <String>{},
  });

  final String id;
  final ProductType type;
  final String? entitlementId;
  final Duration? duration;
  final String? displayName;
  final int priority;
  final Set<String> tags;

  bool get grantsEntitlement => type != ProductType.consumable;
  bool get isPermanent =>
      type == ProductType.lifetime || type == ProductType.nonConsumable;
  bool get isSubscription =>
      type == ProductType.nonRenewing || type == ProductType.autoRenewing;
  bool get isConsumable => type == ProductType.consumable;

  @override
  List<Object?> get props => [
    id,
    type,
    entitlementId,
    duration,
    displayName,
    priority,
    tags,
  ];

  @override
  String toString() => 'ProductDefinition($id, $type)';
}
