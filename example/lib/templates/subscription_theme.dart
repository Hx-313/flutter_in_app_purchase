import 'package:flutter/material.dart';

/// Optional visual overrides layered over the host app's ThemeData.
final class SubscriptionTheme {
  const SubscriptionTheme({
    this.accentColor,
    this.cardColor,
    this.cardRadius = 20,
    this.contentPadding = const EdgeInsets.all(20),
  });

  final Color? accentColor;
  final Color? cardColor;
  final double cardRadius;
  final EdgeInsetsGeometry contentPadding;

  Color accent(BuildContext context) =>
      accentColor ?? Theme.of(context).colorScheme.primary;

  Color card(BuildContext context) =>
      cardColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
}
