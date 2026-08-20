import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/models/creator_subscription_models.dart';

void main() {
  test('amounts are rendered without dividing', () {
    expect(formatSubscriptionAmount(2, 'sats'), '2 sats');
    expect(formatSubscriptionAmount(11.99, 'usd'), 'USD 11.99');
    expect(formatSubscriptionAmount(12, 'myr'), 'MYR 12.00');
    // legacy record with a genuinely unknown amount
    expect(formatSubscriptionAmount(0, ''), '—');
  });

  test('lightning entries parse without subscription_id / customer_id', () {
    final p = SubscriptionPayment.fromMap({
      'invoice_id': '',
      'amount': 2,
      'currency': 'sats',
      'status': 'paid',
      'payment_method': 'lightning',
      'subscribed_at': 1781776466,
      'hosted_invoice_url': '',
      'provider': 'lightning',
    });

    expect(p.isPaid, true);
    expect(p.formattedAmount, '2 sats');
    expect(p.hostedInvoiceUrl, '');
  });

  test('canceling stays active and exposes an end date', () {
    final s = SubscriberSubscription.fromMap({
      'creator_pubkey': 'abc',
      'active': true,
      'status': 'active',
      'display_status': 'canceling',
      'amount': 11.99,
      'currency': 'usd',
      'cancel_at': 1787544603,
      'next_subscription': 1787544603,
      'has_stripe': true,
      'history': [],
    });

    expect(s.isActive, true);
    expect(s.isCanceling, true);
    expect(s.endsAt, 1787544603);
  });

  test('expired lightning subscription is inactive and has no stripe portal',
      () {
    final s = SubscriberSubscription.fromMap({
      'creator_pubkey': 'abc',
      'display_status': 'expired',
      'amount': 2,
      'currency': 'sats',
      'has_stripe': false,
    });

    expect(s.isActive, false);
    expect(s.hasStripe, false);
    expect(s.history, isEmpty);
  });
}
