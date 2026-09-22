import 'package:flutter/material.dart';

import '../widgets/subscription_body.dart';
import '../widgets/subscription_strings.dart';
import '../widgets/subscription_theme.dart';

/// Opinionated, theme-aware subscription lifecycle screen.
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({
    super.key,
    this.strings = const SubscriptionStrings(),
    this.theme = const SubscriptionTheme(),
    this.onManageSubscription,
  });

  final SubscriptionStrings strings;
  final SubscriptionTheme theme;
  final VoidCallback? onManageSubscription;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SubscriptionBody(
        strings: strings,
        theme: theme,
        onManageSubscription: onManageSubscription,
      ),
    ),
  );
}
