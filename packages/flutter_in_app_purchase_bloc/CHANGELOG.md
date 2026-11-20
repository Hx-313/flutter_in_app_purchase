## 0.2.0

* Expanded `flutter_bloc` support to `>=8.1.6 <10.0.0` (validated against `bloc: ^9.2.1` and `flutter_bloc: ^9.1.1`).
* Decoupled test harnesses from `package:flutter/material.dart` to pure `package:flutter/widgets.dart` with `Directionality`.
* Aligned versioning with `smart_inapp_purchase: 0.2.0`.

## 0.1.0

* Initial release of `smart_inapp_purchase_bloc` companion adapter.
* Provides `SubscriptionBloc`, `SubscriptionEvent`, and `SubscriptionScope` bridging `smart_inapp_purchase` state into Flutter BLoC applications.
* Upgraded to `equatable: ^3.0.0` and `flutter_bloc: ^8.1.6`.
