import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/common/markdown/iframe.dart';
import 'package:yakihonne/common/pomegranate/google_auth_webview.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';

void main() {
  testWidgets('Linux avoids unsupported embedded webviews', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(children: [
              const XWebView(html: 'https://example.com/status/fixture'),
              TextButton(
                onPressed: () => GoogleAuthWebView.show(
                  context,
                  'https://example.com/fixture',
                  GoogleAuthWebViewType.login,
                ),
                child: const Text('Start fixture'),
              ),
            ]),
          ),
        ),
      ),
    ));
    expect(find.text('Use external browser'), findsOneWidget);
    await tester.tap(find.text('Start fixture'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Google sign-in is unavailable on Linux'),
        findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextButton),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });
}
