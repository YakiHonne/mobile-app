import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/widgets/custom_date_picker.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('desktop calendar scrollbar supports mouse in $direction',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: const [
              Breakpoint(start: 0, end: 450, name: MOBILE),
              Breakpoint(start: 451, end: 2000, name: DESKTOP),
            ],
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 480,
                child: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: Directionality(
                    textDirection: direction,
                    child: PickDateTimeWidget(
                      focusedDate: DateTime(2020, 11, 5),
                      onDateSelected: (_) {},
                      onClearDate: () {},
                      isAfter: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final scrollbarFinder = find.byWidgetPredicate(
        (widget) => widget is Scrollbar && widget.controller != null,
      );
      final scrollbar = tester.widget<Scrollbar>(scrollbarFinder);
      expect(scrollbar.thumbVisibility, isTrue);
      final controller = scrollbar.controller!;
      expect(controller.position.maxScrollExtent, greaterThan(0));
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      final bounds = tester.getRect(scrollbarFinder);
      final start = Offset(
        direction == TextDirection.ltr ? bounds.left + 50 : bounds.right - 50,
        bounds.bottom - 3,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: start);
      await mouse.down(start);
      await tester.pump();
      await mouse.moveBy(Offset(direction == TextDirection.ltr ? 30 : -30, 0));
      await tester.pump();
      await mouse.moveBy(Offset(direction == TextDirection.ltr ? 70 : -70, 0));
      await tester.pump();
      await mouse.up();
      await mouse.removePointer();
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('desktop date picker stays usable within a short narrow pane',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var cleared = false;

    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: 2000, name: DESKTOP),
          ],
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 350,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: PickDateTimeWidget(
                  focusedDate: DateTime(2026, 11, 5),
                  onDateSelected: (_) {},
                  onClearDate: () => cleared = true,
                  isAfter: false,
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Clear date'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Clear date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear date'));
    expect(cleared, isTrue);
    expect(tester.takeException(), isNull);
  });
}
