import 'package:flutter/material.dart';

import '../../../common/widgets/ai_upsell_sheet.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/fluid_sheet.dart' show showAppModalSheet;
import 'pricing_screen.dart';

/// True when the account carries a plan. [excludeTrial] narrows that to a
/// paying subscriber, for the features a trial is not entitled to.
bool isSubscribed({bool excludeTrial = false}) {
  if (!subscriptionCubit.isPaid) {
    return false;
  }

  return !excludeTrial ||
      !(subscriptionCubit.state.subscriptionStatus?.isTrialing ?? false);
}

/// Gate for subscriber-only actions: true when the caller may proceed,
/// otherwise the user is sent to upgrade and the caller stops.
///
/// ```dart
/// if (!requireSubscription(context)) return;
/// ```
///
/// Passing [upsellTitle] and [upsellFeatures] opens the AI upsell sheet
/// instead of dropping the user straight onto pricing.
bool requireSubscription(
  BuildContext context, {
  bool excludeTrial = false,
  String? upsellTitle,
  List<String>? upsellFeatures,
}) {
  if (isSubscribed(excludeTrial: excludeTrial)) {
    return true;
  }

  if (upsellTitle != null && upsellFeatures != null) {
    showAppModalSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AiUpsellSheet(
        parentContext: context,
        title: upsellTitle,
        features: upsellFeatures,
      ),
    );
  } else {
    YNavigator.pushPage(context, (_) => const PricingScreen());
  }

  return false;
}
