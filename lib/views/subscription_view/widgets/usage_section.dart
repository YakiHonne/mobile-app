import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../logic/subscription_cubit/subscription_cubit.dart';
import '../../../models/subscription_models.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/fluid_blur_container.dart';
import '../pricing/pricing_screen.dart';

class UsageSection extends StatelessWidget {
  const UsageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      bloc: subscriptionCubit,
      buildWhen: (p, c) =>
          p.usageData != c.usageData || p.usageRefreshing != c.usageRefreshing,
      builder: (context, state) {
        if (state.usageRefreshing && state.usageData == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding * 2),
              child: SpinKitThreeBounce(
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
          );
        }

        final items = state.usageData?.items ?? [];

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding * 2),
              child: Text(
                context.t.sub_usage_load_error,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(kDefaultPadding),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: kDefaultPadding / 2),
          itemBuilder: (context, i) => _UsageRow(
            item: items[i],
            onUpgrade: () => YNavigator.pushPage(
              context,
              (_) => const PricingScreen(),
            ),
          ),
        );
      },
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.item, required this.onUpgrade});

  final UsageItem item;
  final VoidCallback onUpgrade;

  String _fmtResetIn(BuildContext context) {
    if (item.resetAt == 0) {
      return '';
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(item.resetAt * 1000);
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative || diff.inMinutes < 1) {
      return context.t.sub_usage_resets_soon;
    }
    if (diff.inDays >= 1) {
      return context.t.sub_usage_resets_in(time: '${diff.inDays}d');
    }
    if (diff.inHours >= 1) {
      return context.t.sub_usage_resets_in(time: '${diff.inHours}h');
    }
    return context.t.sub_usage_resets_in(time: '${diff.inMinutes}m');
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = Theme.of(context).hintColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    return FluidCardContainer(
      borderRadius: kDefaultPadding / 2,
      padding: const EdgeInsets.all(kDefaultPadding * 0.75),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (item.isUnlimited)
                _Badge(
                  label: context.t.sub_usage_unlimited,
                  color: Colors.green,
                )
              else if (item.isLocked)
                _Badge(
                  label: context.t.sub_usage_locked,
                  color: Colors.red.shade400,
                ),
            ],
          ),
          if (item.isLocked) ...[
            const SizedBox(height: kDefaultPadding / 2),
            GestureDetector(
              onTap: onUpgrade,
              child: Text(
                context.t.sub_usage_upgrade_prompt,
                style: textTheme.bodySmall?.copyWith(
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                  decorationColor: primaryColor,
                ),
              ),
            ),
          ] else if (!item.isUnlimited) ...[
            const SizedBox(height: kDefaultPadding / 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (item.percentage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: hintColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  item.percentage >= 90 ? Colors.orange : primaryColor,
                ),
              ),
            ),
            const SizedBox(height: kDefaultPadding / 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.percentage.toStringAsFixed(0)}%',
                  style: textTheme.labelSmall?.copyWith(color: hintColor),
                ),
                if (item.resetAt != 0)
                  Text(
                    _fmtResetIn(context),
                    style: textTheme.labelSmall?.copyWith(color: hintColor),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
