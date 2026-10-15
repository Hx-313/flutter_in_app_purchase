import 'package:equatable/equatable.dart';

import 'product_definition.dart';
import 'subscription_types.dart';

/// Configuration for one subscription store integration.
final class SubscriptionConfig extends Equatable {
  SubscriptionConfig({
    required List<ProductDefinition> products,
    this.defaultEntitlementId,
    this.verificationMode = VerificationMode.local,
    this.storageKeyPrefix = 'flutter_in_app_purchase',
    this.expiryCheckInterval = const Duration(hours: 1),
  }) : products = List.unmodifiable(products) {
    _validate();
  }

  final List<ProductDefinition> products;
  final String? defaultEntitlementId;
  final VerificationMode verificationMode;
  final String storageKeyPrefix;
  final Duration expiryCheckInterval;

  Set<String> get productIds => products.map((product) => product.id).toSet();

  String? get effectiveDefaultEntitlementId =>
      defaultEntitlementId ??
      products
          .firstWhere(
            (product) => product.grantsEntitlement,
            orElse: () => products.first,
          )
          .entitlementId;

  ProductDefinition? getProduct(String productId) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  List<ProductDefinition> productsForEntitlement(String entitlementId) =>
      products
          .where((product) => product.entitlementId == entitlementId)
          .toList(growable: false);

  void _validate() {
    if (products.isEmpty) {
      throw ArgumentError.value(products, 'products', 'Must not be empty');
    }
    if (storageKeyPrefix.trim().isEmpty) {
      throw ArgumentError.value(
        storageKeyPrefix,
        'storageKeyPrefix',
        'Must not be empty',
      );
    }
    if (expiryCheckInterval <= Duration.zero) {
      throw ArgumentError.value(
        expiryCheckInterval,
        'expiryCheckInterval',
        'Must be positive',
      );
    }
    final ids = <String>{};
    for (final product in products) {
      if (product.id.trim().isEmpty) {
        throw ArgumentError.value(
          product.id,
          'product.id',
          'Must not be empty',
        );
      }
      if (!ids.add(product.id)) {
        throw ArgumentError('Duplicate product ID: ${product.id}');
      }

      if (!product.grantsEntitlement && product.entitlementId != null) {
        throw ArgumentError(
          'Consumable ${product.id} must not define an entitlementId',
        );
      }
      if (product.grantsEntitlement &&
          (product.entitlementId == null ||
              product.entitlementId!.trim().isEmpty)) {
        throw ArgumentError('Product ${product.id} requires an entitlementId');
      }
      if (product.type == ProductType.nonRenewing &&
          (product.duration == null || product.duration! <= Duration.zero)) {
        throw ArgumentError(
          'Non-renewing product ${product.id} requires a positive duration',
        );
      }
      if (product.type == ProductType.autoRenewing &&
          product.duration != null) {
        throw ArgumentError(
          'Auto-renewing product ${product.id} must not define a local duration',
        );
      }
      if (!product.isSubscription && product.duration != null) {
        throw ArgumentError('Product ${product.id} cannot define a duration');
      }
    }

    if (defaultEntitlementId != null &&
        !products.any(
          (product) => product.entitlementId == defaultEntitlementId,
        )) {
      throw ArgumentError(
        'defaultEntitlementId does not match a configured product',
      );
    }
  }

  @override
  List<Object?> get props => [
    products,
    defaultEntitlementId,
    verificationMode,
    storageKeyPrefix,
    expiryCheckInterval,
  ];
}
