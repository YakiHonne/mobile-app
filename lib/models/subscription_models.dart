import 'package:equatable/equatable.dart';

typedef SubPlan = ({
  String id,
  String priceId,
  String name,
  String price,
  int satsRaw,
  String sats,
});

const List<SubPlan> kSubPlans = [
  (
    id: 'basic',
    priceId: 'price_1TXxor8f5pgfcSH1UwpipjP6',
    name: 'Basic',
    price: r'$9',
    satsRaw: 18000,
    sats: '18,000',
  ),
  (
    id: 'premium',
    priceId: 'price_1TXyHO8f5pgfcSH1W1jqzsuk',
    name: 'Premium',
    price: r'$19',
    satsRaw: 38000,
    sats: '38,000',
  ),
];

class SubscriptionStatus extends Equatable {
  const SubscriptionStatus({
    this.plan = 'basic',
    this.active = false,
    this.inTrial = false,
    this.trialEndsAt = 0,
    this.accessBlocked = false,
    this.lastPaymentMethod = '',
    this.lastPaymentMethodDisplay = '',
    this.lastSubscription = 0,
    this.nextSubscription = 0,
    this.cancelAtPeriodEnd = false,
    this.pendingPlan = '',
    this.pendingPlanSince = 0,
    this.pendingPriceId = '',
    this.pendingOriginalPriceId = '',
    this.pendingPlanViaPoints = false,
    this.lastSubscriptionRedeemed = false,
    this.lastReminderAt = 0,
    this.lastIapEventId = '',
    this.trialUsed = false,
    this.stripeCustomerId = '',
    this.stripeSubscriptionId = '',
    this.stripeScheduleId = '',
    this.airwallexCustomerId = '',
    this.airwallexPaymentSourceId = '',
    this.airwallexSubscriptionId = '',
    this.airwallexPendingChangePeriodStartsAt = '',
    this.androidPurchaseToken = '',
    this.appleOriginalTransactionId = '',
    this.history = const [],
    this.username = '',
    this.nip05 = const AccountNip05(),
    this.wallets = const [],
    this.onboarded = false,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> j) {
    final trialEndsAt = (j['trial_ends_at'] as num?)?.toInt() ?? 0;
    return SubscriptionStatus(
      plan: j['plan'] as String? ?? 'basic',
      active: j['active'] as bool? ?? false,
      inTrial: j['in_trial'] as bool? ??
          (trialEndsAt > DateTime.now().millisecondsSinceEpoch ~/ 1000),
      trialEndsAt: trialEndsAt,
      accessBlocked: j['access_blocked'] as bool? ?? false,
      lastPaymentMethod: j['last_payment_method'] as String? ?? '',
      lastPaymentMethodDisplay: j['last_payment_method_display'] as String? ?? '',
      lastSubscription: (j['last_subscription'] as num?)?.toInt() ?? 0,
      nextSubscription: (j['next_subscription'] as num?)?.toInt() ?? 0,
      cancelAtPeriodEnd: j['cancel_at_period_end'] as bool? ?? false,
      pendingPlan: j['pending_plan'] as String? ?? '',
      pendingPlanSince: (j['pending_plan_since'] as num?)?.toInt() ?? 0,
      pendingPriceId: j['pending_price_id'] as String? ?? '',
      pendingOriginalPriceId: j['pending_original_price_id'] as String? ?? '',
      pendingPlanViaPoints: j['pending_plan_via_points'] as bool? ?? false,
      lastSubscriptionRedeemed:
          j['last_subscription_redeemed'] as bool? ?? false,
      lastReminderAt: (j['last_reminder_at'] as num?)?.toInt() ?? 0,
      lastIapEventId: j['last_iap_event_id'] as String? ?? '',
      trialUsed: j['trial_used'] as bool? ?? false,
      stripeCustomerId: j['stripe_customer_id'] as String? ?? '',
      stripeSubscriptionId: j['stripe_subscription_id'] as String? ?? '',
      stripeScheduleId: j['stripe_schedule_id'] as String? ?? '',
      airwallexCustomerId: j['airwallex_customer_id'] as String? ?? '',
      airwallexPaymentSourceId: j['airwallex_payment_source_id'] as String? ?? '',
      airwallexSubscriptionId: j['airwallex_subscription_id'] as String? ?? '',
      airwallexPendingChangePeriodStartsAt:
          j['airwallex_pending_change_period_starts_at']?.toString() ?? '',
      androidPurchaseToken: j['android_purchase_token'] as String? ?? '',
      appleOriginalTransactionId:
          j['apple_original_transaction_id'] as String? ?? '',
      history: (j['history'] as List<dynamic>? ?? [])
          .map(
            (e) => SubscriptionPaymentRecord.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      username: j['username'] as String? ?? '',
      nip05: j['nip05'] != null
          ? AccountNip05.fromJson(j['nip05'] as Map<String, dynamic>)
          : const AccountNip05(),
      wallets: (j['wallets'] as List<dynamic>? ?? [])
          .map(
            // Element shape is unconfirmed, so accept a bare name or an
            // object carrying one, and drop anything that yields neither.
            (e) => e is Map
                ? (e['username'] ?? e['name'] ?? '').toString()
                : e.toString(),
          )
          .map((n) => n.split('@').first)
          .where((n) => n.isNotEmpty)
          .toList(),
      onboarded: j['onboarded'] as bool? ?? false,
    );
  }

  final String plan;
  final bool active;
  final bool inTrial;
  final int trialEndsAt;
  final bool accessBlocked;
  final String lastPaymentMethod;
  final String lastPaymentMethodDisplay;
  final int lastSubscription;
  final int nextSubscription;
  final bool cancelAtPeriodEnd;
  final String pendingPlan;
  final int pendingPlanSince;
  final String pendingPriceId;
  final String pendingOriginalPriceId;
  final bool pendingPlanViaPoints;
  final bool lastSubscriptionRedeemed;
  final int lastReminderAt;
  final String lastIapEventId;
  final bool trialUsed;
  final String stripeCustomerId;
  final String stripeSubscriptionId;
  final String stripeScheduleId;
  final String airwallexCustomerId;
  final String airwallexPaymentSourceId;
  final String airwallexSubscriptionId;
  final String airwallexPendingChangePeriodStartsAt;
  final String androidPurchaseToken;
  final String appleOriginalTransactionId;
  final List<SubscriptionPaymentRecord> history;

  /// Claimed `yakihonne.com/<username>` handle, empty when never claimed.
  final String username;
  final AccountNip05 nip05;

  /// Lightning wallet names owned by this account, bare (no `@domain`).
  final List<String> wallets;
  final bool onboarded;

  bool get isTrialing {
    if (inTrial) {
      return true;
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return trialEndsAt > now;
  }

  /// A paid subscription, trials excluded. Gates the features that a trial is
  /// not entitled to — [isTrialing] rather than [inTrial], so a stale flag with
  /// an unexpired trial period still reads as a trial.
  bool get isActivePaidSub => active && !isTrialing;

  int get trialDaysRemaining {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = trialEndsAt - now;
    return diff > 0 ? (diff / 86400).ceil() : 0;
  }

  bool get hasPendingChange => pendingPlan.isNotEmpty;

  @override
  List<Object?> get props => [
        plan,
        active,
        inTrial,
        trialEndsAt,
        accessBlocked,
        lastPaymentMethod,
        lastPaymentMethodDisplay,
        lastSubscription,
        nextSubscription,
        cancelAtPeriodEnd,
        pendingPlan,
        pendingPlanSince,
        pendingPriceId,
        pendingOriginalPriceId,
        pendingPlanViaPoints,
        lastSubscriptionRedeemed,
        lastReminderAt,
        lastIapEventId,
        trialUsed,
        stripeCustomerId,
        stripeSubscriptionId,
        stripeScheduleId,
        airwallexCustomerId,
        airwallexPaymentSourceId,
        airwallexSubscriptionId,
        airwallexPendingChangePeriodStartsAt,
        androidPurchaseToken,
        appleOriginalTransactionId,
        history,
        username,
        nip05,
        wallets,
        onboarded,
      ];
}

/// The account's NIP-05 claim. [name] is bare — the domain is always
/// `yakihonne.com`, so it is not carried here.
class AccountNip05 extends Equatable {
  const AccountNip05({this.isActive = false, this.name = ''});

  factory AccountNip05.fromJson(Map<String, dynamic> j) => AccountNip05(
        isActive: j['is_active'] as bool? ?? false,
        name: j['name'] as String? ?? '',
      );

  final bool isActive;
  final String name;

  @override
  List<Object?> get props => [isActive, name];
}

class UsageItem extends Equatable {
  const UsageItem({
    required this.key,
    required this.label,
    required this.periodType,
    required this.limit,
    required this.percentage,
    required this.resetAt,
  });

  factory UsageItem.fromJson(String key, Map<String, dynamic> j) => UsageItem(
        key: key,
        label: j['label'] as String? ?? key,
        periodType: j['period_type'] as String? ?? '',
        limit: (j['limit'] as num?)?.toInt() ?? 0,
        percentage: (j['percentage'] as num?)?.toDouble() ?? 0,
        resetAt: (j['reset_at'] as num?)?.toInt() ?? 0,
      );

  final String key;
  final String label;
  final String periodType;
  final int limit;
  final double percentage;
  final int resetAt;

  bool get isUnlimited => limit == -1;
  bool get isLocked => limit == 0;

  @override
  List<Object?> get props =>
      [key, label, periodType, limit, percentage, resetAt];
}

class UsageData extends Equatable {
  const UsageData({required this.plan, required this.items});

  factory UsageData.fromJson(Map<String, dynamic> j) {
    final usageMap = j['usage'] as Map<String, dynamic>? ?? {};
    final items = _kUsageOrder
        .where(usageMap.containsKey)
        .map((k) => UsageItem.fromJson(k, usageMap[k] as Map<String, dynamic>))
        .toList();
    return UsageData(
      plan: j['plan'] as String? ?? '',
      items: items,
    );
  }

  final String plan;
  final List<UsageItem> items;

  @override
  List<Object?> get props => [plan, items];
}

const _kUsageOrder = [
  'chat-articles',
  'second-reader',
  'energy-mapper',
  'translate-lt',
  'wallet-creation',
];

class SubscriptionPaymentRecord extends Equatable {
  const SubscriptionPaymentRecord({
    this.plan = '',
    this.lastPaymentMethod = '',
    this.lastSubscription = 0,
  });

  factory SubscriptionPaymentRecord.fromJson(Map<String, dynamic> j) =>
      SubscriptionPaymentRecord(
        plan: j['plan'] as String? ?? '',
        lastPaymentMethod: j['last_payment_method'] as String? ?? '',
        lastSubscription: (j['last_subscription'] as num?)?.toInt() ?? 0,
      );

  final String plan;
  final String lastPaymentMethod;
  final int lastSubscription;

  @override
  List<Object?> get props => [plan, lastPaymentMethod, lastSubscription];
}
