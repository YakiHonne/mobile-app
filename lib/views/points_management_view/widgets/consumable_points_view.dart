import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../utils/utils.dart';

class ConsumablePointsView extends StatelessWidget {
  const ConsumablePointsView({super.key});

  @override
  Widget build(BuildContext context) {
    final consumablePointsPerks = [
      context.t.consumablePointsPerks1.capitalizeFirst(),
      context.t.consumablePointsPerks2.capitalizeFirst(),
      context.t.consumablePointsPerks3.capitalizeFirst(),
    ];

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      width: isTablet ? 50.w : double.infinity,
      margin: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
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
            height: kDefaultPadding / 2,
          ),
          ...consumablePointsPerks.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 8,
              ),
              child: Text(
                e,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: kWhite,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.start,
              ),
            ),
          ),
          const SizedBox(
            height: kDefaultPadding,
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
      ),
    );
  }
}
