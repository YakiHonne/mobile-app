import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/points_management_cubit/points_management_cubit.dart';
import '../../../models/points_system_models.dart';
import '../../../utils/utils.dart';
import '../../widgets/modal_with_blur.dart';
import 'consumable_points_view.dart';
import 'income_chart.dart';
import 'one_time_reward_container.dart';
import 'repeated_reward_container.dart';
import 'tier_view.dart';

class PointsStatContainers extends StatelessWidget {
  const PointsStatContainers({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              _pointsSystem(context),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              if (isTablet)
                const SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ChatContainer()),
                      SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            XpContainer(),
                            SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            PointContainer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                const SliverToBoxAdapter(
                  child: XpContainer(),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
                const SliverToBoxAdapter(child: PointContainer()),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
                const SliverToBoxAdapter(child: ChatContainer()),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              SliverToBoxAdapter(
                child: Text(
                  context.t.oneTimeRewards.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              if (isTablet) _itemsGrid(state) else _itemsList(state),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              SliverToBoxAdapter(
                child: Text(
                  context.t.repeatedRewards.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              if (isTablet) _itemsGrid2(state) else _itemsList2(state),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kBottomNavigationBarHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SliverList _itemsList2(PointsManagementState state) {
    return SliverList.separated(
      itemBuilder: (context, index) {
        final standard = state.userGlobalStats!.repeatedPointStandards.values
            .toList()[index];
        final standardAction = state.userGlobalStats!.actions[standard.id];

        int cooldownVal = 0;
        int collectedPoints = 0;

        if (standard.cooldown == 0) {
          cooldownVal = -1;
          if (standardAction != null) {
            collectedPoints = standardAction.allTimePoints;
          }
        } else {
          if (standardAction != null) {
            final actionUnixTimeStamp =
                standardAction.lastUpdated.toSecondsSinceEpoch() +
                    standard.cooldown;
            final currentUnixTimeStamp = currentUnixTimestampSeconds();

            if (actionUnixTimeStamp > currentUnixTimeStamp) {
              final remaining = actionUnixTimeStamp - currentUnixTimeStamp;

              cooldownVal = Duration(seconds: remaining).inMinutes;
            }

            collectedPoints = standardAction.allTimePoints;
          }
        }

        return RepeatedReward(
          standard: standard,
          cooldownVal: cooldownVal,
          collectedPoints: collectedPoints,
        );
      },
      itemCount: state.userGlobalStats!.repeatedPointStandards.values.length,
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
    );
  }

  SliverMasonryGrid _itemsGrid2(PointsManagementState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: kDefaultPadding / 2,
      crossAxisSpacing: kDefaultPadding / 2,
      itemBuilder: (context, index) {
        final standard = state.userGlobalStats!.repeatedPointStandards.values
            .toList()[index];
        final standardAction = state.userGlobalStats!.actions[standard.id];

        int cooldownVal = 0;
        int collectedPoints = 0;

        if (standard.cooldown == 0) {
          cooldownVal = -1;
          if (standardAction != null) {
            collectedPoints = standardAction.allTimePoints;
          }
        } else {
          if (standardAction != null) {
            final actionUnixTimeStamp =
                standardAction.lastUpdated.toSecondsSinceEpoch() +
                    standard.cooldown;
            final currentUnixTimeStamp = currentUnixTimestampSeconds();

            if (actionUnixTimeStamp > currentUnixTimeStamp) {
              final remaining = actionUnixTimeStamp - currentUnixTimeStamp;

              cooldownVal = Duration(seconds: remaining).inMinutes;
            }

            collectedPoints = standardAction.allTimePoints;
          }
        }

        return RepeatedReward(
          standard: standard,
          cooldownVal: cooldownVal,
          collectedPoints: collectedPoints,
        );
      },
      childCount: state.userGlobalStats!.repeatedPointStandards.values.length,
    );
  }

  SliverList _itemsList(PointsManagementState state) {
    return SliverList.separated(
      itemBuilder: (context, index) {
        final standard =
            state.userGlobalStats!.onetimePointStandards.values.toList()[index];
        final standardAction = state.userGlobalStats!.actions[standard.id];

        final isCompleted = standard.count == standardAction?.count;

        final remainingAttempts = standard.count - (standardAction?.count ?? 0);

        int total = 0;
        int count = 0;

        if (standardAction != null) {
          total = standardAction.allTimePoints;
          count = standardAction.allTimePoints;
        } else {
          total = standard.points.first;
        }

        return OneTimeRewardContainer(
          standard: standard,
          count: count,
          total: total,
          isCompleted: isCompleted,
          standardAction: standardAction,
          remainingAttempts: remainingAttempts,
        );
      },
      itemCount: state.userGlobalStats!.onetimePointStandards.values.length,
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
    );
  }

  SliverMasonryGrid _itemsGrid(PointsManagementState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: kDefaultPadding / 2,
      crossAxisSpacing: kDefaultPadding / 2,
      itemBuilder: (context, index) {
        final standard =
            state.userGlobalStats!.onetimePointStandards.values.toList()[index];
        final standardAction = state.userGlobalStats!.actions[standard.id];

        final isCompleted = standard.count == standardAction?.count;

        final remainingAttempts = standard.count - (standardAction?.count ?? 0);

        int total = 0;
        int count = 0;

        if (standardAction != null) {
          total = standardAction.allTimePoints;
          count = standardAction.allTimePoints;
        } else {
          total = standard.points.first;
        }

        return OneTimeRewardContainer(
          standard: standard,
          count: count,
          total: total,
          isCompleted: isCompleted,
          standardAction: standardAction,
          remainingAttempts: remainingAttempts,
        );
      },
      childCount: state.userGlobalStats!.onetimePointStandards.values.length,
    );
  }

  SliverToBoxAdapter _pointsSystem(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: Text(
          context.t.pointsSystem.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class ChatContainer extends StatelessWidget {
  const ChatContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        final List<Chart> chartList = [];

        for (final standard
            in state.userGlobalStats!.repeatedPointStandards.values) {
          final chart = Chart(
            standard: standard,
            action: state.userGlobalStats!.actions[standard.id],
          );

          chartList.add(chart);
        }

        return IncomeChart(
          chart: chartList,
        );
      },
    );
  }
}

class PointContainer extends StatelessWidget {
  const PointContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        final points = state.currentXp - state.consumablePoints;

        return Container(
          padding: const EdgeInsets.all(
            kDefaultPadding / 2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
          ),
          child: _contentColumn(points, context, state),
        );
      },
    );
  }

  Column _contentColumn(
      int points, BuildContext context, PointsManagementState state) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              points.toString(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              ' / ${state.currentXp} ',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).highlightColor,
                  ),
            ),
            Text(
              context.t.points.toLowerCase(),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).highlightColor,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                showBlurredModal(
                  context: context,
                  view: const ConsumablePointsView(),
                );
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
              ),
              child: Text(
                context.t.whatsThis.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: kWhite,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        LinearProgressIndicator(
          value: state.consumablePoints / state.currentXp,
          color: kRed,
          minHeight: 5,
          backgroundColor: kBlack.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                context.t.consumablePoints.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(),
              ),
            ),
            Text(
              context.t.lastUpdatedOn(
                date: points == 0
                    ? 'N/A'
                    : dateFormat2.format(
                        state.userGlobalStats!.currentPointsLastUpdated),
              ),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(),
            ),
          ],
        ),
      ],
    );
  }
}

class XpContainer extends StatelessWidget {
  const XpContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(
            kDefaultPadding / 2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
          ),
          child: _contentColumn(state, context),
        );
      },
    );
  }

  Column _contentColumn(PointsManagementState state, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              state.currentXp.toString(),
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Text(
              'xp',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).highlightColor),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Text(
              'lvl',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Text(
              '${state.currentLevel}',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const Spacer(),
            ...state.userGlobalStats!.pointSystemTiers.values.map(
              (tier) {
                final isUnlocked = tier.getStats()['isUnlocked'];

                return Opacity(
                  opacity: isUnlocked ? 1 : 0.5,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      showBlurredModal(
                        context: context,
                        view: TierView(
                          tier: tier,
                        ),
                      );
                    },
                    icon: Image.asset(
                      isUnlocked ? tier.icon : Images.silverTier,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.t.pointsRemaining(
                number: (state.nextLevelXp -
                        state.currentLevelXp -
                        state.additionalXp)
                    .toString(),
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              context.t
                  .levelNumber(number: (state.currentLevel + 1).toString()),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        LinearProgressIndicator(
          value: state.percentage,
          color: kRed,
          minHeight: 5,
          backgroundColor: kBlack.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
        ),
      ],
    );
  }
}
