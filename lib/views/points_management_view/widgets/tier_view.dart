// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/points_system_models.dart';
import '../../../utils/utils.dart';
import '../../widgets/fluid_blur_container.dart';

class TierView extends StatelessWidget {
  const TierView({
    super.key,
    required this.tier,
  });

  final PointSystemTier tier;

  @override
  Widget build(BuildContext context) {
    final stats = tier.getStats();
    final isUnlocked = stats['isUnlocked'];
    final levelsToNextTier = stats['levelsToNextTier'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: FluidCardContainer(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              tier.icon,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            if (isUnlocked) ...[
              Text(
                '🎉',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Text(
                context.t.unlocked.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: kGreen,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ] else ...[
              Text(
                '🔒',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                context.t.locked.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              context.t
                  .levelNumber(number: tier.level.toString())
                  .capitalizeFirst(),
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            if (!isUnlocked) ...[
              LinearProgressIndicator(
                value: tier.level / tier.min,
                color: kRed,
                minHeight: 5,
                backgroundColor: kBlack.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(
                  kDefaultPadding / 2,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Text(
                context.t
                    .levelsRequiredNum(number: levelsToNextTier.toString())
                    .capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
            ],
            ...tier.description.map(
              (e) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: kDefaultPadding / 10),
                child: Text(
                  e,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                openWebPage(url: pointsSystemUrl);
              },
              icon: Text(
                context.t.seeMore.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontStyle: FontStyle.italic,
                      color: kRed,
                    ),
                textAlign: TextAlign.left,
              ),
              label: const Icon(
                LucideIcons.chevronRight,
                size: 15,
                color: kRed,
              ),
              style: TextButton.styleFrom(
                backgroundBuilder: (_, __, child) => child!,
                backgroundColor: kTransparent,
                visualDensity: const VisualDensity(
                  vertical: -2,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.t.gotIt.capitalizeFirst(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
