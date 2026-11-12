import 'dart:ui' show SemanticsAction;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_pane_split.dart';

void main() {
  testWidgets('resizing preserves both pane contents and scroll positions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final mainScroll = ScrollController();
    final sideScroll = ScrollController();
    addTearDown(mainScroll.dispose);
    addTearDown(sideScroll.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: SizedBox(
        width: 1600,
        height: 800,
        child: DesktopPaneSplit(
          preferences: prefs,
          label: 'Resize panes',
          mainBuilder: (_) => ListView(
            key: const ValueKey('main list'),
            controller: mainScroll,
            children: const [
              TextField(),
              SizedBox(height: 2000),
            ],
          ),
          sideBuilder: (_) => ListView(
            key: const ValueKey('side list'),
            controller: sideScroll,
            children: const [SizedBox(height: 2000)],
          ),
        ),
      )),
    ));
    await tester.enterText(find.byType(TextField), 'disposable draft');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    mainScroll.jumpTo(200);
    sideScroll.jumpTo(300);
    await tester.pump();
    await tester.dragFrom(const Offset(1079, 400), const Offset(-150, 0));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('side list'))).width,
        greaterThan(520));
    expect(mainScroll.offset, 200);
    expect(sideScroll.offset, 300);
    mainScroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('disposable draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  for (final fraction in [0.01, 0.99]) {
    testWidgets('extreme saved split $fraction remains usable across resizing',
        (tester) async {
      SharedPreferences.setMockInitialValues({'desktop_pane_split': fraction});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(1800, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
                  mainBuilder: (_) => const SizedBox(key: ValueKey('main')),
                  sideBuilder: (_) => const SizedBox(key: ValueKey('side')),
                ),
              ),
            ),
          );
      await tester.pumpWidget(build());
      expect(tester.getSize(find.byKey(const ValueKey('main'))).width,
          greaterThanOrEqualTo(400));
      expect(tester.getSize(find.byKey(const ValueKey('side'))).width,
          greaterThanOrEqualTo(400));
      width = 601;
      await tester.pumpWidget(build());
      expect(tester.getSize(find.byKey(const ValueKey('main'))).width, 300);
      expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 300);
      expect(prefs.getDouble('desktop_pane_split'), fraction);
      await tester.pumpWidget(const SizedBox());
      width = 1601;
      await tester.pumpWidget(build());
      expect(tester.getSize(find.byKey(const ValueKey('side'))).width,
          fraction < 0.5 ? 400 : 1200);
      expect(prefs.getDouble('desktop_pane_split'), fraction);
    });
  }

  testWidgets('invalid saved split falls back and semantics resize the panes',
      (tester) async {
    SharedPreferences.setMockInitialValues({'desktop_pane_split': 2.0});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 1600,
        child: DesktopPaneSplit(
          preferences: prefs,
          label: 'Resize panes',
          mainBuilder: (_) => const SizedBox(),
          sideBuilder: (_) => const ColoredBox(
            key: ValueKey('side'),
            color: Colors.blue,
          ),
        ),
      ),
    ));
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 520);
    final divider = find.bySemanticsLabel('Resize panes');
    final node = tester.getSemantics(divider);
    final owner = tester.renderObject(divider).owner!.semanticsOwner!;
    owner.performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 540);
    owner.performAction(node.id, SemanticsAction.decrease);
    await tester.pump();
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 520);
    semantics.dispose();
  });
  testWidgets('divider remains keyboard accessible without a highlight',
      (tester) async {
    SharedPreferences.setMockInitialValues({'desktop_pane_split': 0.01});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1601, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 1601,
        child: DesktopPaneSplit(
          preferences: prefs,
          label: 'Resize panes',
          mainBuilder: (_) => const SizedBox(),
          sideBuilder: (_) => const SizedBox(key: ValueKey('side')),
        ),
      ),
    ));
    final divider = find.bySemanticsLabel('Resize panes');
    var node = tester.getSemantics(divider);
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    expect(
        node.getSemanticsData().hasAction(SemanticsAction.decrease), isFalse);
    final indicator =
        find.descendant(of: divider, matching: find.byType(ColoredBox));
    expect(indicator, findsNothing);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1200, 200));
    await tester.pump();
    expect(indicator, findsNothing);
    await mouse.removePointer();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(indicator, findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(tester.getSize(find.byKey(const ValueKey('side'))).width, 420);
    final owner = tester.renderObject(divider).owner!.semanticsOwner!;
    for (var i = 0; i < 40; i++) {
      node = tester.getSemantics(divider);
      if (!node.getSemanticsData().hasAction(SemanticsAction.increase)) {
        break;
      }
      owner.performAction(node.id, SemanticsAction.increase);
      await tester.pump();
    }
    node = tester.getSemantics(divider);
    expect(
        node.getSemanticsData().hasAction(SemanticsAction.increase), isFalse);
    expect(node.getSemanticsData().hasAction(SemanticsAction.decrease), isTrue);
    semantics.dispose();
  });
}
