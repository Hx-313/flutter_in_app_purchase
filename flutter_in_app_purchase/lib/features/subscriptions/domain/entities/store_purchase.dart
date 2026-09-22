import 'package:equatable/equatable.dart';

/// Purchase state exposed by a store adapter.
enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

/// Store payloads forwarded to a verifier without exposing SDK classes.
final class PurchaseVerificationData extends Equatable {
  const PurchaseVerificationData({
    this.source,
    this.serverData,
    this.localData,
  });

  final String? source;
  final String? serverData;
  final String? localData;

  @override
  List<Object?> get props => [source, serverData, localData];
}

/// Store-neutral purchase event.
final class StorePurchase extends Equatable {
  const StorePurchase({
    required this.productId,
    required this.status,
    this.purchaseId,
    this.transactionDate,
    this.verificationData,
    this.pendingCompletePurchase = false,
    this.errorCode,
    this.errorMessage,
  });

  final String productId;
  final StorePurchaseStatus status;
  final String? purchaseId;
  final DateTime? transactionDate;
  final PurchaseVerificationData? verificationData;
  final bool pendingCompletePurchase;
  final String? errorCode;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    productId,
    status,
    purchaseId,
    transactionDate,
    verificationData,
    pendingCompletePurchase,
    errorCode,
    errorMessage,
  ];
}
