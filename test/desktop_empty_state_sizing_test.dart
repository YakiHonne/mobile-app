import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/widgets/no_content_widgets.dart';

void main() {
  testWidgets('offline content fits a narrow desktop pane with large text',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retried = false;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 600,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: NoInternetView(
                  isButtonEnabled: true,
                  onClicked: () => retried = true,
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 220,
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: NoInternetRow(
                title:
                    'A long translated connection instruction with multiple words',
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
