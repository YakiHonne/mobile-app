import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:yakihonne/utils/theme/custom/buttons_theme.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_glass_button.dart';
import 'package:yakihonne/views/main_view/widgets/desktop_sidebar.dart';

void main() {
  testWidgets('account avatar invokes the switcher action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: DesktopAccountAvatar(
          image: '',
          pubkey: 'fixture',
          onPressed: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(DesktopAccountAvatar));
    expect(taps, 1);
  });

  testWidgets('desktop glass text buttons match default icon height',
      (tester) async {
    final original = TbuttonsTheme.fluidTextButtonTheme(
      backgroundColor: Colors.black,
      borderColor: Colors.grey,
      foregroundColor: Colors.white,
    );
    final iconHeight = GlassIconButton(
      icon: const Icon(LucideIcons.user),
      onPressed: () {},
    ).size;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
          textButtonTheme: TbuttonsTheme.desktopFluidTextButtonTheme(original)),
      home: Center(
          child: TextButton(onPressed: () {}, child: const Text('Follow'))),
    ));
    expect(tester.getSize(find.byType(TextButton)).height, iconHeight);
    expect(original.style!.minimumSize, isNull);
  });

  testWidgets('profile text surface aligns with the rendered glass icon',
      (tester) async {
    final theme = TbuttonsTheme.fluidTextButtonTheme(
      backgroundColor: Colors.black,
      borderColor: Colors.grey,
      foregroundColor: Colors.white,
    );
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(textButtonTheme: theme),
      home: Scaffold(
        body: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            DesktopGlassButtonHeight(
              child: AbsorbPointer(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Unfollow'),
                ),
              ),
            ),
            const SizedBox(width: 5),
            GlassIconButton(
              icon: const Icon(LucideIcons.user),
              onPressed: () {},
              useOwnLayer: true,
              quality: GlassQuality.minimal,
            ),
          ]),
        ),
      ),
    ));
    final surface = find.descendant(
      of: find.byType(TextButton),
      matching: find.byWidgetPredicate((widget) =>
          widget is DecoratedBox && widget.decoration is BoxDecoration),
    );
    final textRect = tester.getRect(surface.first);
    final iconRect = tester.getRect(find.byType(GlassIconButton));
    expect(textRect.height, iconRect.height);
    expect(textRect.top, iconRect.top);
    expect(textRect.bottom, iconRect.bottom);
  });

  testWidgets('desktop glass action styles align and grow for larger text',
      (tester) async {
    final textTheme = TbuttonsTheme.fluidTextButtonTheme(
      backgroundColor: Colors.black,
      borderColor: Colors.grey,
      foregroundColor: Colors.white,
    );
    final elevatedTheme = TbuttonsTheme.fluidElevatedButtonTheme();
    final outlinedTheme = TbuttonsTheme.fluidOutlinedButtonTheme();
    final theme = ThemeData(
      visualDensity: VisualDensity.compact,
      textButtonTheme: TbuttonsTheme.desktopFluidTextButtonTheme(textTheme),
      elevatedButtonTheme:
          TbuttonsTheme.desktopFluidElevatedButtonTheme(elevatedTheme),
      outlinedButtonTheme:
          TbuttonsTheme.desktopFluidOutlinedButtonTheme(outlinedTheme),
    );
    Widget build(double scale) => MaterialApp(
          theme: theme,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  TextButton(onPressed: () {}, child: const Text('Next')),
                  ElevatedButton(onPressed: () {}, child: const Text('Create')),
                  OutlinedButton(onPressed: () {}, child: const Text('Back')),
                ]),
              ),
            ),
          ),
        );
    await tester.pumpWidget(build(1));
    for (final type in [TextButton, ElevatedButton, OutlinedButton]) {
      expect(
          tester.getSize(find.byType(type)).height, kDesktopGlassButtonHeight);
    }
    await tester.pumpWidget(build(2));
    for (final type in [TextButton, ElevatedButton, OutlinedButton]) {
      expect(tester.getSize(find.byType(type)).height,
          greaterThan(kDesktopGlassButtonHeight));
    }
    expect(textTheme.style!.minimumSize, isNull);
  });
}
