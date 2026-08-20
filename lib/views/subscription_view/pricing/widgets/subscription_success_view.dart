import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/fluid_scaffold.dart';
import '../../onboarding/identity_onboarding_view.dart';

class SubscriptionSuccessView extends StatefulWidget {
  const SubscriptionSuccessView({
    super.key,
    required this.planName,
    required this.price,
  });

  final String planName;
  final String price;

  @override
  State<SubscriptionSuccessView> createState() =>
      _SubscriptionSuccessViewState();
}

class _SubscriptionSuccessViewState extends State<SubscriptionSuccessView> {
  Timer? _advance;

  @override
  void initState() {
    super.initState();
    // The purchase is done and the only thing left is identity setup, so this
    // screen confirms and hands off on its own. Skipping lives on the
    // onboarding screen's own "Maybe later", the single place that flags the
    // account onboarded for a user who declines.
    _advance = Timer(const Duration(seconds: 2), _toOnboarding);
  }

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  void _toOnboarding() {
    // The Continue button and the dwell timer share this path. The route is
    // not disposed until the push transition ends, so without the cancel a tap
    // late in the dwell lets the timer push a second onboarding view on top.
    _advance?.cancel();
    if (!mounted) {
      return;
    }
    // Already been through identity setup (upgrade, renewal after churn) — the
    // form has nothing left to ask for. Status is refreshed before this screen
    // is pushed, so the flag is current.
    if (subscriptionCubit.state.subscriptionStatus?.onboarded ?? false) {
      YNavigator.popToRoot(context);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => IdentityOnboardingView(
          onDone: () => YNavigator.popToRoot(context),
          onSkip: () => YNavigator.popToRoot(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FluidScaffold(
      title: context.t.pricing_payment_confirmed,
      // Terminal screen — no way back, and no logo shortcut out of it.
      leading: const SizedBox.shrink(),
      actions: const [],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2)
            .copyWith(top: fluidScaffoldTopInset(context)),
        child: Column(
          children: [
            Expanded(
              child: FadeIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: kDefaultPadding,
                  children: [
                    Lottie.asset(
                      LottieAnimations.success,
                      height: 13.h,
                      fit: BoxFit.contain,
                      frameRate: const FrameRate(60),
                      repeat: false,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: kDefaultPadding / 4,
                      children: [
                        Text(
                          widget.planName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.price,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium!.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          context.t.pricing_footer,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
