import 'package:flutter/material.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

void main() {
  runApp(
    SubscriptionScope(
      config: SubscriptionConfig(
        products: const [
          ProductDefinition(
            id: 'pro_lifetime',
            type: ProductType.lifetime,
            entitlementId: 'pro',
            priority: 10,
          ),
          ProductDefinition(
            id: 'pro_monthly',
            type: ProductType.autoRenewing,
            entitlementId: 'pro',
            priority: 8,
          ),
        ],
        defaultEntitlementId: 'pro',
        verificationMode: VerificationMode.local,
      ),
      child: MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const SubscriptionPage(),
      ),
    ),
  );
}
