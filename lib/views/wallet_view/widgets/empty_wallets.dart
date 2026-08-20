import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/main_cubit/main_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/modal_with_blur.dart';
import '../../widgets/wallet_type_switch.dart';
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
        if (isFluid()) ...[
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: WalletTypeSwitch(
              isCashu: false,
              onTap: () {
                context.read<MainCubit>().changeWalletType();
              },
            ),
          ),
        ],
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
          backgroundBuilder: (_, __, child) => child!,
          backgroundColor: kTransparent,
          visualDensity: VisualDensity.comfortable,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(
              FeatureIcons.addRaw,
              size: 15,
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
          child: AppIcon(
            FeatureIcons.walletAdd,
            color: Theme.of(context).primaryColorDark,
            size: 55,
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
                width: 35,
                height: 35,
              ),
            ),
          ),
      ],
    );
  }
}
