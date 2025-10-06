import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';

class SendSuccessView extends StatelessWidget {
  const SendSuccessView({super.key, required this.amount, this.ln});

  final int amount;
  final String? ln;

  @override
  Widget build(BuildContext context) {
    final t = TextButton(
      onPressed: () async {
        YNavigator.popToRoot(context);
      },
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Text(
        context.t.close.capitalizeFirst(),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.t.paymentSucceeded,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: Column(
          children: [
            _successColumn(context),
            Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).padding.bottom + kDefaultPadding / 2,
              ),
              child: SizedBox(
                width: double.infinity,
                child: t,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _successColumn(BuildContext context) {
    return Expanded(
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
            Builder(
              builder: (context) {
                final amountInUsd =
                    walletManagerCubit.getBtcInUsdFromAmount(amount);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _amountRow(context),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    _exchangeRow(amountInUsd, context),
                  ],
                );
              },
            ),
            if (ln != null)
              Column(
                spacing: kDefaultPadding / 4,
                children: [
                  Text(
                    context.t.lightningAddress.capitalizeFirst(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                  Text(
                    ln!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  Row _exchangeRow(double amountInUsd, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '~ \$${amountInUsd == -1 ? 'N/A' : amountInUsd.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          ' USD',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }

  Row _amountRow(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${amount != -1 ? amount : 'N/A'}',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
              ),
        ),
        Text(
          'sats',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }
}
