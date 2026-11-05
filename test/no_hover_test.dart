// ignore_for_file: implementation_imports, invalid_use_of_internal_member
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_focus_region.dart';
import 'package:pull_down_button/src/_internals/button.dart';
import 'package:yakihonne/utils/theme/no_hover_theme.dart';

void main() {
  testWidgets('mobile keeps the original third-party hover behavior',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final oldStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      FocusManager.instance.highlightStrategy = oldStrategy;
    });
    final hovered = ValueNotifier(false);
    addTearDown(hovered.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          GlassFocusRegion(
            enabled: true,
            isHoveredNotifier: hovered,
            child: const SizedBox(width: 80, height: 80),
          ),
          MenuActionButton(
            onTap: () {},
            pressedColor: Colors.blue,
            hoverColor: Colors.red,
            child: Builder(
                builder: (context) => SizedBox(
                      width: 80,
                      height: 80,
                      child: Text(MenuActionButtonState.of(context)
                          ? 'hover'
                          : 'normal'),
                    )),
          ),
        ]),
      ),
    ));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(200, 200));
    await mouse.moveTo(tester.getCenter(find.byType(GlassFocusRegion)));
    await tester.pump();
    expect(hovered.value, isTrue);
    await mouse.moveTo(tester.getCenter(find.byType(MenuActionButton)));
    await tester.pump();
    expect(find.text('hover'), findsOneWidget);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
    FocusManager.instance.highlightStrategy = oldStrategy;
  });

  test('theme suppresses hover without suppressing press or focus', () {
    final theme = withoutHoverHighlights(ThemeData());
    expect(theme.hoverColor, Colors.transparent);
    expect(theme.inputDecorationTheme.hoverColor, Colors.transparent);
    for (final style in [
      theme.textButtonTheme.style!,
      theme.elevatedButtonTheme.style!,
      theme.outlinedButtonTheme.style!,
      theme.iconButtonTheme.style!,
    ]) {
      expect(style.overlayColor!.resolve({WidgetState.hovered}),
          Colors.transparent);
      expect(style.overlayColor!.resolve({WidgetState.pressed})!.a,
          greaterThan(0));
      expect(style.overlayColor!.resolve({WidgetState.focused})!.a,
          greaterThan(0));
      expect(
          style.overlayColor!
              .resolve({WidgetState.hovered, WidgetState.focused})!.a,
          greaterThan(0));
    }
  });

  testWidgets('glass region keeps hover clear while retaining focus and tap',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final oldStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = oldStrategy);
    final hovered = ValueNotifier(false);
    final focused = ValueNotifier(false);
    final focus = FocusNode();
    addTearDown(hovered.dispose);
    addTearDown(focused.dispose);
    addTearDown(focus.dispose);
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: GlassFocusRegion(
            enabled: true,
            isHoveredNotifier: hovered,
            isFocusedNotifier: focused,
            focusNode: focus,
            semanticOnTap: () => taps++,
            onKeyboardActivate: () => taps++,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      ),
    ));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(GlassFocusRegion)));
    await tester.pump();
    expect(hovered.value, isFalse);
    focus.requestFocus();
    await tester.pump();
    expect(focused.value, isTrue);
    await tester.tap(find.byType(GlassFocusRegion));
    expect(taps, 1);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('pull-down items stay unhighlighted and remain clickable',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: MenuActionButton(
            onTap: () => taps++,
            pressedColor: Colors.blue,
            hoverColor: Colors.red,
            child: Builder(
                builder: (context) => SizedBox(
                      width: 80,
                      height: 80,
                      child: Text(MenuActionButtonState.of(context)
                          ? 'hover'
                          : 'normal'),
                    )),
          ),
        ),
      ),
    ));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(MenuActionButton)));
    await tester.pump();
    expect(find.text('normal'), findsOneWidget);
    final box = tester.widget<DecoratedBox>(find
        .descendant(
          of: find.byType(MenuActionButton),
          matching: find.byType(DecoratedBox),
        )
        .first);
    expect((box.decoration as BoxDecoration).color, isNull);
    await tester.tap(find.byType(MenuActionButton));
    expect(taps, 1);
    await mouse.removePointer();
    debugDefaultTargetPlatformOverride = null;
  });
}
