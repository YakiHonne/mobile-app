import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/utils/theme/theme.dart';
import 'package:yakihonne/views/main_view/widgets/desktop_sidebar.dart';

class _Signer extends Fake implements EventSigner {
  @override
  bool canSign() => true;
}

void main() {
  for (final compact in [true, false]) {
    testWidgets('compose menu returns focus after Escape (compact: $compact)',
        (tester) async {
      currentSigner = _Signer();
      addTearDown(() => currentSigner = null);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: DesktopComposeButton(compact: compact)),
          ),
        ),
      ));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.bySemanticsLabel('Compose'), findsWidgets);
      expect(find.byType(GlassMenu), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Quick post'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Quick post'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Quick post'), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets('expanded compose fills the same rail width as Settings',
      (tester) async {
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DesktopComposeButton(compact: false),
                  DesktopSettingsButton(
                    compact: false,
                    label: 'Settings',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    final compose = find.byType(TextButton);
    final settings = find.byKey(const ValueKey('desktop-settings-surface'));
    expect(tester.getSize(compose).width, 240);
    expect(tester.getRect(compose).left, tester.getRect(settings).left);
    expect(tester.getRect(compose).right, tester.getRect(settings).right);
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('glass Compose label fits at text scale $scale',
        (tester) async {
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          theme: AppPreferredThemes.fluidGraphite(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(
            body: Center(
                child: SizedBox(
                    width: 240, child: DesktopComposeButton(compact: false))),
          ),
        ),
      ));
      final button = tester.getRect(find.byType(TextButton));
      final label = tester.getRect(find.text('Compose'));
      expect(button.contains(label.topLeft), isTrue);
      expect(button.contains(label.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('account action opens a dialog and restores keyboard focus',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return DesktopAccountButton(
            label: 'Switch accounts',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(content: Text('Accounts')),
            ),
            child: const SizedBox(width: 44, height: 44),
          );
        }),
      ),
    ));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Accounts'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Accounts'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Accounts'), findsOneWidget);
  });
}
