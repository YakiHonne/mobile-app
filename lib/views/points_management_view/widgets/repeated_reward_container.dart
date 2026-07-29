import 'package:flutter/material.dart';

import '../../../models/points_system_models.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/fluid_blur_container.dart';

class RepeatedReward extends StatelessWidget {
  const RepeatedReward({
    super.key,
    required this.standard,
    required this.cooldownVal,
    required this.collectedPoints,
  });

  final PointStandard standard;
  final int cooldownVal;
  final int collectedPoints;

  @override
  Widget build(BuildContext context) {
    final content = IntrinsicHeight(
      child: Row(
        children: [
          _standartColumn(context),
          _cooldown(context),
          const VerticalDivider(
            width: 0,
          ),
          _points(context)
        ],
      ),
    );
    return isFluid()
        ? FluidCardContainer(
            borderRadius: kDefaultPadding / 2,
            padding: EdgeInsets.zero,
            child: content,
          )
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: content,
          );
  }

  Padding _points(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(
        kDefaultPadding / 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            collectedPoints.toString(),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          Text(
            context.t.points.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Padding _cooldown(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          children: [
            Positioned.fill(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: cooldownVal == -1
                    ? 1
                    : cooldownVal.toDouble() /
                        Duration(seconds: standard.cooldown).inMinutes,
                color: kGreen,
                strokeCap: StrokeCap.round,
                backgroundColor: kBlack.withValues(alpha: 0.3),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cooldownVal == -1)
                    AppIcon(
                      FeatureIcons.infinity,
                      size: 20,
                      color: Theme.of(context).primaryColorDark,
                    )
                  else ...[
                    Text(
                      cooldownVal.toString(),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 8,
                    ),
                    Text(
                      context.t.min.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            height: 1,
                          ),
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Expanded _standartColumn(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              standard.displayName,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.labelSmall,
                children: [
                  TextSpan(
                    text: '${context.t.gain.capitalize()} ',
                  ),
                  TextSpan(
                    text: '${standard.points.first} xp',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  TextSpan(
                    text: ' ${context.t.forName(name: standard.displayName)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
