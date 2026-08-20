import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/views/dm_view/widgets/dm_redeem_widget.dart';

void main() {
  test('extracts the code from a lottery reward message', () {
    const message = '🎉 You won a YakiHonne lottery reward of 2100 sats!\n\n'
        'Redeem this code in the app: YR-3W52MXKP';

    expect(extractRedeemCode(message), 'YR-3W52MXKP');
  });

  test('returns null for plain chat and gift tokens', () {
    expect(extractRedeemCode('hey, are you around?'), null);
    expect(extractRedeemCode('eyJhbGc.eyJzdWIi.SflKxwRJ'), null);
    expect(extractRedeemCode(''), null);
  });
}
