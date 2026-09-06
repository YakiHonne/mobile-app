import 'dart:async';

import '../../models/subscription_models.dart';
import '../../repositories/http_functions_repository.dart';
import '../../utils/utils.dart';

/// Usage keys as returned by `/api/v1/usage`.
const kUsageKeyAskAi = 'chat-articles';
const kUsageKeySecondReader = 'second-reader';
const kUsageKeyEnergyMapper = 'energy-mapper';

enum UsageLimitKind { exhausted, locked }

class UsageLimit {
  const UsageLimit(this.kind, this.message, {this.resetsIn});
  final UsageLimitKind kind;
  final String message;

  /// Humanised time until the quota renews, when the server reports one.
  final String? resetsIn;

  /// Anything that isn't already the top tier can upgrade. Basic is a paid
  /// plan here but premium sits above it, so basic users keep the CTA — an
  /// allowlist or a "paid tiers" denylist would hide it from the cohort most
  /// likely to convert.
  bool get canUpgrade {
    final plan = subscriptionCubit.state.subscriptionStatus?.plan ??
        subscriptionCubit.state.usageData?.plan ??
        '';
    return plan.toLowerCase() != 'premium';
  }
}

/// Reads the cached usage snapshot. Unknown usage allows the action — the
/// server stays the enforcer and [checkUsageLimit] catches the rejection.
UsageLimit? usageLimitFor(String key) =>
    classifyUsage(_itemFor(subscriptionCubit.state.usageData, key));

UsageItem? _itemFor(UsageData? data, String key) {
  for (final item in data?.items ?? const <UsageItem>[]) {
    if (item.key == key) {
      return item;
    }
  }
  return null;
}

bool isUsageBlocked(String key) => usageLimitFor(key) != null;

/// Refreshes the cached snapshot after a request consumed quota, so the gates
/// reflect the spend without waiting for the subscription screen.
void refreshUsageAfterCall() => unawaited(subscriptionCubit.refreshUsage());

/// Re-checks usage after a request failed and reports whether the failure was
/// the plan's quota rather than a generic error. Classifies only a confirmed
/// fresh fetch — a failed refresh would leave a stale snapshot that could
/// report an already-reset quota as spent.
Future<UsageLimit?> checkUsageLimit(String key) async {
  final data = await HttpFunctionsRepository.subscriptionGetUsage();
  if (data == null) {
    return null;
  }
  subscriptionCubit.setUsageData(data);
  return classifyUsage(_itemFor(data, key));
}

/// Classifies a usage item. Null means the feature is available, so the caller
/// should proceed (or fall back to its generic error).
UsageLimit? classifyUsage(UsageItem? item) {
  if (item == null || item.isUnlimited) {
    return null;
  }
  if (item.isLocked) {
    return UsageLimit(UsageLimitKind.locked, t.sub_usage_upgrade_prompt);
  }
  if (item.percentage >= 100) {
    final resets = _resetsIn(item);
    return UsageLimit(
      UsageLimitKind.exhausted,
      resets == null
          ? t.usage_quota_exceeded
          : t.usage_quota_exceeded_renews(time: resets),
      resetsIn: resets,
    );
  }
  return null;
}

String? _resetsIn(UsageItem item) {
  if (item.resetAt == 0) {
    return null;
  }
  final remaining = DateTime.fromMillisecondsSinceEpoch(item.resetAt * 1000)
      .difference(DateTime.now());
  if (remaining.isNegative) {
    return null;
  }

  final days = remaining.inDays;
  if (days >= 1) {
    return t.usage_renews_days(count: days);
  }
  final hours = remaining.inHours;
  if (hours >= 1) {
    return t.usage_renews_hours(count: hours);
  }
  return t.usage_renews_soon;
}
