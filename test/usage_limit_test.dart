import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/logic/subscription_cubit/subscription_cubit.dart';
import 'package:yakihonne/logic/subscription_cubit/usage_limit.dart';
import 'package:yakihonne/models/subscription_models.dart';
import 'package:yakihonne/utils/utils.dart';

UsageItem item({
  required int limit,
  required double percentage,
  int resetAt = 0,
}) =>
    UsageItem(
      key: kUsageKeyAskAi,
      label: 'AI Assistant',
      periodType: 'weekly',
      limit: limit,
      percentage: percentage,
      resetAt: resetAt,
    );

int inDays(int days) =>
    DateTime.now().add(Duration(days: days, minutes: 1)).millisecondsSinceEpoch ~/
    1000;

/// `canUpgrade` prefers subscriptionStatus.plan and falls back to
/// usageData.plan, which is the half a test can set without a network call.
void setPlan(String plan) =>
    subscriptionCubit.setUsageData(UsageData(plan: plan, items: const []));

UsageLimit exhausted() => classifyUsage(item(limit: 10, percentage: 100))!;

void main() {
  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.en);
    subscriptionCubit = SubscriptionCubit();
  });

  test('under the limit is not a quota rejection', () {
    expect(classifyUsage(item(limit: 10, percentage: 90)), isNull);
  });

  test('unlimited is never a quota rejection', () {
    expect(classifyUsage(item(limit: -1, percentage: 100)), isNull);
  });

  test('a missing item falls back to the generic error', () {
    expect(classifyUsage(null), isNull);
  });

  test('exhausted quota without a reset time omits the countdown', () {
    final limit = classifyUsage(item(limit: 10, percentage: 100));
    expect(limit?.kind, UsageLimitKind.exhausted);
    expect(limit!.message, 'Quota exceeded');
    expect(limit.resetsIn, isNull);
  });

  test('exhausted quota reports when it renews', () {
    final limit = classifyUsage(
      item(limit: 10, percentage: 100, resetAt: inDays(3)),
    );
    expect(limit!.message, 'Quota exceeded — renews in 3 days');
  });

  test('an elapsed reset time is not shown as a countdown', () {
    final limit = classifyUsage(
      item(limit: 10, percentage: 100, resetAt: inDays(-3)),
    );
    expect(limit!.resetsIn, isNull);
  });

  // percentage is 0-100, not a fraction — testing >= 1 would block everyone.
  test('a fraction-shaped percentage does not block', () {
    expect(classifyUsage(item(limit: 10, percentage: 1)), isNull);
  });

  test('locked is an upgrade prompt, not a limit message', () {
    final limit = classifyUsage(item(limit: 0, percentage: 0));
    expect(limit?.kind, UsageLimitKind.locked);
  });

  group('canUpgrade', () {
    test('premium is the top tier and gets no CTA', () {
      setPlan('premium');
      expect(exhausted().canUpgrade, isFalse);
    });

    // Basic is a paid plan here, but premium sits above it — the cohort most
    // likely to convert must keep the CTA.
    test('basic can upgrade', () {
      setPlan('basic');
      expect(exhausted().canUpgrade, isTrue);
    });

    test('trial-shaped and unrecognised plans can upgrade', () {
      for (final plan in ['trial', 'free', '', 'Basic']) {
        setPlan(plan);
        expect(exhausted().canUpgrade, isTrue, reason: 'plan=$plan');
      }
    });

    test('an unloaded subscription still offers the CTA', () {
      subscriptionCubit.reset();
      expect(exhausted().canUpgrade, isTrue);
    });
  });
}
