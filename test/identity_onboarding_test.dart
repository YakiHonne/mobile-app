import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/models/subscription_models.dart';
import 'package:yakihonne/views/widgets/identity_field.dart';

void main() {
  group('SubscriptionStatus identity fields', () {
    test('parses username, nip05 and onboarded', () {
      final s = SubscriptionStatus.fromJson(const {
        'username': 'alice',
        'nip05': {'name': 'alice', 'is_active': true},
        'onboarded': true,
      });

      expect(s.username, 'alice');
      expect(s.nip05.name, 'alice');
      expect(s.nip05.isActive, isTrue);
      expect(s.onboarded, isTrue);
    });

    test('defaults every identity field when the document omits them', () {
      final s = SubscriptionStatus.fromJson(const {'plan': 'basic'});

      expect(s.username, isEmpty);
      expect(s.nip05.name, isEmpty);
      expect(s.wallets, isEmpty);
      expect(s.onboarded, isFalse);
    });

    test('accepts wallets as bare strings or objects, stripping any domain',
        () {
      // The element shape is unconfirmed server-side, so both forms have to
      // survive — and neither should keep the @domain the row appends itself.
      final s = SubscriptionStatus.fromJson(const {
        'wallets': [
          'alice@wallet.yakihonne.com',
          {'username': 'bob'},
          {'name': 'carol@wallet.yakihonne.com'},
          {'unexpected': 'shape'},
          '',
        ],
      });

      expect(s.wallets, ['alice', 'bob', 'carol']);
    });
  });

  group('isValidUsername', () {
    test('accepts lowercase, digits, underscore and hyphen at 3-30 chars', () {
      expect(isValidUsername('abc'), isTrue);
      expect(isValidUsername('alice_99'), isTrue);
      expect(isValidUsername('a-b_c123'), isTrue);
      expect(isValidUsername('a' * 30), isTrue);
    });

    test('rejects what would be sharded into an unusable claim', () {
      expect(isValidUsername(''), isFalse);
      expect(isValidUsername('ab'), isFalse, reason: 'under 3');
      expect(isValidUsername('a' * 31), isFalse, reason: 'over 30');
      expect(isValidUsername('Alice'), isFalse, reason: 'uppercase');
      expect(isValidUsername('a.b'), isFalse, reason: 'punctuation');
      expect(isValidUsername('a b'), isFalse, reason: 'space');
      expect(isValidUsername('alice@yakihonne.com'), isFalse);
    });
  });

  group('addressStatusOf', () {
    test('owned wins over available', () {
      // The server reports a name this account already holds as unavailable;
      // there is nothing left to claim, so it must not render as taken.
      expect(
        addressStatusOf((available: false, owned: true, reason: 'taken')),
        AddressStatus.alreadySet,
      );
      expect(
        addressStatusOf((available: true, owned: true, reason: null)),
        AddressStatus.alreadySet,
      );
    });

    test('maps a free name to available and a claimed one to taken', () {
      expect(
        addressStatusOf((available: true, owned: false, reason: null)),
        AddressStatus.available,
      );
      expect(
        addressStatusOf((available: false, owned: false, reason: 'reserved')),
        AddressStatus.taken,
      );
    });
  });

  group('Yaki NIP-05 sheet seed', () {
    test('a name owned by the account is settled', () {
      expect(seedNip05Status('alice', 'alice'), AddressStatus.alreadySet);
    });

    test('a yakihonne address the account does not own stays editable', () {
      // IdentityField renders `alreadySet` read-only — settling this would
      // leave the user unable to type a different name.
      expect(seedNip05Status('bob', ''), AddressStatus.unchecked);
      expect(seedNip05Status('bob', 'alice'), AddressStatus.unchecked);
    });

    test('an empty field is never settled', () {
      expect(seedNip05Status('', ''), AddressStatus.unchecked);
    });
  });

  group('SubscriptionStatus.isActivePaidSub', () {
    // Gates the Yaki identity rows: a trial does not entitle a user to claim.
    final future = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 86400;
    final past = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 86400;

    test('a paid, non-trial subscription qualifies', () {
      expect(
        const SubscriptionStatus(active: true).isActivePaidSub,
        isTrue,
      );
    });

    test('an inactive account never qualifies', () {
      expect(const SubscriptionStatus().isActivePaidSub, isFalse);
    });

    test('a trial does not qualify, by flag or by unexpired period', () {
      expect(
        const SubscriptionStatus(active: true, inTrial: true).isActivePaidSub,
        isFalse,
        reason: 'explicit flag',
      );
      expect(
        SubscriptionStatus(active: true, trialEndsAt: future).isActivePaidSub,
        isFalse,
        reason: 'stale flag, trial period still running',
      );
    });

    test('an expired trial on an active account qualifies', () {
      expect(
        SubscriptionStatus(active: true, trialEndsAt: past).isActivePaidSub,
        isTrue,
      );
    });
  });

  group('shouldClaimUsernameOnUpdate', () {
    test('claims a free, legal name that is not yet held', () {
      expect(
        shouldClaimUsernameOnUpdate(
          claimed: '',
          pending: 'alice',
          status: AddressStatus.available,
        ),
        isTrue,
      );
    });

    test('never re-claims once the account holds a name', () {
      expect(
        shouldClaimUsernameOnUpdate(
          claimed: 'alice',
          pending: 'bob',
          status: AddressStatus.available,
        ),
        isFalse,
      );
    });

    test('skips anything not confirmed available', () {
      for (final s in [
        AddressStatus.taken,
        AddressStatus.checking,
        AddressStatus.unchecked,
      ]) {
        expect(
          shouldClaimUsernameOnUpdate(
            claimed: '',
            pending: 'alice',
            status: s,
          ),
          isFalse,
          reason: '$s must not claim',
        );
      }
    });

    test('skips an empty or illegal name', () {
      expect(
        shouldClaimUsernameOnUpdate(
          claimed: '',
          pending: '',
          status: AddressStatus.available,
        ),
        isFalse,
      );
      expect(
        shouldClaimUsernameOnUpdate(
          claimed: '',
          pending: 'Alice!',
          status: AddressStatus.available,
        ),
        isFalse,
      );
    });
  });
}
