import 'package:flutter_test/flutter_test.dart';

/// Guards the transaction-processing chain in `CheckoutCubit`: batches queue
/// behind each other, and one that throws must not stall the chain for the
/// next. Mirrors the `_processing = _processing.then(...).catchError(...)`
/// idiom — the plugin itself is not mockable cheaply, so this pins the shape.
void main() {
  test('a throwing batch does not break the chain for the next one', () async {
    final order = <String>[];
    var chain = Future<void>.value();

    Future<void> queue(Future<void> Function() batch) {
      return chain =
          chain.then((_) => batch()).catchError((Object _) => order.add('err'));
    }

    queue(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      order.add('a');
    });
    queue(() async => throw StateError('boom'));
    await queue(() async => order.add('c'));

    expect(order, ['a', 'err', 'c']);
  });
}
