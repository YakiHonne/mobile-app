import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../utils/utils.dart';
import '../../widgets/fluid_blur_container.dart';

/// Targets for the spotlight tour. Only one of the normal/fluid variants of the
/// app bar and nav bar is ever mounted, so the same key is safe on both.
class TourKeys {
  static final drawer = GlobalKey();
  static final title = GlobalKey();
  static final search = GlobalKey();
  static final home = GlobalKey();
  static final media = GlobalKey();
  static final wallet = GlobalKey();
  static final dms = GlobalKey();
  static final notifications = GlobalKey();
  static final create = GlobalKey();
}

/// Set by `MainViewContent` so the tour can pin the glass bars on screen while
/// it measures targets — they slide off screen on scroll otherwise.
ValueNotifier<bool>? mainBarsVisible;

const kAlwaysShowFeatureTour = false;

class _Step {
  const _Step(
    this.key,
    this.title,
    this.description, {
    this.circle = false,
  });

  final GlobalKey key;
  final String title;
  final String description;
  final bool circle;

  /// Whether the target currently sits in the lower half of the screen. Can't
  /// be a fixed flag — notifications is a nav tab in normal mode but an app-bar
  /// button in fluid mode.
  bool isLow(BuildContext context) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;

    if (box == null || !box.hasSize) {
      return false;
    }

    final centerY = box.localToGlobal(box.size.center(Offset.zero)).dy;

    return centerY > MediaQuery.of(context).size.height / 2;
  }
}

List<_Step> _steps(BuildContext context) {
  final t = context.t;

  return [
    _Step(TourKeys.drawer, t.profile.capitalizeFirst(), t.tourProfile,
        circle: true),
    _Step(TourKeys.title, t.tourFeedTitle, t.tourFeed),
    _Step(TourKeys.search, t.search.capitalizeFirst(), t.tourSearch,
        circle: true),
    _Step(TourKeys.notifications, t.notifications.capitalizeFirst(),
        t.tourNotifications,
        circle: true),
    _Step(TourKeys.home, t.home.capitalizeFirst(), t.tourHome, circle: true),
    _Step(TourKeys.media, t.media.capitalizeFirst(), t.tourMedia, circle: true),
    _Step(TourKeys.create, t.tourCreateTitle, t.tourCreate, circle: true),
    _Step(TourKeys.wallet, t.wallet.capitalizeFirst(), t.tourWallet,
        circle: true),
    _Step(TourKeys.dms, t.tourMessagesTitle, t.tourMessages, circle: true),
  ];
}

Future<void> showFeatureTour(BuildContext context) async {
  // Glass bars slide off screen on scroll — pin them so targets can be measured.
  mainBarsVisible?.value = true;
  await Future.delayed(const Duration(milliseconds: 350));

  if (!context.mounted) {
    return;
  }

  // The fluid and normal bars expose different items (no FAB in fluid, no
  // notifications tab in fluid), so drop whatever isn't currently mounted.
  final steps =
      _steps(context).where((s) => s.key.currentContext != null).toList();

  if (steps.isEmpty) {
    markFeatureTourSeen();
    return;
  }

  TutorialCoachMark(
    targets: [
      for (var i = 0; i < steps.length; i++)
        _target(steps[i], i, steps.length, isLow: steps[i].isLow(context)),
    ],
    opacityShadow: 0.88,
    paddingFocus: 6,
    // Skip lives in the card next to Next, not floating at the screen edge.
    hideSkip: true,
    onFinish: markFeatureTourSeen,
    onSkip: () {
      markFeatureTourSeen();
      return true;
    },
  ).show(context: context, rootOverlay: true);
}

void markFeatureTourSeen() {
  if (!kAlwaysShowFeatureTour) {
    localDatabaseRepository.setFeatureTourSeen();
  }
}

TargetFocus _target(
  _Step step,
  int index,
  int total, {
  required bool isLow,
}) {
  return TargetFocus(
    identify: step.title,
    keyTarget: step.key,
    shape: step.circle ? ShapeLightFocus.Circle : ShapeLightFocus.RRect,
    radius: kDefaultPadding / 2,
    contents: [
      TargetContent(
        // Copy goes above low targets, below high ones — never off screen.
        align: isLow ? ContentAlign.top : ContentAlign.bottom,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding,
        ),
        builder: (context, controller) => _TourCard(
          title: step.title,
          description: step.description,
          index: index,
          total: total,
          controller: controller,
        ),
      ),
    ],
  );
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.title,
    required this.description,
    required this.index,
    required this.total,
    required this.controller,
  });

  final String title;
  final String description;
  final int index;
  final int total;
  final TutorialCoachMarkController controller;

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: FluidBlurContainer(
        sigma: 20,
        borderRadius: kDefaultPadding * 3 / 4,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 3 / 4,
          vertical: kDefaultPadding / 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: kDefaultPadding / 8),
            Text(
              description,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: kDefaultPadding / 2),
            // Equal-width flanks keep the dots centred whether or not Skip shows.
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: isLast
                        ? const SizedBox.shrink()
                        : TextButton(
                            onPressed: controller.skip,
                            style: _compact(context),
                            child: Text(context.t.skip.capitalizeFirst()),
                          ),
                  ),
                ),
                _Dots(index: index, total: total),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: controller.next,
                      style: _compact(context),
                      child: Text(
                        isLast
                            ? context.t.tourDone
                            : context.t.next.capitalizeFirst(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _compact(BuildContext context) => TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        minimumSize: const Size(84, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.labelMedium,
      );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            // No trailing gap on the last dot, or the row sits off-centre.
            margin: EdgeInsetsDirectional.only(end: i == total - 1 ? 0 : 4),
            height: 5,
            // The current step reads as a pill, the rest as dots.
            width: i == index ? 14 : 5,
            decoration: BoxDecoration(
              color: i == index
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
      ],
    );
  }
}
