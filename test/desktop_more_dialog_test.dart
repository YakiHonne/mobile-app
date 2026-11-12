import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_more_dialog.dart';

void main() {
  testWidgets('search, keyboard activation and focus restoration',
      (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var activated = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  focusNode: focus,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => DesktopMoreDialog(
                      title: 'More',
                      searchLabel: 'Search',
                      emptyLabel: 'No results',
                      entries: [
                        DesktopMoreEntry(
                            label: 'Articles',
                            icon: Icons.article,
                            onPressed: () => activated = 'articles'),
                        DesktopMoreEntry(
                            label: 'Settings',
                            icon: Icons.settings,
                            onPressed: () => activated = 'settings'),
                      ],
                    ),
                  ),
                  child: const Text('Open'),
                )),
      ),
    ));
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'SETT');
    await tester.pumpAndSettle();
    expect(find.text('Articles'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activated, 'settings');
    expect(focus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(DesktopMoreDialog), findsNothing);
    expect(focus.hasFocus, isTrue);
  });
  testWidgets('long RTL labels fit in a short window at large text',
      (tester) async {
    tester.view.physicalSize = const Size(420, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.5)),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
      home: Scaffold(
          body: DesktopMoreDialog(
        title: 'المزيد',
        searchLabel: 'بحث',
        emptyLabel: 'لا توجد نتائج',
        entries: [
          DesktopMoreEntry(
            label: 'إعدادات الاشتراكات وتفضيلات الحساب الطويلة',
            icon: Icons.settings,
            onPressed: () {},
          )
        ],
      )),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ListTile), findsOneWidget);
  });
  testWidgets('groups remain clear when filtering destinations',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: DesktopMoreDialog(
        title: 'More',
        searchLabel: 'Search',
        emptyLabel: 'No results',
        entries: [
          DesktopMoreEntry(
              label: 'Articles',
              group: 'Content',
              icon: Icons.article,
              onPressed: () {}),
          DesktopMoreEntry(
              label: 'Explore',
              group: 'Discover',
              icon: Icons.explore,
              onPressed: () {}),
          DesktopMoreEntry(
              label: 'Relay orbits',
              group: 'Discover',
              icon: Icons.public,
              onPressed: () {}),
        ],
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'relay');
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsNothing);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Relay orbits'), findsOneWidget);
  });
}
