import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../utils/theme/glass_settings.dart';

/// Glass tab bar used in fluid mode, driven by a [TabController].
///
/// [floating] picks `GlassTabBar.bottom` (the DM view's floating pill) over
/// `GlassTabBar.inline` (in-page switcher). [segmented] picks
/// `GlassSegmentedControl` instead — reserved for 2–3 peer options that fit
/// without scrolling, not for tab bars over feeds.
class FluidGlassTabBar extends StatelessWidget {
  const FluidGlassTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.floating = false,
    this.segmented = false,
    this.barHeight = 40,
    this.maxWidth = 500,
  });

  final List<GlassTab> tabs;

  /// Defaults to the ambient [DefaultTabController].
  final TabController? controller;

  /// Extra side effect on selection, on top of moving the controller.
  final ValueChanged<int>? onTap;

  final bool floating;
  final bool segmented;
  final double barHeight;

  /// Logical-px cap so the bar stops stretching on tablets. Phones are ~390–430
  /// wide so this never bites there; callers wrapping in a tight `SizedBox`
  /// (DM, search) still get capped because [Center] loosens the constraint.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final tabController = controller ?? DefaultTabController.of(context);
    final theme = Theme.of(context);

    // Listen to the controller itself, not `controller.animation`. GlassTabBar
    // runs its own spring on the indicator, driven off a *discrete*
    // selectedIndex change in didUpdateWidget. Rebuilding every animation frame
    // fed it the same index ~60x and restarted the settings object each time,
    // so the pill never got a clean single transition to animate. The
    // controller notifies on index changes (taps and settled swipes), which is
    // exactly the one event the spring needs.
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _bar(context, tabController, theme),
      ),
    );
  }

  Widget _bar(
    BuildContext context,
    TabController tabController,
    ThemeData theme,
  ) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        void select(int index) {
          tabController.animateTo(index);
          onTap?.call(index);
        }

        if (segmented) {
          return GlassSegmentedControl(
            height: barHeight,
            settings: GlassSettings.segmentedControl(context),
            selectedIndex: tabController.index,
            onSegmentSelected: select,
            selectedTextStyle: theme.textTheme.labelMedium!.copyWith(
              color: theme.primaryColorDark,
              fontWeight: FontWeight.w600,
            ),
            unselectedTextStyle: theme.textTheme.labelMedium!.copyWith(
              color: theme.hintColor,
            ),
            segments: tabs
                .map((t) => GlassSegment(icon: t.icon, label: t.label))
                .toList(),
          );
        }

        return floating
            ? GlassTabBar.bottom(
                barHeight: barHeight,
                settings: GlassSettings.floatingTabBar(context),
                selectedIndex: tabController.index,
                onTabSelected: select,
                selectedIconColor: theme.primaryColorDark,
                unselectedIconColor: theme.hintColor,
                unselectedLabelStyle: theme.textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                tabs: tabs,
              )
            : GlassTabBar.inline(
                barHeight: barHeight,
                // The label row is inset by tabPadding but the indicator's slot
                // math uses the full bar width, so any horizontal tabPadding
                // shifts labels off the pill centre — worst at the edge tabs.
                tabPadding: EdgeInsets.zero,
                settings: GlassSettings.inlineTabBar(context),
                selectedIndex: tabController.index,
                onTabSelected: select,

                selectedIconColor: theme.primaryColorDark,
                unselectedIconColor: theme.hintColor,
                unselectedLabelStyle: theme.textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                tabs: tabs,
              );
      },
    );
  }
}
