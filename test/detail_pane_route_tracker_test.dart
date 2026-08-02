import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/views/main_view/widgets/detail_pane.dart';

/// The detail pane's discriminator: only redirect a push into the pane when the
/// main panel is the content underneath it. One sequence, because the tracker's
/// stack is static — the pops at the end also leave it drained.
void main() {
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
}
