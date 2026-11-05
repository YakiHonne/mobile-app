import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/routes/navigator.dart';
import 'package:yakihonne/utils/constants.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_dm_routing.dart'
    as dm_routing;
import 'package:yakihonne/views/main_view/widgets/desktop_sidebar.dart';
import 'package:yakihonne/views/main_view/widgets/detail_pane.dart';

/// The detail pane's discriminator: only redirect a push into the pane when the
/// main panel is the content underneath it. One sequence, because the tracker's
/// stack is static — the pops at the end also leave it drained.
void main() {
  testWidgets('desktop message links select the inner conversation',
      (tester) async {
    final root = GlobalKey<NavigatorState>();
    String? selected;
    dm_routing.openDesktopConversation = (pubkey) => selected = pubkey;
    addTearDown(() => dm_routing.openDesktopConversation = null);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: root,
      navigatorObservers: [DetailPaneRouteTracker()],
      home: Navigator(
        key: detailPaneNavigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Text('outer pane'),
        ),
      ),
    ));
    await YNavigator.pushNamed<void>(root.currentContext!, '/dmDetailsView',
        arguments: ['alice']);
    await tester.pump();
    expect(selected, 'alice');
    expect(find.text('outer pane'), findsOneWidget);
    expect(detailPaneNavigatorKey.currentState!.canPop(), isFalse);
  });

  test('desktop pane shares narrow windows and caps at its preferred width',
      () {
    expect(desktopDetailPaneWidth(600), 299.5);
    // The native minimum includes the compact rail and shell padding.
    const panelAtMinimum =
        1153.0 - kDesktopSidebarCompactWidth - 3 * (kDefaultPadding / 1.5);
    final pane = desktopDetailPaneWidth(panelAtMinimum);
    expect(pane, (panelAtMinimum - 1) / 2);
    expect(panelAtMinimum - pane - 1, pane);
    expect(pane, 520);
    expect(desktopDetailPaneWidth(1400), 520);
  });

  testWidgets('isMainPanelUnderneath ignores sheets but not full-screen routes',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [DetailPaneRouteTracker()],
        home: const Scaffold(body: Text('panel')),
      ),
    );

    expect(DetailPaneRouteTracker.isMainPanelUnderneath, isTrue);

    // A dialog / sheet is non-opaque: the panel is still what is underneath.
    showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const SizedBox.shrink(),
    );
    await tester.pumpAndSettle();
    expect(DetailPaneRouteTracker.isMainPanelUnderneath, isTrue);

    // Popping and pushing in the same frame — what every fast-access sheet does,
    // and what `canPop()` got wrong.
    navigator.currentState!.pop();
    expect(DetailPaneRouteTracker.isMainPanelUnderneath, isTrue);
    await tester.pumpAndSettle();

    // A full-screen route is opaque: pushes from here must stay full-screen.
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('x'))),
    );
    await tester.pumpAndSettle();
    expect(DetailPaneRouteTracker.isMainPanelUnderneath, isFalse);

    // A sheet opened inside that full-screen route inherits its answer.
    showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const SizedBox.shrink(),
    );
    await tester.pumpAndSettle();
    expect(DetailPaneRouteTracker.isMainPanelUnderneath, isFalse);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(DetailPaneRouteTracker.isMainPanelUnderneath, isTrue);
  });

  testWidgets('search opens in the pane when available and otherwise at root',
      (tester) async {
    final root = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: root,
        navigatorObservers: [DetailPaneRouteTracker()],
        home: Scaffold(
          body: Navigator(
            key: detailPaneNavigatorKey,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const Text('empty pane'),
            ),
          ),
        ),
      ),
    );

    YNavigator.pushPage<void>(
      root.currentContext,
      (_) => const Text('pane search'),
      pageName: 'SearchView',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(detailPaneNavigatorKey),
        matching: find.text('pane search'),
      ),
      findsOneWidget,
    );
    expect(root.currentState!.canPop(), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: root,
        navigatorObservers: [DetailPaneRouteTracker()],
        home: const Scaffold(body: Text('single panel')),
      ),
    );
    YNavigator.pushPage<void>(
      root.currentContext,
      (_) => const Text('full search'),
      pageName: 'SearchView',
    );
    await tester.pumpAndSettle();
    expect(find.text('full search'), findsOneWidget);
    expect(root.currentState!.canPop(), isTrue);
  });

  testWidgets('hidden pane preserves a composer and new pushes use the root',
      (tester) async {
    final root = GlobalKey<NavigatorState>();
    late StateSetter setVisibility;
    var visible = true;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: root,
        navigatorObservers: [DetailPaneRouteTracker()],
        home: StatefulBuilder(
          builder: (context, setState) {
            setVisibility = setState;
            return Scaffold(
              body: Visibility(
                visible: visible,
                maintainState: true,
                child: Navigator(
                  key: detailPaneNavigatorKey,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => const Text('empty pane'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    YNavigator.pushPage<void>(
      root.currentContext,
      (_) => const Scaffold(body: TextField()),
      pageName: 'AddContentView',
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'unfinished draft');

    setVisibility(() => visible = false);
    await tester.pumpAndSettle();
    YNavigator.pushPage<void>(
      root.currentContext,
      (_) => const Text('media composer'),
      pageName: 'AddMediaView',
    );
    await tester.pumpAndSettle();
    expect(find.text('media composer'), findsOneWidget);
    expect(root.currentState!.canPop(), isTrue);

    root.currentState!.pop();
    setVisibility(() => visible = true);
    await tester.pumpAndSettle();
    expect(find.text('unfinished draft'), findsOneWidget);
    expect(root.currentState!.canPop(), isFalse);
  });

  testWidgets('desktop pages and selected conversations use the pane',
      (tester) async {
    final root = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: root,
        navigatorObservers: [DetailPaneRouteTracker()],
        home: Scaffold(
          body: Navigator(
            key: detailPaneNavigatorKey,
            observers: [detailPaneObserver],
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Text('${settings.name}:${settings.arguments}'),
            ),
          ),
        ),
      ),
    );

    YNavigator.pushNamed<void>(root.currentContext!, '/wallet');
    await tester.pumpAndSettle();
    expect(find.text('/wallet:null'), findsOneWidget);
    expect(root.currentState!.canPop(), isFalse);

    YNavigator.pushNamed<void>(root.currentContext!, '/dmDetailsView',
        arguments: 'first');
    await tester.pumpAndSettle();
    YNavigator.pushNamed<void>(root.currentContext!, '/dmDetailsView',
        arguments: 'second');
    await tester.pumpAndSettle();
    expect(find.text('/dmDetailsView:second'), findsOneWidget);
    detailPaneNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('/wallet:null'), findsOneWidget);

    showDialog<void>(
      context: root.currentContext!,
      builder: (context) => TextButton(
        onPressed: () => YNavigator.pushReplacement<void, void>(
          context,
          const Text('replacement page'),
        ),
        child: const Text('replace dialog'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('replace dialog'));
    await tester.pumpAndSettle();
    expect(find.text('replacement page'), findsOneWidget);
    expect(root.currentState!.canPop(), isFalse);
  });
}
