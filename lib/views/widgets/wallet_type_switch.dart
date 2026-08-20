import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/utils.dart';

class WalletTypeSwitch extends StatelessWidget {
  const WalletTypeSwitch({
    super.key,
    required this.isCashu,
    required this.onTap,
  });

  final bool isCashu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: kDefaultPadding / 2,
          children: isCashu
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
    );
  }
}
