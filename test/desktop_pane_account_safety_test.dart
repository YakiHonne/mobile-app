import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/views/main_view/widgets/detail_pane.dart';

class _Signer extends Fake implements EventSigner {
  _Signer(this.pubkey);

  final String pubkey;

  @override
  String getPublicKey() => pubkey;
}

void main() {
  testWidgets('signer refresh preserves draft; account changes clear pane',
      (tester) async {
    final repository = NostrDataRepository();
    addTearDown(repository.currentSignerController.close);
    addTearDown(() => detailPaneObserver.accountPubkey = null);
    await tester.pumpWidget(MaterialApp(
      home: Navigator(
        key: detailPaneNavigatorKey,
        observers: [detailPaneObserver],
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('base')),
        ),
      ),
    ));

    final alice = _Signer('disposable-alice');
    final bob = _Signer('disposable-bob');
    repository.setCurrentSignerState(alice);
    detailPaneNavigatorKey.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: TextField()),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'disposable draft');

    repository.setCurrentSignerState(_Signer('disposable-alice'));
    await tester.pumpAndSettle();
    expect(find.text('disposable draft'), findsOneWidget);
    expect(detailPaneNavigatorKey.currentState!.canPop(), isTrue);

    repository.setCurrentSignerState(bob);
    await tester.pumpAndSettle();
    expect(find.text('base'), findsOneWidget);
    expect(find.text('disposable draft'), findsNothing);
    expect(detailPaneNavigatorKey.currentState!.canPop(), isFalse);

    detailPaneNavigatorKey.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Text('bob detail'),
    ));
    await tester.pumpAndSettle();
    repository.setCurrentSignerState(null);
    await tester.pumpAndSettle();
    expect(find.text('base'), findsOneWidget);
    expect(find.text('bob detail'), findsNothing);
    expect(detailPaneNavigatorKey.currentState!.canPop(), isFalse);
  });
}
