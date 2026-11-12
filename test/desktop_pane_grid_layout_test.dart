import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/utils/platform_utils.dart';

void main() {
  testWidgets(
      'box grid adapts to local width and text scale without losing scroll or draft',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final width = ValueNotifier(500.0);
    final scale = ValueNotifier(1.0);
    final draft = TextEditingController();
    final scroll = ScrollController();
    addTearDown(width.dispose);
    addTearDown(scale.dispose);
    addTearDown(draft.dispose);
    addTearDown(scroll.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: ValueListenableBuilder<double>(
        valueListenable: width,
        builder: (context, size, child) =>
            SizedBox(width: size, height: 360, child: child),
        child: ValueListenableBuilder<double>(
          valueListenable: scale,
          builder: (context, value, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(value)),
              child: child!),
          child: DesktopPaneGridBuilder(
              builder: (context, columns) => MasonryGridView.count(
                    key: const ValueKey('grid'),
                    controller: scroll,
                    crossAxisCount: columns,
                    itemCount: 30,
                    itemBuilder: (context, index) => SizedBox(
                        height: 100,
                        child: index == 0
                            ? TextField(controller: draft)
                            : Text('Item $index')),
                  )),
        ),
      ),
    ))));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'unfinished fixture');
    expect(
        (tester
                    .widget<MasonryGridView>(find.byType(MasonryGridView))
                    .gridDelegate
                as SliverSimpleGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        1);
    scroll.jumpTo(200);
    await tester.pump();
    width.value = 900;
    await tester.pump();
    expect(
        (tester
                    .widget<MasonryGridView>(find.byType(MasonryGridView))
                    .gridDelegate
                as SliverSimpleGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        2);
    expect(scroll.offset, 200);
    expect(draft.text, 'unfinished fixture');
    scale.value = 1.5;
    await tester.pump();
    expect(
        (tester
                    .widget<MasonryGridView>(find.byType(MasonryGridView))
                    .gridDelegate
                as SliverSimpleGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        1);
    expect(scroll.offset, 200);
    expect(draft.text, 'unfinished fixture');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliver grid uses local cross-axis width', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final width = ValueNotifier(500.0);
    addTearDown(width.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: ValueListenableBuilder<double>(
        valueListenable: width,
        builder: (context, value, child) =>
            SizedBox(width: value, height: 400, child: child),
        child: CustomScrollView(slivers: [
          DesktopPaneSliverGridBuilder(
            builder: (context, columns) => SliverMasonryGrid.count(
              crossAxisCount: columns,
              childCount: 4,
              itemBuilder: (context, index) =>
                  SizedBox(height: 80, child: Text('Item $index')),
            ),
          )
        ]),
      ),
    ))));
    await tester.pump();
    double x(int index) => tester.getTopLeft(find.text('Item $index')).dx;
    expect(x(0), x(1));
    width.value = 900;
    await tester.pump();
    expect(x(1), greaterThan(x(0)));
    expect(tester.takeException(), isNull);
  });
}
