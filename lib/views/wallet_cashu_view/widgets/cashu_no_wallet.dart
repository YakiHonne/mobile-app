import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/utils.dart';
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
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      ),
      child: TextButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (_) {
              return const CreateCashuWallet();
            },
            isScrollControlled: true,
            useRootNavigator: true,
            useSafeArea: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              colorFilter: const ColorFilter.mode(
                kWhite,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Text(
              context.t.addWallet.capitalizeFirst(),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: kWhite,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
