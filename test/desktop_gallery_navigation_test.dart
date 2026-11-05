import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/gallery_view/gallery_view.dart';
import 'package:yakihonne/views/widgets/yaki_gallery/yaki_gallery.dart';

void main() {
  testWidgets('gallery arrows have matching surfaces and navigate pages',
      (tester) async {
    final controller = PageController();
    var current = 0;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            return Column(children: [
              Expanded(
                child: YakiGallery<String>(
                  sources: const ['one', 'two'],
                  initIndex: 0,
                  pageController: controller,
                  onPageChanged: (page) => setState(() => current = page),
                  itemBuilder: (_, index, __) => Text('item $index'),
                ),
              ),
              DesktopGalleryProgress(
                currentIndex: current,
                count: 2,
                pageController: controller,
              ),
            ]);
          }),
        ),
      ),
    ));
    final arrows = find.descendant(
      of: find.byType(DesktopGalleryProgress),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(arrows.first).onPressed, isNull);
    final previous =
        tester.getRect(find.byKey(const ValueKey('gallery-previous')));
    final next = tester.getRect(find.byKey(const ValueKey('gallery-next')));
    final progress =
        tester.getRect(find.byKey(const ValueKey('gallery-progress')));
    expect(previous.height, next.height);
    expect(previous.height, progress.height);
    expect(previous.top, progress.top);
    expect(previous.bottom, progress.bottom);
    await tester.tap(arrows.last);
    await tester.pumpAndSettle();
    expect(current, 1);
    expect(tester.widget<IconButton>(arrows.last).onPressed, isNull);
    await tester.tap(arrows.first);
    await tester.pumpAndSettle();
    expect(current, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('external navigation and swiping update the same gallery page',
      (tester) async {
    final controller = PageController();
    var current = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: YakiGallery<String>(
          sources: const ['one', 'two', 'three'],
          initIndex: 0,
          pageController: controller,
          onPageChanged: (page) => current = page,
          itemBuilder: (_, index, __) => Center(child: Text('item $index')),
        ),
      ),
    ));
    controller.animateToPage(1,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    await tester.pumpAndSettle();
    expect(current, 1);
    expect(find.text('item 1'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(current, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
