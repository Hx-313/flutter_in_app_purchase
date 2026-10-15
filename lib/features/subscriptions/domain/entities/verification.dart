import 'package:equatable/equatable.dart';

import 'product_definition.dart';
import 'store_purchase.dart';
import 'subscription_types.dart';

/// Input supplied to an injected purchase verifier.
final class PurchaseVerificationRequest extends Equatable {
  const PurchaseVerificationRequest({
    required this.product,
    required this.purchase,
  });

  final ProductDefinition product;
  final StorePurchase purchase;

  @override
  List<Object?> get props => [product, purchase];
}

/// Verifier outcome for a durable purchase.
enum VerificationStatus { valid, invalid, unavailable }

/// Normalized verifier response.
final class VerificationResult extends Equatable {
  const VerificationResult({
    required this.status,
    this.state = SubscriptionState.active,
    this.expiresAt,
    this.isExpiryKnown = true,
    this.willRenew = false,
    this.message,
  });

  const VerificationResult.valid({
    this.state = SubscriptionState.active,
    this.expiresAt,
    this.isExpiryKnown = true,
    this.willRenew = false,
    this.message,
  }) : status = VerificationStatus.valid;

  const VerificationResult.invalid({this.message})
    : status = VerificationStatus.invalid,
      state = SubscriptionState.refunded,
      expiresAt = null,
      isExpiryKnown = true,
      willRenew = false;

  const VerificationResult.unavailable({this.message})
    : status = VerificationStatus.unavailable,
      state = SubscriptionState.active,
      expiresAt = null,
      isExpiryKnown = false,
      willRenew = false;

  final VerificationStatus status;
  final SubscriptionState state;
  final DateTime? expiresAt;
  final bool isExpiryKnown;
  final bool willRenew;
  final String? message;

  @override
  List<Object?> get props => [
    status,
    state,
    expiresAt,
    isExpiryKnown,
    willRenew,
    message,
  ];
}

/// Optional secure verification extension point.
abstract interface class PurchaseVerifier {
  Future<VerificationResult> verify(PurchaseVerificationRequest request);
}
