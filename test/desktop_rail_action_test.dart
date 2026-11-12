import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_rail_action.dart';

void main() {
  testWidgets('rail action is labeled, focusable and keyboard activated',
      (tester) async {
    var activations = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DesktopRailAction(
          label: 'Search',
          selected: true,
          onPressed: () => activations++,
          child: const SizedBox(width: 44, height: 44),
        ),
      ),
    ));
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    expect(
        tester.getSemantics(find.bySemanticsLabel('Search')),
        matchesSemantics(
            label: 'Search',
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true));
    BoxDecoration decoration() => tester
        .widget<DecoratedBox>(find.descendant(
          of: find.byType(DesktopRailAction),
          matching: find.byType(DecoratedBox),
        ))
        .decoration as BoxDecoration;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(decoration().border, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(activations, 2);
    semantics.dispose();
  });

  testWidgets('rail action does not highlight on hover', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DesktopRailAction(
        label: 'Search',
        onPressed: () {},
        child: const SizedBox(width: 44, height: 44),
      ),
    ));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(
        location: tester.getCenter(find.byType(DesktopRailAction)));
    await tester.pump();
    final box = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(DesktopRailAction),
      matching: find.byType(DecoratedBox),
    ));
    expect((box.decoration as BoxDecoration).border, isNull);
    await mouse.removePointer();
  });
}
