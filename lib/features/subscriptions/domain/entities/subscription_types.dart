/// Product categories supported by the package.
enum ProductType {
  consumable,
  nonConsumable,
  lifetime,
  nonRenewing,
  autoRenewing,
}

/// Durable access state returned by the package.
enum SubscriptionState {
  none,
  active,
  expired,
  gracePeriod,
  paused,
  canceled,
  refunded,
}

/// Result of a purchase operation or purchase-stream event.
enum PurchaseStatus {
  success,
  pending,
  canceled,
  error,
  alreadyOwned,
  notAvailable,
  networkError,
  verificationFailed,
  restored,
}

/// Lifecycle phase exposed by the consumer presentation layer.
enum SubscriptionPhase {
  idle,
  initializing,
  ready,
  unavailable,
  failure,
  disposed,
}

/// Controls whether renewable access is evaluated locally or by a verifier.
enum VerificationMode { local, serverVerified }

/// Outcome of a restore request.
enum RestoreStatus { restored, none, failure }

extension SubscriptionStateX on SubscriptionState {
  bool get hasAccess => switch (this) {
    SubscriptionState.active ||
    SubscriptionState.gracePeriod ||
    SubscriptionState.canceled => true,
    _ => false,
  };

  bool get hasDetailedLifecycle => switch (this) {
    SubscriptionState.gracePeriod ||
    SubscriptionState.paused ||
    SubscriptionState.canceled ||
    SubscriptionState.refunded ||
    SubscriptionState.expired => true,
    _ => false,
  };
}

extension PurchaseStatusX on PurchaseStatus {
  bool get isSuccess => this == PurchaseStatus.success;
  bool get isPending => this == PurchaseStatus.pending;
  bool get isError => switch (this) {
    PurchaseStatus.error ||
    PurchaseStatus.networkError ||
    PurchaseStatus.verificationFailed => true,
    _ => false,
  };
}
