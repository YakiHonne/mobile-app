import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/dm_view/widgets/dm_details.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_compact_content.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_dm_workspace.dart';

void main() {
  testWidgets('embedded conversation has no close button', (tester) async {
    final selection = ValueNotifier(false);
    final selectedEvents = ValueNotifier(<String>{});
    addTearDown(selection.dispose);
    addTearDown(selectedEvents.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return DmAppBar(
              pubkey: 'fixture',
              isSelectionMode: selection,
              selectedEvents: selectedEvents,
              onClose: () {},
            ).leading(context) ??
            const SizedBox.shrink();
      }),
    ));
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('compact content caps its local width and adapts to narrow panes',
      (tester) async {
    var width = 1200.0;
    Widget build() => MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              height: 400,
              child: DesktopCompactContent(
                child: Builder(builder: (context) {
                  return Text('${MediaQuery.sizeOf(context).width}');
                }),
              ),
            ),
          ),
        );
    await tester.pumpWidget(build());
    expect(find.text('680.0'), findsOneWidget);
    width = 350;
    await tester.pumpWidget(build());
    expect(find.text('350.0'), findsOneWidget);
  });

  testWidgets(
      'DM selection stays inside the main area and survives tab changes',
      (tester) async {
    var activeTab = 0;
    final selected = ValueNotifier<String?>(null);
    addTearDown(selected.dispose);
    Widget build() => TranslationProvider(
          child: MaterialApp(
            home: IndexedStack(index: activeTab, children: [
              DesktopDmWorkspace(
                selected: selected,
                list: Builder(builder: (context) {
                  return TextButton(
                    onPressed: () =>
                        DesktopDmScope.maybeSelect(context)!('alice'),
                    child: const Text('Choose conversation'),
                  );
                }),
                conversationBuilder: (_, peer, close) => TextButton(
                  onPressed: close,
                  child: Text('Conversation: $peer'),
                ),
              ),
              const Text('Another tab'),
            ]),
          ),
        );
    await tester.pumpWidget(build());
    await tester.tap(find.text('Choose conversation'));
    await tester.pump();
    expect(find.text('Conversation: alice'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Conversation: alice')).dx,
        greaterThan(tester.getTopLeft(find.text('Choose conversation')).dx));
    tester.view.physicalSize = const Size(500, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    expect(find.text('Choose conversation'), findsOneWidget);
    expect(find.text('Conversation: alice'), findsNothing);
    expect(selected.value, 'alice');
    tester.view.physicalSize = const Size(800, 600);
    await tester.pump();
    expect(find.text('Conversation: alice'), findsOneWidget);
    activeTab = 1;
    await tester.pumpWidget(build());
    activeTab = 0;
    await tester.pumpWidget(build());
    expect(find.text('Conversation: alice'), findsOneWidget);
    await tester.tap(find.text('Conversation: alice'));
    await tester.pump();
    expect(find.text('Conversation: alice'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('DM draft survives crossing the inner split breakpoint',
      (tester) async {
    final selected = ValueNotifier<String?>('disposable-peer');
    addTearDown(selected.dispose);
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var width = 700.0;
    Widget build() => TranslationProvider(
          child: MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: 600,
                child: DesktopDmWorkspace(
                  selected: selected,
                  list: const Text('Conversation list'),
                  conversationBuilder: (_, __, ___) =>
                      const Material(child: TextField()),
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(build());
    await tester.enterText(find.byType(TextField), 'disposable draft');
    width = 400;
    await tester.pumpWidget(build());
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextField, skipOffstage: false), findsOneWidget);
    width = 700;
    await tester.pumpWidget(build());
    expect(find.text('disposable draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
