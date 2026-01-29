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
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        context.read<MainCubit>().changeWalletType();
      },
      shape: CircleBorder(
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      elevation: 2,
      backgroundColor: Theme.of(context).cardColor,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInBack,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: !isCashuWallet
            ? ExtendedImage.asset(
                key: const ValueKey('cashu'),
                Images.cashu,
                width: 24,
                height: 24,
              )
            : SvgPicture.asset(
                key: const ValueKey('nwc'),
                FeatureIcons.nwc,
                width: 24,
                height: 24,
              ),
      ),
    );
  }
}
