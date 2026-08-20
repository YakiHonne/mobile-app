import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../logic/subscription_badge_cubit/subscription_badge_cubit.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

/// Shows the YakiHonne premium/basic badge for [pubkey], if any.
/// Fetches and caches the plan via [subscriptionBadgeCubit] so it only
/// needs to be looked up once per pubkey app-wide.
class SubscriptionBadgeView extends StatefulWidget {
  const SubscriptionBadgeView(
      {super.key, required this.pubkey, this.size = 22});

  final String pubkey;
  final double size;

  @override
  State<SubscriptionBadgeView> createState() => _SubscriptionBadgeViewState();
}

class _SubscriptionBadgeViewState extends State<SubscriptionBadgeView> {
  @override
  void initState() {
    super.initState();
    subscriptionBadgeCubit.fetchPlan(widget.pubkey);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBadgeCubit, SubscriptionBadgeState>(
      bloc: subscriptionBadgeCubit,
      buildWhen: (previous, current) =>
          previous.plans[widget.pubkey] != current.plans[widget.pubkey] ||
          previous.badgeImages[widget.pubkey] !=
              current.badgeImages[widget.pubkey],
      builder: (context, state) {
        final plan = state.plans[widget.pubkey] ?? '';

        if (plan.isEmpty) {
          return const SizedBox.shrink();
        }

        final imageUrl = state.badgeImages[widget.pubkey] ?? '';

        return GestureDetector(
          onTap: () => BotToastUtils.showInformation(
            plan == 'premium'
                ? "YakiHonne's Premium subscriber"
                : "YakiHonne's Basic subscriber",
          ),
          child: imageUrl.isNotEmpty
              ? ExtendedImage.network(
                  imageUrl,
                  width: widget.size,
                  height: widget.size,
                  // ponytail: decode at display size, not source size.
                  cacheWidth:
                      (widget.size * MediaQuery.devicePixelRatioOf(context))
                          .round(),
                  fit: BoxFit.contain,
                  loadStateChanged: (state) =>
                      state.extendedImageLoadState == LoadState.failed
                          ? _iconBadge(context, plan)
                          : null,
                )
              : _iconBadge(context, plan),
        );
      },
    );
  }

  Widget _iconBadge(BuildContext context, String plan) {
    final isPremium = plan == 'premium';
    final color =
        isPremium ? const Color(0xFFB8860B) : Theme.of(context).primaryColor;

    return Icon(
      LucideIcons.crown,
      size: widget.size,
      color: color,
    );
  }
}
