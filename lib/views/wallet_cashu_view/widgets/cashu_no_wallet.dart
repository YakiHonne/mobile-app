import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/main_cubit/main_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/wallet_type_switch.dart';
import 'create_cashu_wallet.dart';

class CashuNoWallet extends HookWidget {
  const CashuNoWallet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExtendedImage.asset(
          Images.cashu,
          width: 30.w,
          height: 30.w,
          fit: BoxFit.contain,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Text(
          context.t.addCashuWallet.capitalizeFirst(),
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
              isCashu: true,
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
            Colors.orangeAccent,
            Colors.pinkAccent,
          ],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: TextButton(
        onPressed: () {
          showAppModalSheet(
            context: context,
            builder: (_) {
              return const CreateCashuWallet();
            },
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        },
        style: TextButton.styleFrom(
          backgroundBuilder: (_, __, child) => child!,
          backgroundColor: kTransparent,
          visualDensity: VisualDensity.compact,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(
              FeatureIcons.addRaw,
              size: 15,
              color: kWhite,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Text(
              context.t.addWallet.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: kWhite,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
