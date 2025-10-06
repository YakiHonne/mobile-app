import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/utils.dart';
import '../../widgets/modal_with_blur.dart';
import 'wallet_options_view.dart';

class DisconnectedWallet extends HookWidget {
  const DisconnectedWallet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const WalletImage(),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Text(
          context.t.toBeAbleSendSats.capitalizeFirst(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        _emptyWalletAdd(context),
      ],
    );
  }

  Container _emptyWalletAdd(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.orange,
            Colors.yellow,
          ],
        ),
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      ),
      child: TextButton(
        onPressed: () {
          showBlurredModal(
            context: context,
            view: const WalletOptions(),
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: kTransparent,
          visualDensity: VisualDensity.comfortable,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              FeatureIcons.addRaw,
              width: 15,
              height: 15,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Text(
              context.t.addWallet.capitalizeFirst(),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: kBlack,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletImage extends StatelessWidget {
  const WalletImage({
    super.key,
    this.removeExtra,
  });
  final bool? removeExtra;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const SizedBox(
          width: 140,
          height: 140,
        ),
        Container(
          width: 130,
          height: 130,
          margin: const EdgeInsets.all(kDefaultPadding / 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).cardColor,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            FeatureIcons.walletAdd,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
            width: 55,
            height: 55,
          ),
        ),
        if (removeExtra == null)
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                FeatureIcons.alby,
                width: 35,
                height: 35,
              ),
            ),
          ),
        if (removeExtra == null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                FeatureIcons.nwc,
                fit: BoxFit.scaleDown,
                width: 35,
                height: 35,
              ),
            ),
          ),
      ],
    );
  }
}
