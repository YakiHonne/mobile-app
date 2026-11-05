import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../widgets/place_holders.dart';
import 'desktop_density.dart';

/// A single scrollable whose cards adapt to the space inside the side pane.
class DesktopWorkspaceFeed extends StatelessWidget {
  const DesktopWorkspaceFeed({
    super.key,
    required this.storageKey,
    required this.padding,
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.loading = false,
  });

  final PageStorageKey<String> storageKey;
  final EdgeInsets padding;
  final Widget header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool loading;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final gap = DesktopDensityScope.of(context).gap;
          final itemGap = loading ? gap / 2 : gap;
          final usable = (constraints.maxWidth - padding.horizontal)
              .clamp(0.0, double.infinity);
          // Keep text-heavy cards readable, including at larger text scales.
          final scale =
              MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
          final columns =
              ((usable + gap) / (360 * scale + gap)).floor().clamp(1, 3);
          return CustomScrollView(
            key: storageKey,
            slivers: [
              SliverPadding(
                padding: padding,
                sliver: SliverMainAxisGroup(slivers: [
                  SliverToBoxAdapter(child: header),
                  SliverPadding(
                    padding: EdgeInsets.only(top: itemCount == 0 ? 0 : gap),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: itemGap,
                      mainAxisSpacing: itemGap,
                      childCount: itemCount,
                      itemBuilder: itemBuilder,
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      );
}

/// Loading card for the desktop workspace, preserving the profile shape.
class DesktopWorkspaceSkeleton extends StatelessWidget {
  const DesktopWorkspaceSkeleton({super.key, this.label, this.people = false});

  final String? label;
  final bool people;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: ExcludeSemantics(
          child: people
              ? const SearchProfileSkeleton(outlined: true)
              : const ArticleSkeleton(outlined: true),
        ),
      );
}
