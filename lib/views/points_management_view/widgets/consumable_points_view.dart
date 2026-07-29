import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../utils/utils.dart';
import '../../widgets/fluid_blur_container.dart';

class ConsumablePointsView extends StatelessWidget {
  const ConsumablePointsView({super.key});

  @override
  Widget build(BuildContext context) {
    final perks = [
      (
        icon: LucideIcons.star,
        title: context.t.consumablePointsPerks1.capitalizeFirst(),
        description: context.t.consumablePointsPerksDesc1.capitalizeFirst(),
      ),
      (
        icon: LucideIcons.fileText,
        title: context.t.consumablePointsPerks2.capitalizeFirst(),
        description: context.t.consumablePointsPerksDesc2.capitalizeFirst(),
      ),
      (
        icon: LucideIcons.zap,
        title: context.t.consumablePointsPerks3.capitalizeFirst(),
        description: context.t.consumablePointsPerksDesc3.capitalizeFirst(),
      ),
    ];

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.yakihonneConsPoints.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w800,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Text(
          context.t.soonUsers.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        ...perks.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: kDefaultPadding / 3),
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: Icon(
                    e.icon,
                    size: 16,
                    color: kWhite,
                  ),
                ),
                const SizedBox(width: kDefaultPadding / 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: kDefaultPadding / 8),
                      Text(
                        e.description,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).highlightColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          context.t.startEarningPoints.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: kGreen,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              context.t.gotIt.capitalizeFirst(),
            ),
          ),
        ),
      ],
    );

    final width = isTablet ? 50.w : double.infinity;

    if (isFluid()) {
      return Container(
        width: width,
        margin: const EdgeInsets.all(kDefaultPadding),
        child: FluidBlurContainer(
          sigma: 20,
          borderRadius: kDefaultPadding,
          padding: const EdgeInsets.all(kDefaultPadding),
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      margin: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: const EdgeInsets.all(kDefaultPadding),
      child: content,
    );
  }
}
