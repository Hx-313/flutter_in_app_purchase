import 'package:equatable/equatable.dart';

import 'entitlement.dart';
import 'subscription_types.dart';

/// Result emitted for a purchase or restore operation.
final class PurchaseResult extends Equatable {
  PurchaseResult({
    required this.status,
    this.productId,
    this.entitlement,
    this.storePurchaseId,
    this.message,
    this.errorCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final PurchaseStatus status;
  final String? productId;
  final Entitlement? entitlement;
  final String? storePurchaseId;
  final String? message;
  final String? errorCode;
  final DateTime timestamp;

  bool get isSuccess => status.isSuccess;
  bool get isPending => status.isPending;
  bool get isError => status.isError;

  @override
  List<Object?> get props => [
    status,
    productId,
    entitlement,
    storePurchaseId,
    message,
    errorCode,
    timestamp,
  ];

  @override
  String toString() => 'PurchaseResult($status, productId: $productId)';
}
