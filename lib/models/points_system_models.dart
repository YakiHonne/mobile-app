// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:nostr_core_enhanced/utils/utils.dart';

import '../utils/utils.dart';

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
    final isUnlocked = level >= min && (max == -1 || level <= max);

    return {
      'isUnlocked': isUnlocked,
      'levelsToNextTier': isUnlocked ? 0 : min - level,
    };
  }
}

class PointAction {
  final String actionId;
  final int currentPoints;
  final int count;
  final int allTimePoints;
  final DateTime lastUpdated;

  PointAction({
    required this.actionId,
    required this.currentPoints,
    required this.count,
    required this.allTimePoints,
    required this.lastUpdated,
  });

  factory PointAction.fromMap(Map<String, dynamic> map) {
    return PointAction(
      actionId: map['action'] as String,
      currentPoints: map['current_points'] as int,
      count: map['count'] as int,
      allTimePoints: map['all_time_points'] as int,
      lastUpdated:
          DateTime.fromMillisecondsSinceEpoch(map['last_updated'] * 1000),
    );
  }
}

class UserGlobalStats {
  final String pubkey;
  final int xp;
  final DateTime lastUpdated;
  final Map<String, PointAction> actions;
  final Map<String, PointStandard> onetimePointStandards;
  final Map<String, PointStandard> repeatedPointStandards;
  final Map<String, PointSystemTier> pointSystemTiers;
  final int currentPoints;
  final DateTime currentPointsLastUpdated;

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
  });

  factory UserGlobalStats.fromMap(Map<String, dynamic> map) {
    final userStat = map['user_stats'];
    final Map<String, PointAction> actions = {};
    final Map<String, PointSystemTier> tiers = {};
    final List<PointStandard> pointStandards = List<PointStandard>.from(
      map['platform_standards'].entries.map(
        (e) {
          return PointStandard.fromMap(mapEntry: e);
        },
      ),
    );

    for (final e in userStat['actions']) {
      final pointAction = PointAction.fromMap(e as Map<String, dynamic>);
      actions[pointAction.actionId] = pointAction;
    }

    for (final e in map['tiers']) {
      final tier = PointSystemTier.fromMap(
        e as Map<String, dynamic>,
        getCurrentLevel(userStat['xp'] as int? ?? 0),
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

    return UserGlobalStats(
      pubkey: userStat['pubkey'] as String? ?? '',
      xp: userStat['xp'] as int? ?? 0,
      lastUpdated:
          DateTime.fromMillisecondsSinceEpoch(userStat['last_updated'] * 1000),
      actions: actions,
      onetimePointStandards: oPS,
      repeatedPointStandards: rPS,
      pointSystemTiers: tiers,
      currentPoints: userStat['current_points']['points'],
      currentPointsLastUpdated: DateTime.fromMillisecondsSinceEpoch(
          userStat['current_points']['last_updated'] * 1000),
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
