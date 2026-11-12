import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('search field can hide its ring while accepting keyboard input',
      (tester) async {
    final focus = FocusNode();
    final controller = TextEditingController();
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GlassTextField.search(
          focusNode: focus,
          controller: controller,
          showFocusRing: false,
        ),
      ),
    ));
    focus.requestFocus();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), 'fixture');
    expect(focus.hasFocus, isTrue);
    expect(controller.text, 'fixture');
    expect(
      find.byWidgetPredicate((widget) =>
          widget is CustomPaint &&
          widget.painter?.runtimeType.toString() == 'GlassFocusRingPainter'),
      findsNothing,
    );
  });
}
