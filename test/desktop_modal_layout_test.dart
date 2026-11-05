import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/common/functions/functions_set.dart';
import 'package:yakihonne/views/widgets/modal_sheet_container.dart';

void main() {
  testWidgets('desktop modal has a complete border and vertical padding',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () => showAdaptiveModal<void>(
              context,
              backgroundColor: Colors.white,
              dialogHeight: 200,
              builder: (_) => const ModalSheetContainer(
                child: ColoredBox(
                  key: ValueKey('body'),
                  color: Colors.blue,
                  child: SizedBox.expand(),
                ),
              ),
            ),
            child: const Text('Open'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final decoration = find.descendant(
      of: find.byType(Dialog),
      matching: find.byWidgetPredicate((widget) =>
          widget is DecoratedBox &&
          widget.position == DecorationPosition.foreground &&
          widget.decoration is BoxDecoration),
    );
    final border =
        (tester.widget<DecoratedBox>(decoration).decoration as BoxDecoration)
            .border! as Border;
    expect(border.top.width, greaterThan(0));
    expect(border.bottom.width, greaterThan(0));
    expect(border.left.width, greaterThan(0));
    expect(border.right.width, greaterThan(0));
    final outer = tester.getRect(decoration);
    final body = tester.getRect(find.byKey(const ValueKey('body')));
    expect(body.top, greaterThan(outer.top));
    expect(body.bottom, lessThan(outer.bottom));
    final sheetContainer = tester.widget<Container>(find
        .descendant(
          of: find.byType(ModalSheetContainer),
          matching: find.byType(Container),
        )
        .first);
    final sheetDecoration = sheetContainer.decoration! as BoxDecoration;
    expect(sheetDecoration.border, isNull);
    expect(sheetDecoration.color, Colors.transparent);
    expect(
      tester
          .widgetList<ColoredBox>(find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(ColoredBox),
          ))
          .any((box) => box.color == Colors.white),
      isTrue,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });
}
