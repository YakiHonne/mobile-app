import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/models/identity_models.dart';

void main() {
  test('username deeplink parsing', () {
    expect(usernameFromYakiUrl('https://yakihonne.com/alice'), 'alice');
    expect(usernameFromYakiUrl('https://yakihonne.com/alice?ref=x'), 'alice');
    expect(usernameFromYakiUrl('https://yakihonne.com/alice/'), 'alice');

    // Not usernames.
    expect(usernameFromYakiUrl('https://yakihonne.com/'), null);
    expect(usernameFromYakiUrl('https://yakihonne.com/article/naddr1abc'), null);
    expect(usernameFromYakiUrl('https://example.com/alice'), null);
    expect(usernameFromYakiUrl('https://yakihonne.com/Alice'), null);
    expect(usernameFromYakiUrl('https://yakihonne.com/ab'), null);
    expect(
      usernameFromYakiUrl(
        'https://yakihonne.com/npub1${'q' * 58}',
      ),
      null,
    );
  });
}
