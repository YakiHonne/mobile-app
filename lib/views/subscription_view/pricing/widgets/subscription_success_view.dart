import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';

class SubscriptionSuccessView extends StatelessWidget {
  const SubscriptionSuccessView({
    super.key,
    required this.planName,
    required this.price,
  });

  final String planName;
  final String price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.t.pricing_payment_confirmed,
          style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
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
                      spacing: kDefaultPadding / 4,
                      children: [
                        Text(
                          planName,
                          style: theme.textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          price,
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
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + kDefaultPadding / 2,
              ),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => YNavigator.popToRoot(context),
                  style: TextButton.styleFrom(
                    backgroundBuilder: (_, __, child) => child!,
                    backgroundColor: theme.cardColor,
                    side: BorderSide(color: theme.dividerColor, width: 0.5),
                  ),
                  child: Text(
                    context.t.close.capitalizeFirst(),
                    style: theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
