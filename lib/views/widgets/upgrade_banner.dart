import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../logic/subscription_cubit/subscription_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../subscription_view/pricing/pricing_screen.dart';
import 'app_icon.dart';

class UpgradeBanner extends HookWidget {
  const UpgradeBanner({super.key, this.dismissible = false});

  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final pubkey = currentSigner?.getPublicKey() ?? '';

    final refresh = useState(0);
    final dismissed = dismissible &&
        localDatabaseRepository.getUpgradeBannerDismissed(pubkey);

    if (!canSign() || pubkey.isEmpty || dismissed) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      bloc: subscriptionCubit,
      buildWhen: (p, c) => p.subscriptionStatus != c.subscriptionStatus,
      builder: (context, state) {
        final status = state.subscriptionStatus;

        if (status == null || status.isActivePaidSub) {
          return const SizedBox.shrink();
        }

        final padding = EdgeInsets.only(
          left: dismissible ? kDefaultPadding / 2 : 0,
          right: dismissible ? kDefaultPadding / 2 : 0,
          bottom: kDefaultPadding / 4,
        );

        if (status.isTrialing) {
          return Padding(
            padding: padding,
            child: _TrialStrip(
              daysLeft: status.trialDaysRemaining,
              stacked: !dismissible,
              onDismiss: () {
                localDatabaseRepository.setUpgradeBannerDismissed(pubkey);
                refresh.value++;
              },
            ),
          );
        }

        return Padding(
          padding: padding,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => YNavigator.pushPage(
                  context,
                  (_) => const PricingScreen(),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  child: Image.asset(
                    Images.upgrade,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
              if (dismissible)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      localDatabaseRepository.setUpgradeBannerDismissed(pubkey);
                      refresh.value++;
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(kDefaultPadding / 2),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Trial strip shown while the subscription is active but still in trial:
/// remaining days plus a shortcut to the plans.
class _TrialStrip extends StatelessWidget {
  const _TrialStrip({
    required this.daysLeft,
    this.stacked = false,
    this.onDismiss,
  });

  final int daysLeft;

  /// Button below the text instead of beside it — for narrow containers.
  final bool stacked;

  /// Dismisses the whole banner using the same per-user pref as the upgrade.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final label = Text.rich(
      TextSpan(
        text: '${context.t.trial_banner_label} · ',
        children: [
          TextSpan(
            text: context.t.trial_banner_days_left(days: daysLeft),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).highlightColor,
            fontWeight: FontWeight.w400,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final button = GestureDetector(
      onTap: () => YNavigator.pushPage(
        context,
        (_) => const PricingScreen(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        child: Text(
          context.t.sub_upgrade_now,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2 + 4,
        vertical: kDefaultPadding / 4 + 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.dot, size: 20, color: kMainColor),
              const SizedBox(width: kDefaultPadding / 4),
              Expanded(child: label),
              if (!stacked) ...[
                const SizedBox(width: kDefaultPadding / 4),
                button,
                const SizedBox(width: kDefaultPadding / 4),
                GestureDetector(
                  onTap: onDismiss,
                  child: const AppIcon(
                    FeatureIcons.close,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          if (stacked) ...[
            const SizedBox(height: kDefaultPadding / 4),
            button,
            const SizedBox(height: kDefaultPadding / 4),
          ],
        ],
      ),
    );
  }
}
