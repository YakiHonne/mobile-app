import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/utils/enums.dart';
import 'package:yakihonne/views/widgets/media_selector.dart';

void main() {
  testWidgets('desktop media choices fit a narrow dialog with large text',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: MediaSelector(onSuccess: (_) {}),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MediaChoice), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
    testWidgets('$platform offers file selection without unsupported camera',
        (tester) async {
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          theme: ThemeData(platform: platform),
          home: Scaffold(body: MediaSelector(onSuccess: (_) {})),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(MediaChoice), findsOneWidget);
      expect(tester.widget<MediaChoice>(find.byType(MediaChoice)).mediaType,
          MediaType.gallery);
    });
  }
}
