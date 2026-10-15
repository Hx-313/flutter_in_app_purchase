import 'package:equatable/equatable.dart';

import 'product_definition.dart';

/// Store-neutral product information.
final class StoreProduct extends Equatable {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    this.definition,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final String currencyCode;
  final ProductDefinition? definition;

  StoreProduct withDefinition(ProductDefinition definition) => StoreProduct(
    id: id,
    title: title,
    description: description,
    price: price,
    rawPrice: rawPrice,
    currencyCode: currencyCode,
    definition: definition,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    price,
    rawPrice,
    currencyCode,
    definition,
  ];
}
