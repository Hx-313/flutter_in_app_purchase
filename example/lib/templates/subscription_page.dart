import 'package:flutter/material.dart';

import 'subscription_body.dart';
import 'subscription_plan_content.dart';
import 'subscription_strings.dart';
import 'subscription_theme.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

/// Opinionated, theme-aware subscription lifecycle screen.
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({
    super.key,
    required this.service,
    this.strings = const SubscriptionStrings(),
    this.theme = const SubscriptionTheme(),
    this.onManageSubscription,
    this.planContent = const [],
  });

  final SubscriptionService service;
  final SubscriptionStrings strings;
  final SubscriptionTheme theme;
  final VoidCallback? onManageSubscription;
  final List<SubscriptionPlanContent> planContent;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SubscriptionBody(
        service: service,
        strings: strings,
        theme: theme,
        onManageSubscription: onManageSubscription,
        planContent: planContent,
      ),
    ),
  );
}
