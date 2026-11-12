import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/logic/checkout_cubit/checkout_cubit.dart';
import 'package:yakihonne/logic/checkout_cubit/subscription_billing_policy.dart';
import 'package:yakihonne/models/app_models/pricing_plan_model.dart';
import 'package:yakihonne/models/subscription_models.dart';

class _Signer extends Fake implements EventSigner {
  _Signer(this.pubkey);
  final String pubkey;
  @override
  bool canSign() => true;
  @override
  String getPublicKey() => pubkey;
}

const PricingPlan _plan = (
  id: 'fixture',
  plan: 'basic',
  priceId: '',
  productId: '',
  iapProductId: '',
  yakiproIapProductId: '',
  paymentProvider: 'stripe',
  name: 'Basic',
  price: r'$9',
  satsRaw: 0,
  sats: '0',
  period: '/month',
  desc: '',
  highlighted: false,
  features: <({String text, bool dim})>[],
);

void main() {
  setUp(() => currentSigner = _Signer('fixture-account'));
  tearDown(() => currentSigner = null);

  test('desktop selects external billing regardless of store build flag', () {
    expect(
        usesNativeSubscriptionStore(desktop: true, iapEnabled: true), isFalse);
    expect(
        usesNativeSubscriptionStore(desktop: true, iapEnabled: false), isFalse);
    expect(
        usesNativeSubscriptionStore(desktop: false, iapEnabled: true), isTrue);
    expect(usesNativeSubscriptionStore(desktop: false, iapEnabled: false),
        isFalse);
  });

  for (final method in ['iap', 'stripe']) {
    test('active $method prevents desktop card checkout', () async {
      var requests = 0;
      final cubit = CheckoutCubit(
        plan: _plan,
        method: CheckoutMethod.stripe,
        desktopStatusLoader: () async =>
            SubscriptionStatus(active: true, lastPaymentMethod: method),
        stripeLinkLoader: (_) async {
          requests++;
          return 'https://example.test/checkout';
        },
        stripeLauncher: (_) async => true,
      );
      addTearDown(cubit.close);
      await cubit.start();
      expect(cubit.state.phase, CheckoutPhase.failed);
      expect(requests, 0);
    });
  }

  test('opens a secure checkout and reports browser handoff', () async {
    Uri? launched;
    final cubit = CheckoutCubit(
      plan: _plan,
      method: CheckoutMethod.stripe,
      desktopStatusLoader: () async => const SubscriptionStatus(),
      stripeLinkLoader: (_) async => 'https://example.test/checkout',
      stripeLauncher: (uri) async {
        launched = uri;
        return true;
      },
    );
    addTearDown(cubit.close);
    await cubit.start();
    expect(launched?.host, 'example.test');
    expect(cubit.state.phase, CheckoutPhase.handedOff);
  });

  test('failed browser launch does not claim checkout opened', () async {
    final cubit = CheckoutCubit(
      plan: _plan,
      method: CheckoutMethod.stripe,
      desktopStatusLoader: () async => const SubscriptionStatus(),
      stripeLinkLoader: (_) async => 'https://example.test/checkout',
      stripeLauncher: (_) async => false,
    );
    addTearDown(cubit.close);
    await cubit.start();
    expect(cubit.state.phase, CheckoutPhase.failed);
  });

  test('account change while checking status prevents checkout', () async {
    var requested = false;
    final cubit = CheckoutCubit(
      plan: _plan,
      method: CheckoutMethod.stripe,
      desktopStatusLoader: () async {
        currentSigner = _Signer('different-account');
        return const SubscriptionStatus();
      },
      stripeLinkLoader: (_) async {
        requested = true;
        return null;
      },
    );
    addTearDown(cubit.close);
    await cubit.start();
    expect(cubit.state.phase, CheckoutPhase.failed);
    expect(requested, isFalse);
  });
  test('missing status fails closed before requesting a link', () async {
    var requested = false;
    final cubit = CheckoutCubit(
      plan: _plan,
      method: CheckoutMethod.stripe,
      desktopStatusLoader: () async => null,
      stripeLinkLoader: (_) async {
        requested = true;
        return null;
      },
    );
    addTearDown(cubit.close);
    await cubit.start();
    expect(cubit.state.phase, CheckoutPhase.failed);
    expect(requested, isFalse);
  });

  test('insecure link is never launched', () async {
    var launched = false;
    final cubit = CheckoutCubit(
      plan: _plan,
      method: CheckoutMethod.stripe,
      desktopStatusLoader: () async => const SubscriptionStatus(),
      stripeLinkLoader: (_) async => 'http://example.test/checkout',
      stripeLauncher: (_) async {
        launched = true;
        return true;
      },
    );
    addTearDown(cubit.close);
    await cubit.start();
    expect(cubit.state.phase, CheckoutPhase.failed);
    expect(launched, isFalse);
  });
}
