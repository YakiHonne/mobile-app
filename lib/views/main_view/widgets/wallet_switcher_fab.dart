import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/main_cubit/main_cubit.dart';
import '../../../utils/utils.dart';

class WalletSwitcherFAB extends StatelessWidget {
  const WalletSwitcherFAB({
    super.key,
    required this.isCashuWallet,
  });

  final bool isCashuWallet;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.read<MainCubit>().changeWalletType();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 1.5,
          vertical: kDefaultPadding / 3,
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInBack,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Row(
            key: ValueKey(isCashuWallet),
            mainAxisSize: MainAxisSize.min,
            spacing: kDefaultPadding / 2,
            children: isCashuWallet
                ? [
                    SvgPicture.asset(
                      FeatureIcons.nwc,
                      width: 18,
                      height: 18,
                    ),
                    Text(
                      context.t.switchToNwc,
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ]
                : [
                    ExtendedImage.asset(
                      Images.cashu,
                      width: 18,
                      height: 18,
                    ),
                    Text(
                      context.t.switchToCashu,
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
