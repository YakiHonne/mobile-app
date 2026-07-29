import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../models/app_models/pricing_plan_model.dart';
import '../../../../utils/utils.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.isLn,
    required this.isLoading,
    required this.anyLoading,
    required this.isCurrent,
    required this.isUpgrade,
    required this.onCheckout,
    this.isPoints = false,
    this.pointsCost = 0,
    this.pointsEligible = false,
  });

  final PricingPlan plan;
  final bool isLn;
  final bool isPoints;
  final int pointsCost;
  final bool pointsEligible;
  final bool isLoading;
  final bool anyLoading;
  final bool isCurrent;
  final bool isUpgrade;
  final VoidCallback? onCheckout;

  String _formatPoints(int pts) {
    if (pts >= 1000) {
      return '${(pts / 1000).toStringAsFixed(pts % 1000 == 0 ? 0 : 1)}K';
    }
    return pts.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: plan.highlighted
            ? theme.primaryColor.withValues(alpha: 0.05)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2 + 4),
        border: Border.all(
          color: plan.highlighted
              ? theme.primaryColor.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: plan.highlighted ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (plan.highlighted) ...[
                const SizedBox(width: kDefaultPadding / 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                    vertical: kDefaultPadding / 4 - 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(kDefaultPadding),
                  ),
                  child: Text(
                    context.t.pricing_most_popular,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isPoints
                    ? _formatPoints(pointsCost)
                    : isLn
                        ? plan.sats
                        : plan.price,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isPoints && !pointsEligible
                      ? theme.hintColor.withValues(alpha: 0.4)
                      : null,
                ),
              ),
              const SizedBox(width: kDefaultPadding / 4),
              Text(
                isPoints
                    ? context.t.pricing_points_period
                    : isLn
                        ? context.t.pricing_sats_period
                        : plan.period,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
          if (isPoints || isLn || !kIapEnabled)
            Text(
              isPoints
                  ? (pointsEligible
                      ? context.t.pricing_points_cost(points: pointsCost.toString())
                      : context.t.pricing_points_not_eligible)
                  : isLn
                      ? context.t.pricing_approx_usd(price: plan.price)
                      : plan.highlighted
                          ? context.t.pricing_approx_sats(sats: plan.sats)
                          : context.t.pricing_approx_sats_discount(sats: plan.sats),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isPoints && !pointsEligible ? Colors.red.withValues(alpha: 0.7) : theme.hintColor,
              ),
            ),
          if (plan.desc.isNotEmpty) ...[
            const SizedBox(height: kDefaultPadding / 2),
            Text(
              plan.desc,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          Divider(height: kDefaultPadding, thickness: 0.5, color: theme.dividerColor),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: kDefaultPadding / 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.dim ? '–' : '✓',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: f.dim
                          ? theme.hintColor.withValues(alpha: 0.4)
                          : theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding / 2),
                  Expanded(
                    child: Text(
                      f.text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: f.dim ? theme.hintColor.withValues(alpha: 0.5) : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: kDefaultPadding / 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isCurrent || anyLoading ? null : onCheckout,
              child: isLoading
                  ? SpinKitCircle(color: theme.primaryColor, size: 16)
                  : Text(
                      isCurrent
                          ? context.t.pricing_current_plan
                          : isUpgrade
                          ? context.t.pricing_upgrade_to_pro
                          : isPoints
                          ? context.t.pricing_redeem_with_points
                          : context.t.pricing_cta_subscribe,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
