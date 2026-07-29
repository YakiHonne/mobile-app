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
    this.lastSubscription = 0,
    this.nextSubscription = 0,
    this.cancelAtPeriodEnd = false,
    this.pendingPlan = '',
    this.pendingPlanSince = 0,
    this.history = const [],
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
        lastSubscription: (j['last_subscription'] as num?)?.toInt() ?? 0,
        nextSubscription: (j['next_subscription'] as num?)?.toInt() ?? 0,
        cancelAtPeriodEnd: j['cancel_at_period_end'] as bool? ?? false,
        pendingPlan: j['pending_plan'] as String? ?? '',
        pendingPlanSince: (j['pending_plan_since'] as num?)?.toInt() ?? 0,
        history: (j['history'] as List<dynamic>? ?? [])
            .map(
              (e) => SubscriptionPaymentRecord.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
  }

  final String plan;
  final bool active;
  final bool inTrial;
  final int trialEndsAt;
  final bool accessBlocked;
  final String lastPaymentMethod;
  final int lastSubscription;
  final int nextSubscription;
  final bool cancelAtPeriodEnd;
  final String pendingPlan;
  final int pendingPlanSince;
  final List<SubscriptionPaymentRecord> history;

  bool get isTrialing {
    if (inTrial) {
      return true;
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return trialEndsAt > now;
  }

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
        lastSubscription,
        nextSubscription,
        cancelAtPeriodEnd,
        pendingPlan,
        pendingPlanSince,
        history,
      ];
}

class UserOnlineStats {
  const UserOnlineStats({
    required this.subscriptionStatus,
    required this.consumablePoints,
    required this.xp,
  });

  factory UserOnlineStats.fromJson(Map<String, dynamic> j) => UserOnlineStats(
        subscriptionStatus: SubscriptionStatus.fromJson(j),
        consumablePoints:
            (j['current_points'] as Map<String, dynamic>?)?['points'] as int? ??
                0,
        xp: j['xp'] as int? ?? 0,
      );

  final SubscriptionStatus subscriptionStatus;
  final int consumablePoints;
  final int xp;
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
  List<Object?> get props => [key, label, periodType, limit, percentage, resetAt];
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
