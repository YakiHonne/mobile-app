import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/app_view/app_view.dart';

void main() {
  for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
    testWidgets('smart widget offers a browser fallback on $platform',
        (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      await tester.pumpWidget(TranslationProvider(
        child: const MaterialApp(
          home: Scaffold(
            body: SmartWidgetAppView(url: 'https://example.com/fixture'),
          ),
        ),
      ));
      expect(find.byType(SmartWidgetBrowserFallback), findsOneWidget);
      expect(find.textContaining('Interactive signing is unavailable'),
          findsOneWidget);
      expect(find.text('Use external browser'), findsOneWidget);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
