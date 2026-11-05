import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/views/main_view/desktop/workspace_feed.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';

void main() {
  testWidgets('desktop skeletons are outlined and keep their content shapes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ListView(children: const [
        DesktopWorkspaceSkeleton(people: true),
        DesktopWorkspaceSkeleton(),
        SearchProfileSkeleton(),
        ArticleSkeleton(),
      ]),
    ));

    BoxDecoration decoration(Finder skeleton) => tester
        .widget<Container>(find
            .descendant(
              of: skeleton,
              matching: find.byType(Container),
            )
            .first)
        .decoration! as BoxDecoration;

    for (final skeleton in [
      find.byType(SearchProfileSkeleton).first,
      find.byType(ArticleSkeleton).first,
    ]) {
      expect(decoration(skeleton).border, isNotNull);
      expect(decoration(skeleton).color, isNull);
    }
    for (final skeleton in [
      find.byType(SearchProfileSkeleton).last,
      find.byType(ArticleSkeleton).last,
    ]) {
      expect(decoration(skeleton).border, isNull);
      expect(decoration(skeleton).color, isNotNull);
    }
  });

  testWidgets('loading grid uses tighter gaps than loaded cards',
      (tester) async {
    var loading = true;
    Widget build() => MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 600,
              child: DesktopWorkspaceFeed(
                storageKey: const PageStorageKey('loading-feed'),
                padding: EdgeInsets.zero,
                header: const SizedBox.shrink(),
                loading: loading,
                itemCount: 2,
                itemBuilder: (_, index) =>
                    SizedBox(key: ValueKey(index), height: 40),
              ),
            ),
          ),
        );
    double itemGap() =>
        tester.getTopLeft(find.byKey(const ValueKey(1))).dy -
        tester.getBottomLeft(find.byKey(const ValueKey(0))).dy;
    await tester.pumpWidget(build());
    expect(itemGap(), closeTo(20 / 3, 0.01));
    loading = false;
    await tester.pumpWidget(build());
    expect(itemGap(), closeTo(40 / 3, 0.01));
  });

  testWidgets('workspace feed uses pane width and text scale for its columns',
      (tester) async {
    tester.view.physicalSize = const Size(1800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var width = 520.0;
    var scale = 1.0;
    Widget build() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: 600,
                child: DesktopWorkspaceFeed(
                  storageKey: const PageStorageKey('feed'),
                  padding: const EdgeInsets.all(10),
                  header: const Text('Header'),
                  itemCount: 8,
                  itemBuilder: (_, index) => SizedBox(
                    key: ValueKey(index),
                    height: 120,
                    child: Text('Card $index'),
                  ),
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(build());
    expect(tester.getTopLeft(find.byKey(const ValueKey(0))).dx,
        tester.getTopLeft(find.byKey(const ValueKey(1))).dx);
    width = 900;
    await tester.pumpWidget(build());
    expect(tester.getTopLeft(find.byKey(const ValueKey(1))).dx,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey(0))).dx));
    scale = 2;
    await tester.pumpWidget(build());
    expect(tester.getTopLeft(find.byKey(const ValueKey(0))).dx,
        tester.getTopLeft(find.byKey(const ValueKey(1))).dx);
    expect(tester.takeException(), isNull);
  });
}
