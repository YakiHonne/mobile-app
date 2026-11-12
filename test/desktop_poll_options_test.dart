import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/write_note_view/widgets/poll_options.dart';

void main() {
  testWidgets('desktop poll choices fit a short dialog with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 220,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: PollOptions(onDataAdded: (_) {}),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Create poll'), findsOneWidget);
    expect(find.text('Browse polls'), findsOneWidget);
    final scrollable = find.byType(SingleChildScrollView);
    await tester.drag(scrollable, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.text('Browse polls')).dy,
        lessThanOrEqualTo(tester.getBottomRight(scrollable).dy));
    expect(tester.takeException(), isNull);
  });
}
