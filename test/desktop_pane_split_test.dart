import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_pane_split.dart';

void main() {
  testWidgets('mouse can resize in both directions at minimum window width',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 1041,
          height: 400,
          child: DesktopPaneSplit(
            preferences: prefs,
            label: 'Resize panes',
            mainBuilder: (_) => const ColoredBox(
              key: ValueKey('main'),
              color: Colors.red,
            ),
            sideBuilder: (_) => const ColoredBox(
              key: ValueKey('side'),
              color: Colors.blue,
            ),
          ),
        ),
      ),
    ));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(520, 200));
    await mouse.down(const Offset(520, 200));
    await mouse.moveBy(const Offset(-30, 0));
    await mouse.moveBy(const Offset(-70, 0));
    await tester.pump();
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width,
        greaterThan(520));
    await mouse.moveBy(const Offset(200, 0));
    await tester.pump();
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width,
        lessThan(520));
    await mouse.up();
    await mouse.removePointer();
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('divider clamps, persists, restores and resets', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var width = 1601.0;
    Widget build() => MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: 400,
              child: DesktopPaneSplit(
                preferences: prefs,
                label: 'Resize panes',
                mainBuilder: (_) => const ColoredBox(
                  key: ValueKey('main'),
                  color: Colors.red,
                ),
                sideBuilder: (_) => const ColoredBox(
                  key: ValueKey('side'),
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        );
    tester.view.physicalSize = const Size(1800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(build());
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 520);
    await tester.dragFrom(const Offset(1080, 200), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 800);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(build());
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 800);
    width = 1041;
    await tester.pumpWidget(build());
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 520);
    await tester.pump(const Duration(milliseconds: 400));
    width = 1601;
    await tester.pumpWidget(build());
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 800);
    await tester.tapAt(const Offset(800, 200));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 520);
    await tester.pump(const Duration(milliseconds: 400));
  });

}
