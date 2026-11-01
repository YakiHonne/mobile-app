import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/views/widgets/auto_complete_textfield.dart';

void main() {
  testWidgets('autocomplete treats search text as literal, ignoring case',
      (tester) async {
    final key = GlobalKey<AutoCompleteTextFieldState<String>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SimpleAutoCompleteTextField(
            key: key,
            suggestions: const ['Sigmund Freud (1856)', 'Other'],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'FREUD (');
    await tester.pump();
    expect(find.text('Sigmund Freud (1856)'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), '.*');
    await tester.pump();
    expect(find.text('Sigmund Freud (1856)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
