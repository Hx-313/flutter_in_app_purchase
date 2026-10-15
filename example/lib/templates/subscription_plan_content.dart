/// Optional presentation copy for one configured subscription product.
final class SubscriptionPlanContent {
  SubscriptionPlanContent({
    required this.productId,
    this.title,
    this.description,
    List<String> perks = const [],
    this.badge,
    this.purchaseLabel,
  }) : perks = List.unmodifiable(perks) {
    if (productId.trim().isEmpty) {
      throw ArgumentError.value(productId, 'productId', 'Must not be empty');
    }
  }

  final String productId;
  final String? title;
  final String? description;
  final List<String> perks;
  final String? badge;
  final String? purchaseLabel;
}
