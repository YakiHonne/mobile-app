import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/widgets/identity_field.dart';

/// Reproduces the "Change name" unlock path of the Yaki NIP-05 sheet.
///
/// The settled state shows a plain address row — the editable name row is not
/// in the tree at all, so its controller listener is not registered and
/// `controller.clear()` fires nothing. The row then mounts with the status
/// still `alreadySet`, and `IdentityField` derives `readOnly` from exactly
/// that. Entering editing must therefore reset the status itself.
class _Harness extends HookWidget {
  const _Harness({required this.owned});

  final String owned;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: owned);
    final editing = useState(false);
    final status = useState(AddressStatus.alreadySet);

    return TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!editing.value) ...[
                // The settled branch: no name row, no listener.
                Text('$owned@yakihonne.com'),
                OutlinedButton(
                  onPressed: () {
                    editing.value = true;
                    controller.clear();
                    status.value = AddressStatus.unchecked;
                  },
                  child: const Text('change'),
                ),
              ] else
                _NameRow(
                  controller: controller,
                  status: status,
                  owned: owned,
                  editing: editing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameRow extends HookWidget {
  const _NameRow({
    required this.controller,
    required this.status,
    required this.owned,
    required this.editing,
  });

  final TextEditingController controller;
  final ValueNotifier<AddressStatus> status;
  final String owned;
  final ValueNotifier<bool> editing;

  @override
  Widget build(BuildContext context) {
    useEffect(
      () {
        void listener() {
          final name = controller.text.trim();
          if (name.isEmpty) {
            status.value = AddressStatus.unchecked;
            return;
          }
          if (name == owned && !editing.value) {
            status.value = AddressStatus.alreadySet;
            return;
          }
          status.value = AddressStatus.checking;
        }

        controller.addListener(listener);
        return () => controller.removeListener(listener);
      },
      [controller, owned],
    );

    return IdentityField(
      label: 'NIP-05 name',
      controller: controller,
      status: status.value,
      hint: 'yourname',
    );
  }
}

void main() {
  testWidgets('Change name unlocks the field on the first tap', (tester) async {
    await tester.pumpWidget(const _Harness(owned: 'alice'));

    // Opens settled: the address is shown as text, with no input at all.
    expect(find.text('alice@yakihonne.com'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('change'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.readOnly,
      isFalse,
      reason: 'one tap must unlock the field, not several',
    );
    expect(find.text('alice'), findsNothing, reason: 'field should be cleared');
  });

  testWidgets('retyping the owned name while editing keeps it unlocked',
      (tester) async {
    await tester.pumpWidget(const _Harness(owned: 'alice'));

    await tester.tap(find.text('change'));
    await tester.pump();

    // The listener reads `editing` live, so the owned name must not settle the
    // row again and trap the user in a read-only field.
    //
    // A plain pump, not pumpAndSettle: `checking` renders an indeterminate
    // spinner, which never settles.
    await tester.enterText(find.byType(TextField), 'alice');
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.readOnly, isFalse);
  });
}
