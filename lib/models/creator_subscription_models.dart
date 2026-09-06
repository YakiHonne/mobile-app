// ignore_for_file: sort_constructors_first

class CreatorProvider {
  const CreatorProvider({
    required this.pubkey,
    required this.url,
  });

  final String pubkey;
  final String url;
}

/// One payment row from `/subscriber/subscriptions`. Lightning entries omit
/// `subscription_id` / `customer_id` / `hosted_invoice_url` entirely.
class SubscriptionPayment {
  const SubscriptionPayment({
    required this.invoiceId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.subscribedAt,
    required this.hostedInvoiceUrl,
    required this.provider,
    required this.creatorPubkey,
  });

  final String invoiceId;
  final num amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final int subscribedAt;
  final String hostedInvoiceUrl;
  final String provider;
  final String creatorPubkey;

  bool get isPaid => status == 'paid';

  /// `amount: 0` + empty currency is a legacy record with a genuinely unknown
  /// amount — render a dash, never "0".
  String get formattedAmount => formatSubscriptionAmount(amount, currency);

  factory SubscriptionPayment.fromMap(Map<String, dynamic> map) {
    return SubscriptionPayment(
      invoiceId: map['invoice_id'] as String? ?? '',
      amount: map['amount'] as num? ?? 0,
      currency: map['currency'] as String? ?? '',
      status: map['status'] as String? ?? '',
      paymentMethod: map['payment_method'] as String? ?? '',
      subscribedAt: (map['subscribed_at'] as num?)?.toInt() ?? 0,
      hostedInvoiceUrl: map['hosted_invoice_url'] as String? ?? '',
      provider: map['provider'] as String? ?? '',
      creatorPubkey: map['creator_pubkey'] as String? ?? '',
    );
  }
}

class SubscriberSubscription {
  const SubscriberSubscription({
    required this.creatorPubkey,
    required this.displayStatus,
    required this.interval,
    required this.amount,
    required this.currency,
    required this.cancelAt,
    required this.nextSubscription,
    required this.hasStripe,
    required this.history,
  });

  final String creatorPubkey;

  /// Use this, never the raw `status`: a cancelled-but-still-running Stripe
  /// subscription keeps `status: "active"`.
  final String displayStatus;
  final String interval;
  final num amount;
  final String currency;
  final int cancelAt;
  final int nextSubscription;
  final bool hasStripe;
  final List<SubscriptionPayment> history;

  bool get isCanceling => displayStatus == 'canceling';
  bool get isActive => displayStatus == 'active' || isCanceling;
  bool get hasPaymentIssue =>
      displayStatus == 'past_due' ||
      displayStatus == 'unpaid' ||
      displayStatus == 'incomplete';

  /// The date a canceling subscription stops working.
  int get endsAt => cancelAt != 0 ? cancelAt : nextSubscription;

  String get formattedAmount => formatSubscriptionAmount(amount, currency);

  factory SubscriberSubscription.fromMap(Map<String, dynamic> map) {
    return SubscriberSubscription(
      creatorPubkey: map['creator_pubkey'] as String? ?? '',
      displayStatus: map['display_status'] as String? ?? '',
      interval: map['interval'] as String? ?? '',
      amount: map['amount'] as num? ?? 0,
      currency: map['currency'] as String? ?? '',
      cancelAt: (map['cancel_at'] as num?)?.toInt() ?? 0,
      nextSubscription: (map['next_subscription'] as num?)?.toInt() ?? 0,
      hasStripe: map['has_stripe'] as bool? ?? false,
      history: (map['history'] as List<dynamic>? ?? [])
          .map((e) => SubscriptionPayment.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Amounts arrive in major units already — never divide.
String formatSubscriptionAmount(num amount, String currency) {
  if (amount == 0 && currency.isEmpty) {
    return '—';
  }
  if (currency == 'sats') {
    return '$amount sats';
  }
  // ponytail: `CODE 12.00` matches the existing plan card style; swap for
  // NumberFormat.currency if per-locale symbols are ever asked for.
  return '${currency.toUpperCase()} ${amount.toStringAsFixed(2)}';
}

class CreatorPlan {
  const CreatorPlan({
    required this.method,
    required this.id,
    required this.name,
    required this.amount,
    required this.interval,
    required this.currency,
  });

  final String method;
  final String id;
  final String name;
  final String amount;
  final String interval;
  final String currency;
}

class CreatorMethod {
  const CreatorMethod({
    required this.id,
    required this.displayName,
    required this.plans,
  });

  final String id;
  final String displayName;
  final List<CreatorPlan> plans;
}

class CreatorSubscriptionData {
  const CreatorSubscriptionData({
    required this.gatewayPubkey,
    required this.methods,
  });

  final String gatewayPubkey;
  final List<CreatorMethod> methods;

  bool get hasPlans => methods.isNotEmpty;

  static CreatorSubscriptionData fromKind30164Tags(List<List<String>> tags) {
    final methodsMap = <String, Map<String, dynamic>>{};
    final prices = <Map<String, String>>[];
    final currencies = <String, String>{};
    String gatewayPubkey = '';

    for (final tag in tags) {
      if (tag.isEmpty) {
        continue;
      }
      final key = tag[0];
      final values = tag.sublist(1);

      if (key == 'gateway' && values.isNotEmpty) {
        gatewayPubkey = values[0];
      } else if (key == 'method' && values.length >= 2) {
        methodsMap[values[0]] = {
          'id': values[0],
          'display_name': values[1],
        };
      } else if (key == 'price' && values.length >= 5) {
        prices.add({
          'method': values[0],
          'id': values[1],
          'name': values[2],
          'amount': values[3],
          'interval': values[4],
        });
      } else if (key == 'currency' && values.length >= 2) {
        currencies[values[0]] = values[1];
      }
    }

    final methods = methodsMap.entries.map((entry) {
      final methodId = entry.key;
      final plans = prices
          .where((p) => p['method'] == methodId)
          .map(
            (p) => CreatorPlan(
              method: methodId,
              id: p['id']!,
              name: p['name']!,
              amount: p['amount']!,
              interval: p['interval']!,
              currency: currencies[methodId] ?? '',
            ),
          )
          .toList();

      return CreatorMethod(
        id: methodId,
        displayName: entry.value['display_name'] as String,
        plans: plans,
      );
    }).toList();

    return CreatorSubscriptionData(
      gatewayPubkey: gatewayPubkey,
      methods: methods,
    );
  }
}
