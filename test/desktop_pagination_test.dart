import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:yakihonne/utils/platform_utils.dart';
import 'package:yakihonne/views/widgets/adaptive_smart_refresher.dart';

void main() {
  bool call({
    double pixels = 5000,
    double maxScrollExtent = 5000,
    LoadStatus? status = LoadStatus.idle,
    int depth = 0,
    Axis axis = Axis.vertical,
  }) =>
      shouldLoadMore(
        pixels: pixels,
        maxScrollExtent: maxScrollExtent,
        status: status,
        depth: depth,
        axis: axis,
      );

  test('at bottom + idle triggers load', () {
    expect(call(), isTrue);
  });

  test('far from bottom does not trigger', () {
    expect(call(pixels: 100), isFalse);
  });

  test('already loading does not re-trigger', () {
    expect(call(status: LoadStatus.loading), isFalse);
  });

  test('no more data does not trigger', () {
    expect(call(status: LoadStatus.noMore), isFalse);
  });

  test('nested (horizontal carousel) scroll does not trigger', () {
    expect(call(depth: 1), isFalse);
  });

  test('non-scrollable list (maxScrollExtent 0) does not trigger', () {
    expect(call(pixels: 0, maxScrollExtent: 0), isFalse);
  });

  test('horizontal axis does not trigger', () {
    expect(call(axis: Axis.horizontal), isFalse);
  });

  testWidgets('scrolling to the bottom fires onLoading exactly once on desktop',
      (tester) async {
    if (!isDesktopPlatform) {
      return;
    }

    final controller = RefreshController();
    var loadCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveSmartRefresher(
            controller: controller,
            enablePullUp: true,
            footer: const ClassicFooter(),
            onLoading: () => loadCount++,
            child: ListView.builder(
              itemCount: 60,
              itemBuilder: (_, i) => SizedBox(height: 80, child: Text('$i')),
            ),
          ),
        ),
      ),
    );

    await tester.fling(
        find.byType(Scrollable).first, const Offset(0, -6000), 4000);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(loadCount, 1);
    controller.dispose();
  });
}
