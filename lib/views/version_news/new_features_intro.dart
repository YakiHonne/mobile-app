import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import '../main_view/widgets/feature_tour.dart';
import '../widgets/app_icon.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/fluid_blur_container.dart';

/// Shown once per install after a major release: highlights the new core
/// features, then hands off to the spotlight tour.
class NewFeaturesIntro extends StatelessWidget {
  const NewFeaturesIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      (FeatureIcons.ai, context.t.aiToolsTitle, context.t.aiToolsDesc),
      (
        FeatureIcons.appearance,
        context.t.fluidModeTitle,
        context.t.fluidModeDesc
      ),
      (
        FeatureIcons.home,
        context.t.redesignedNavTitle,
        context.t.redesignedNavDesc
      ),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      // The glass surface carries the shape and fill — keep the dialog bare.
      backgroundColor: kTransparent,
      elevation: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FluidBlurContainer(
            sigma: 20,
            borderRadius: kDefaultPadding,
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.t.newInYakihonne,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: kDefaultPadding),
                ...features.map(
                  (f) => _FeatureRow(icon: f.$1, title: f.$2, subtitle: f.$3),
                ),
                const SizedBox(height: kDefaultPadding / 2),
                // The caller starts the tour — this context dies on pop.
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(context.t.takeTheTour),
                ),
                TextButton(
                  onPressed: () {
                    markFeatureTourSeen();
                    Navigator.of(context).pop(false);
                  },
                  child: Text(context.t.maybeLater),
                ),
              ],
            ),
          ),
          Positioned(
            right: -12,
            top: -12,
            child: CustomIconButton(
              onClicked: () {
                markFeatureTourSeen();
                Navigator.of(context).pop(false);
              },
              icon: FeatureIcons.closeRaw,
              size: 15,
              vd: -2,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
            child: AppIcon(
              icon,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
