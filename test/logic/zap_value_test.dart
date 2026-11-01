import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:yakihonne/common/functions/functions_set.dart';

void main() {
  Event receipt(String invoice) => Event.partial(
        id: 'test',
        kind: EventKind.ZAP,
        tags: [
          ['bolt11', invoice],
        ],
      );

  test('malformed zap invoices return zero without throwing', () {
    expect(getZapValue(receipt('lnbc1o')), 0);
    expect(getZapValue(receipt('')), 0);
  });

  test('valid zap invoices retain their amount in sats', () {
    const invoice =
        'lnbc10u1pdsw4dkpp5mmlhfpcw4rj0scnyqmw02yvwpn4h6d40wyep3yew8l954sfl6ucqdqqcqzysxqrrssaayzylslcav0sr3c7237mwea5k67vk7t3j6pdmvnuuadxy0dsj5zalg6merxgndc74nc753lnuyx7t2sjecfpxp820r9use77n7vyqcpp7dlfy';
    expect(getZapValue(receipt(invoice)), 1000);
  });
}
