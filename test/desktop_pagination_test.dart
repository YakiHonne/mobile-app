import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
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

  test('failed loads wait for an explicit retry', () {
    expect(call(status: LoadStatus.failed), isFalse);
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
      TranslationProvider(
          child: MaterialApp(
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
      )),
    );

    await tester.pump();
    await tester.pump();
    expect(find.text('Load more'), findsNothing);

    await tester.fling(
        find.byType(Scrollable).first, const Offset(0, -6000), 4000);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(loadCount, 1);
    controller.dispose();
  });

  testWidgets('layout-time scroll notifications defer and coalesce loading',
      (tester) async {
    if (!isDesktopPlatform) {
      return;
    }
    final controller = RefreshController();
    final listKey = GlobalKey();
    var loads = 0;
    var dispatched = false;

    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: AdaptiveSmartRefresher(
            controller: controller,
            enablePullUp: true,
            onLoading: () => loads++,
            child: ListView(
              key: listKey,
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  if (!dispatched) {
                    dispatched = true;
                    final metrics = FixedScrollMetrics(
                      minScrollExtent: 0,
                      maxScrollExtent: 1000,
                      pixels: 1000,
                      viewportDimension: 400,
                      axisDirection: AxisDirection.down,
                      devicePixelRatio: 1,
                    );
                    for (var i = 0; i < 2; i++) {
                      ScrollUpdateNotification(
                        metrics: metrics,
                        context: listKey.currentContext!,
                      ).dispatch(listKey.currentContext);
                    }
                  }
                  return const SizedBox(height: 1200);
                }),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(loads, 1);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('desktop controls refresh and paginate a short list',
      (tester) async {
    if (!isDesktopPlatform) {
      return;
    }
    final controller = RefreshController();
    var loads = 0;
    var refreshes = 0;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: AdaptiveSmartRefresher(
            controller: controller,
            enablePullDown: false,
            enablePullUp: true,
            desktopHasResults: true,
            onRefresh: () => refreshes++,
            onLoading: () => loads++,
            child: ListView(children: const [Text('Short feed')]),
          ),
        ),
      ),
    ));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Load more'));
    await tester.pump();
    expect(loads, 1);
    expect(find.text('Loading'), findsNothing);
    expect(find.text('Load more'), findsNothing);
    controller.loadFailed();
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(loads, 2);
    controller.loadNoData();
    await tester.pump();
    await tester.pump();
    expect(find.widgetWithText(TextButton, 'No more data'), findsNothing);
    expect(find.text('Load more'), findsNothing);
    await tester.tap(find.byTooltip('refresh'));
    await tester.pump();
    expect(refreshes, 1);
    expect(controller.footerStatus, LoadStatus.idle);
    expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    controller.refreshCompleted();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('load control follows changes in list extent', (tester) async {
    if (!isDesktopPlatform) {
      return;
    }
    final controller = RefreshController();
    Widget feed(int count, {bool hasResults = true}) => TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: AdaptiveSmartRefresher(
                controller: controller,
                desktopHasResults: hasResults,
                enablePullUp: true,
                onLoading: () {},
                child: ListView.builder(
                  itemCount: count,
                  itemBuilder: (_, i) => const SizedBox(height: 80),
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(feed(1));
    await tester.pump();
    await tester.pump();
    expect(find.text('Load more'), findsOneWidget);
    await tester.pumpWidget(feed(1, hasResults: false));
    await tester.pump();
    expect(find.text('Load more'), findsNothing);
    await tester.pumpWidget(feed(1));
    await tester.pump();
    await tester.pumpWidget(feed(50));
    await tester.pump();
    await tester.pump();
    expect(find.text('Load more'), findsNothing);
    await tester.pumpWidget(feed(1));
    await tester.pump();
    await tester.pump();
    expect(find.text('Load more'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('a feed header can host the shared refresh control',
      (tester) async {
    if (!isDesktopPlatform) {
      return;
    }
    final controller = RefreshController();
    var refreshes = 0;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              DesktopRefreshButton(controller: controller),
              Expanded(
                child: AdaptiveSmartRefresher(
                  controller: controller,
                  showDesktopRefresh: false,
                  onRefresh: () => refreshes++,
                  child: ListView(children: const [Text('Feed')]),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
    expect(find.byType(DesktopRefreshButton), findsOneWidget);
    await tester.tap(find.byTooltip('refresh'));
    await tester.pump();
    expect(refreshes, 1);
    expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    controller.refreshCompleted();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
