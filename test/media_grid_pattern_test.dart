import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/utils/platform_utils.dart';

/// The media grid picks its large (2×1) tiles arithmetically, from a pattern the
/// package lays out. This asserts the arithmetic against the *delegate's actual
/// geometry* rather than against itself — a self-consistent formula that
/// disagrees with the layout is exactly the failure mode here.
void main() {
  const constraints = SliverConstraints(
    axisDirection: AxisDirection.down,
    growthDirection: GrowthDirection.forward,
    userScrollDirection: ScrollDirection.idle,
    scrollOffset: 0,
    precedingScrollExtent: 0,
    overlap: 0,
    remainingPaintExtent: 4000,
    crossAxisExtent: 1200,
    crossAxisDirection: AxisDirection.right,
    viewportMainAxisExtent: 4000,
    remainingCacheExtent: 4000,
    cacheOrigin: 0,
  );

  for (final columns in [3, 4, 5]) {
    test('$columns-column media grid: predicted large tiles match the layout',
        () {
      final SliverGridDelegate delegate = SliverQuiltedGridDelegate(
        crossAxisCount: columns,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        repeatPattern: QuiltedGridRepeatPattern.inverted,
        pattern: [
          const QuiltedGridTile(2, 1),
          for (var i = 0; i < columns * 2 - 2; i++) const QuiltedGridTile(1, 1),
        ],
      );

      final layout = delegate.getLayout(constraints);
      final cycle = mediaGridCycle(columns);
      final largeOffset = mediaGridLargeTileOffset(columns);

      // Cell extent, from the smallest tile the layout produces.
      final extents = [
        for (var i = 0; i < cycle * 2; i++)
          layout.getGeometryForChildIndex(i).mainAxisExtent,
      ];
      final cell = extents.reduce((a, b) => a < b ? a : b);

      for (var i = 0; i < cycle * 2; i++) {
        final laidOutLarge = extents[i] > cell * 1.5;
        final predictedLarge =
            i % cycle == 0 || i % cycle == largeOffset;

        expect(
          predictedLarge,
          laidOutLarge,
          reason: 'index $i: predicted large=$predictedLarge but the layout gave '
              'mainAxisExtent ${extents[i]} (cell $cell)',
        );
      }

      // Exactly two large tiles per cycle, or the pattern is not two rows.
      expect(
        extents.take(cycle).where((e) => e > cell * 1.5).length,
        2,
      );
    });
  }
}
