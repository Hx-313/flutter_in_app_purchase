import 'package:equatable/equatable.dart';

/// A durable, pending handoff of a consumable purchase to the host app.
///
/// The host should fulfill the purchase idempotently using [purchaseId], then
/// acknowledge it through [SubscriptionService.acknowledgeConsumablePurchase].
final class ConsumableDelivery extends Equatable {
  const ConsumableDelivery({
    required this.purchaseId,
    required this.productId,
    required this.purchasedAt,
  });

  /// Stable transaction identifier provided by the store.
  final String purchaseId;

  /// Configured store product identifier.
  final String productId;

  /// Store transaction date, or the processing time when the store omitted it.
  final DateTime purchasedAt;

  @override
  List<Object?> get props => [purchaseId, productId, purchasedAt];
}
