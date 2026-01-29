import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import 'cashu_deposit_view.dart';
import 'cashu_redeem_view.dart';

class CashuReceiveView extends HookWidget {
  const CashuReceiveView({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(kDefaultPadding),
              topRight: Radius.circular(kDefaultPadding),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalBottomSheetAppbar(
                title: context.t.receive,
                isBack: false,
              ),
              Padding(
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: Column(
                  children: [
                    _buildOptionCard(
                      context,
                      title: context.t.redeemEcash,
                      description: context.t.redeemEcashDesc,
                      icon: FeatureIcons.redeemEcash,
                      onTap: () {
                        Navigator.pop(context);
                        YNavigator.presentPage(
                          context,
                          (context) => const CashuRedeemView(),
                        );
                      },
                    ),
                    const SizedBox(height: kDefaultPadding / 2),
                    _buildOptionCard(
                      context,
                      title: context.t.deposit,
                      description: context.t.depositDesc,
                      icon: FeatureIcons.depositSats,
                      onTap: () {
                        Navigator.pop(context);
                        YNavigator.presentPage(
                          context,
                          (context) => const CashuDepositView(),
                        );
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
              child: SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).highlightColor,
            ),
          ],
        ),
      ),
    );
  }
}
