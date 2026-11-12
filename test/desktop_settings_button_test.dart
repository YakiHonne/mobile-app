import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/views/main_view/widgets/desktop_sidebar.dart';
import 'package:yakihonne/views/widgets/app_icon.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('compact Settings icon is centered in its border: $direction',
        (tester) async {
      var pressed = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: direction,
            child: DesktopSettingsButton(
              compact: true,
              label: 'Settings',
              onPressed: () => pressed++,
            ),
          ),
        ),
      ));
      final surface = find.byKey(const ValueKey('desktop-settings-surface'));
      expect(tester.getSize(surface),
          const Size(kDesktopCompactFooterSize, kDesktopCompactFooterSize));
      expect(tester.getCenter(find.byType(AppIcon)), tester.getCenter(surface));
      final decoration =
          tester.widget<Container>(surface).decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.border, isNotNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(pressed, 1);
    });
  }

  testWidgets('expanded Settings icon is vertically centered with a border',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 220,
          child: DesktopSettingsButton(
            compact: false,
            label: 'Settings',
            onPressed: () {},
          ),
        ),
      ),
    ));
    final surface = find.byKey(const ValueKey('desktop-settings-surface'));
    expect(tester.getSize(surface),
        const Size(220, kDesktopCompactFooterSize));
    expect(tester.getCenter(find.byType(AppIcon)).dy,
        tester.getCenter(surface).dy);
    final decoration =
        tester.widget<Container>(surface).decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
  });
  testWidgets('compact profile image stays centered inside the 44-point action',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            DesktopAccountButton(
              compact: true,
              label: 'Switch accounts',
              onPressed: () {},
              child: Container(
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DesktopAccountAvatar(
                      size: kDesktopCompactFooterSize,
                      image: '',
                      pubkey: '',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            DesktopSettingsButton(
              compact: true,
              label: 'Settings',
              onPressed: () {},
            ),
          ],
        ),
      ),
    ));
    expect(
        tester.getSize(find.byType(DesktopAccountButton)),
        const Size(
            kDesktopCompactFooterSize, kDesktopCompactFooterSize));
    final avatar = find.byType(DesktopAccountAvatar);
    final action = find.byType(DesktopAccountButton);
    expect(
        tester.getSize(avatar),
        const Size(
            kDesktopCompactFooterSize, kDesktopCompactFooterSize));
    expect(tester.getCenter(avatar), tester.getCenter(action));
    expect(tester.getSize(action),
        tester.getSize(find.byKey(const ValueKey('desktop-settings-surface'))));
  });
}
