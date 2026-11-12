import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_pane_split.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_rail_action.dart';

void main() {
  testWidgets('Tab can leave the nested pane and reach both other controls',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final activated = <String>{};
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Row(children: [
          DesktopRailAction(
            label: 'Rail',
            onPressed: () => activated.add('rail'),
            child: const SizedBox(width: 60, height: 60),
          ),
          Expanded(
            child: DesktopPaneSplit(
              preferences: prefs,
              label: 'Resize panes',
              mainBuilder: (_) => Center(
                child: TextButton(
                  onPressed: () => activated.add('main'),
                  child: const Text('Main'),
                ),
              ),
              sideBuilder: (_) => Navigator(
                onGenerateRoute: (_) => PageRouteBuilder<void>(
                  pageBuilder: (_, __, ___) => Center(
                    child: TextButton(
                      onPressed: () => activated.add('side'),
                      child: const Text('Side'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    // The nested Navigator initially owns focus. Continue traversing rather
    // than assuming that the first Tab starts at the rail.
    for (var i = 0; i < 10 && activated.length < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
    }
    expect(activated, {'rail', 'main', 'side'});
  });
}
