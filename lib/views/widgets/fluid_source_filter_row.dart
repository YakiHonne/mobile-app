import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../utils/utils.dart';
import '../discover_view/discover_view.dart' show SourceButton;
import '../main_view/widgets/app_bar_widgets.dart' show FilterGlobalButton;
import '../widgets/fluid_blur_container.dart';
import 'adaptive_smart_refresher.dart';

/// Height of the source control shared by both desktop panes.
const double kFluidSourceControlHeight = kDefaultPadding * 2;

/// Reserved height for the floating row, including its breathing room.
const double kFluidSourceFilterRowHeight = 48;

/// Top inset for the floating source-filter row.
///
/// Mobile clears the status bar and the fluid app bar. The desktop content
/// panel has neither, so the row sits at `kDefaultPadding` — the same inset the
/// new-content pill uses at the bottom, so the two gaps read as equal.
double fluidFilterRowTop(BuildContext context) => isDesktopPlatform
    ? kDefaultPadding
    : MediaQuery.of(context).padding.top + kToolbarHeight + kDefaultPadding / 2;

/// Scroll space to reserve above the first item so the floating row does not
/// cover it. [extra] is the per-view mobile allowance; desktop derives its
/// inset from [fluidFilterRowTop] instead so all three feeds line up.
double fluidFeedTopInset(BuildContext context, {double extra = 0}) =>
    isDesktopPlatform
        ? kDefaultPadding + kFluidSourceFilterRowHeight + kDefaultPadding / 2
        : MediaQuery.of(context).padding.top + kToolbarHeight + extra;

class FluidSourceFilterRow extends StatelessWidget {
  const FluidSourceFilterRow({
    super.key,
    required this.viewType,
    required this.onSourceChanged,
    this.refreshController,
  });

  final ViewDataTypes viewType;
  final VoidCallback onSourceChanged;
  final RefreshController? refreshController;

  @override
  Widget build(BuildContext context) {
    return FluidSourceContainer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SourceButton(
              viewType: viewType,
              onSourceChanged: onSourceChanged,
            ),
          ),
          SizedBox(
            height: 20,
            child: VerticalDivider(
              width: 1,
              thickness: 0.5,
              color: Theme.of(context).dividerColor,
            ),
          ),
          FilterGlobalButton(viewType: viewType),
          if (isDesktopPlatform && refreshController != null) ...[
            SizedBox(
              height: 20,
              child: VerticalDivider(
                width: 1,
                thickness: 0.5,
                color: Theme.of(context).dividerColor,
              ),
            ),
            DesktopRefreshButton(
              controller: refreshController!,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// The shared floating surface used by source selectors in both panes.
class FluidSourceContainer extends StatelessWidget {
  const FluidSourceContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isDesktopPlatform ? kFluidSourceControlHeight : null,
      width: isDesktopPlatform
          ? min(
              (MediaQuery.of(context).size.width - kDefaultPadding)
                  .clamp(0.0, double.infinity),
              380)
          : min(70.w, 380),
      child: FluidBlurContainer(
        borderRadius: kDefaultPadding * 2,
        child: child,
      ),
    );
  }
}
