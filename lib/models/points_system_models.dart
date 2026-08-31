// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:nostr_core_enhanced/utils/utils.dart';

import '../utils/utils.dart';
import 'subscription_models.dart';

class PointStandard {
  final String id;
  final int count;
  final int cooldown;
  final String displayName;
  final List<int> points;

  PointStandard({
    required this.id,
    required this.count,
    required this.cooldown,
    required this.displayName,
    required this.points,
  });

  factory PointStandard.fromMap({
    required MapEntry<String, dynamic> mapEntry,
  }) {
    return PointStandard(
      id: mapEntry.key,
      count: mapEntry.value['count'] as int? ?? 0,
      cooldown: mapEntry.value['cooldown'] as int? ?? 0,
      displayName: mapEntry.value['display_name'] as String? ?? '',
      points: List<int>.from(mapEntry.value['points']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'count': count,
      'cooldown': cooldown,
      'displayName': displayName,
      'points': points,
    };
  }
}

class PointSystemTier {
  final int volume;
  final int min;
  final int max;
  final String displayName;
  final List<String> description;
  final String icon;
  final int level;

  PointSystemTier({
    required this.volume,
    required this.min,
    required this.max,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.level,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'volume': volume,
      'min': min,
      'max': max,
      'displayName': displayName,
      'description': description,
    };
  }

  factory PointSystemTier.fromMap(Map<String, dynamic> map, int level) {
    final volume = map['volume'] as int;

    return PointSystemTier(
      volume: volume,
      min: map['min'] as int,
      max: map['max'] as int,
      displayName: map['display_name'] as String,
      description: List<String>.from(map['description']),
      level: level,
      icon: volume == 1
          ? Images.bronzeTier
          : volume == 2
              ? Images.silverTier
              : volume == 3
                  ? Images.goldTier
                  : Images.platinumTier,
    );
  }

  Map<String, dynamic> getStats() {
    final isUnlocked = level >= min;

    return {
      'isUnlocked': isUnlocked,
      'levelsToNextTier': isUnlocked ? 0 : min - level,
    };
  }
}

class PointAction {
  final String actionId;
  final num currentPoints;
  final num count;
  final num allTimePoints;
  final DateTime lastUpdated;
  final Map<String, dynamic>? extra;

  PointAction({
    required this.actionId,
    required this.currentPoints,
    required this.count,
    required this.allTimePoints,
    required this.lastUpdated,
    this.extra,
  });

  factory PointAction.fromMap(Map<String, dynamic> map) {
    return PointAction(
      actionId: map['action'] as String,
      currentPoints: map['current_points'] as num,
      count: map['count'] as num,
      allTimePoints: map['all_time_points'] as num,
      lastUpdated:
          DateTime.fromMillisecondsSinceEpoch(map['last_updated'] * 1000),
      extra: map['extra'] as Map<String, dynamic>?,
    );
  }
}

class UserGlobalStats {
  final String pubkey;
  final num xp;
  final DateTime lastUpdated;
  final Map<String, PointAction> actions;
  final Map<String, PointStandard> onetimePointStandards;
  final Map<String, PointStandard> repeatedPointStandards;
  final Map<String, PointSystemTier> pointSystemTiers;
  final num currentPoints;
  final DateTime currentPointsLastUpdated;
  final SubscriptionStatus subscriptionStatus;

  UserGlobalStats({
    required this.pubkey,
    required this.xp,
    required this.lastUpdated,
    required this.actions,
    required this.onetimePointStandards,
    required this.repeatedPointStandards,
    required this.pointSystemTiers,
    required this.currentPoints,
    required this.currentPointsLastUpdated,
    required this.subscriptionStatus,
  });

  factory UserGlobalStats.fromMap(Map<String, dynamic> map) {
    final userStat = map['user_stats'] ?? map;
    final Map<String, PointAction> actions = {};
    final Map<String, PointSystemTier> tiers = {};
    final List<PointStandard> pointStandards = List<PointStandard>.from(
      ((map['platform_standards'] as Map<String, dynamic>?) ?? {}).entries.map(
        (e) {
          return PointStandard.fromMap(mapEntry: e);
        },
      ),
    );

    for (final e in (userStat['actions'] as List? ?? [])) {
      final pointAction = PointAction.fromMap(e as Map<String, dynamic>);
      actions[pointAction.actionId] = pointAction;
    }

    for (final e in (map['tiers'] as List? ?? [])) {
      final tier = PointSystemTier.fromMap(
        e as Map<String, dynamic>,
        getCurrentLevel(userStat['xp'] as num? ?? 0),
      );

      tiers[tier.displayName] = tier;
    }

    final Map<String, PointStandard> oPS = {};
    final Map<String, PointStandard> rPS = {};

    for (final standard in pointStandards) {
      if (standard.count != 0) {
        oPS[standard.id] = standard;
      } else {
        rPS[standard.id] = standard;
      }
    }

    final currentPoints = userStat['current_points'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    return UserGlobalStats(
      pubkey: userStat['pubkey'] as String? ?? '',
      xp: userStat['xp'] as num? ?? 0,
      lastUpdated:
          DateTime.fromMillisecondsSinceEpoch(userStat['last_updated'] * 1000),
      actions: actions,
      onetimePointStandards: oPS,
      repeatedPointStandards: rPS,
      pointSystemTiers: tiers,
      currentPoints: currentPoints['points'],
      currentPointsLastUpdated: DateTime.fromMillisecondsSinceEpoch(
          currentPoints['last_updated'] * 1000),
      subscriptionStatus: SubscriptionStatus.fromJson(userStat),
    );
  }

  int currentLevel() => getCurrentLevel(xp);
}

class Chart {
  final PointStandard standard;
  final PointAction? action;

  Chart({
    required this.standard,
    this.action,
  });
}

class ZapsToPoints {
  final String pubkey;

  final int actionTimeStamp;
  final num sats;
  final String? eventId;

  ZapsToPoints({
    required this.pubkey,
    required this.actionTimeStamp,
    required this.sats,
    this.eventId,
  });

  bool shouldBeDeleted() {
    return (DateTime.now().toSecondsSinceEpoch() - actionTimeStamp) >= 120;
  }
}

// ── Points API response models ─────────────────────────────────────────────────

class PointsConfig {
  final int subscriptionBasicCost;
  final int subscriptionPremiumCost;
  final int paidNoteFree;
  final int paidNoteBasic;
  final int redeemCodeCost;
  final int redeemCodeLimit;
  final int redeemCodePeriodDays;
  final int redeemCodeMonthlyLimit;

  const PointsConfig({
    required this.subscriptionBasicCost,
    required this.subscriptionPremiumCost,
    required this.paidNoteFree,
    required this.paidNoteBasic,
    required this.redeemCodeCost,
    required this.redeemCodeLimit,
    required this.redeemCodePeriodDays,
    required this.redeemCodeMonthlyLimit,
  });

  factory PointsConfig.fromJson(Map<String, dynamic> j) {
    final sub = j['subscription'] as Map<String, dynamic>? ?? {};
    final pn = j['paid_note'] as Map<String, dynamic>? ?? {};
    final rc = j['redeem_code'] as Map<String, dynamic>? ?? {};
    return PointsConfig(
      subscriptionBasicCost: (sub['basic'] as num?)?.toInt() ?? 10000,
      subscriptionPremiumCost: (sub['premium'] as num?)?.toInt() ?? 20000,
      paidNoteFree: (pn['free'] as num?)?.toInt() ?? 800,
      paidNoteBasic: (pn['basic'] as num?)?.toInt() ?? 400,
      redeemCodeCost: (rc['cost'] as num?)?.toInt() ?? 1000,
      redeemCodeLimit: (rc['limit'] as num?)?.toInt() ?? 1,
      redeemCodePeriodDays: (rc['period_days'] as num?)?.toInt() ?? 7,
      redeemCodeMonthlyLimit: (rc['monthly_limit'] as num?)?.toInt() ?? 4,
    );
  }
}

class PointsPlanEligibility {
  final int cost;
  final bool eligible;

  const PointsPlanEligibility({required this.cost, required this.eligible});

  factory PointsPlanEligibility.fromJson(Map<String, dynamic> j) =>
      PointsPlanEligibility(
        cost: (j['cost'] as num?)?.toInt() ?? 0,
        eligible: j['eligible'] as bool? ?? false,
      );
}

class PointsEligibility {
  final int points;
  final PointsPlanEligibility basic;
  final PointsPlanEligibility premium;

  const PointsEligibility({
    required this.points,
    required this.basic,
    required this.premium,
  });

  factory PointsEligibility.fromJson(Map<String, dynamic> j) {
    final elig = j['eligibility'] as Map<String, dynamic>? ?? {};
    return PointsEligibility(
      points: (j['points'] as num?)?.toInt() ?? 0,
      basic: PointsPlanEligibility.fromJson(
          elig['basic'] as Map<String, dynamic>? ?? {}),
      premium: PointsPlanEligibility.fromJson(
          elig['premium'] as Map<String, dynamic>? ?? {}),
    );
  }

  bool eligibleFor(String planId) {
    if (planId == 'basic') {
      return basic.eligible;
    }
    if (planId == 'premium') {
      return premium.eligible;
    }
    return false;
  }

  int costFor(String planId) {
    if (planId == 'basic') {
      return basic.cost;
    }
    if (planId == 'premium') {
      return premium.cost;
    }
    return 0;
  }
}

class PointsRedeemCode {
  final String code;
  final int amount;
  final bool status;
  final String preImage;
  final int reservedAt;

  const PointsRedeemCode({
    required this.code,
    required this.amount,
    required this.status,
    required this.preImage,
    required this.reservedAt,
  });

  factory PointsRedeemCode.fromJson(Map<String, dynamic> j) => PointsRedeemCode(
        code: j['code'] as String? ?? '',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        status: j['status'] as bool? ?? false,
        preImage: j['preImage'] as String? ?? '',
        reservedAt: (j['reserved_at'] as num?)?.toInt() ?? 0,
      );
}
