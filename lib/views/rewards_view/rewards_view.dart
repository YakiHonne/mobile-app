// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/rewards_cubit/rewards_cubit.dart';
import '../../logic/uncensored_notes_cubit/uncensored_notes_cubit.dart';
import '../../models/flash_news_model.dart';
import '../../models/uncensored_notes_models.dart';
import '../../utils/utils.dart';
import '../search_view/search_view.dart';
import '../uncensored_notes_view/uncensored_notes_view.dart';
import '../uncensored_notes_view/widgets/un_flashnews_details.dart';
import '../uncensored_notes_view/widgets/uncensored_note_component.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/data_providers.dart';
import '../widgets/empty_list.dart';
import '../widgets/flash_news_container.dart';
import '../widgets/no_content_widgets.dart';

class RewardsView extends HookWidget {
  RewardsView({
    super.key,
    required this.uncensoredNotesCubit,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Rewards view');
  }

  static const routeName = '/rewardsView';
  static Route route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (_) => RewardsView(
        uncensoredNotesCubit: settings.arguments! as UncensoredNotesCubit,
      ),
    );
  }

  final UncensoredNotesCubit uncensoredNotesCubit;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    return BlocProvider(
      create: (context) =>
          RewardsCubit(uncensoredNotesCubit: uncensoredNotesCubit)..initView(),
      lazy: false,
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.rewards.capitalizeFirst(),
        ),
        body: BlocBuilder<RewardsCubit, RewardsState>(
          builder: (context, state) {
            return Stack(
              children: [
                _scrollableView(scrollController, state),
                ResetScrollButton(
                  scrollController: scrollController,
                  isLeft: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Scrollbar _scrollableView(
      ScrollController scrollController, RewardsState state) {
    return Scrollbar(
      controller: scrollController,
      child: NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: BlocProvider.value(
                value: uncensoredNotesCubit,
                child: CommunityWalletContainer(
                  isMainView: false,
                  onClicked: () {
                    uncensoredNotesCubit.getBalance();
                    context.read<RewardsCubit>().initView();
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: kDefaultPadding,
              ),
            ),
          ];
        },
        body: getView(updatingState: state.updatingState),
      ),
    );
  }

  Widget getView({
    required UpdatingState updatingState,
  }) {
    if (updatingState == UpdatingState.progress) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: kDefaultPadding),
        child: SearchLoading(),
      );
    } else if (updatingState == UpdatingState.success) {
      return const RewardsList();
    } else if (updatingState == UpdatingState.failure) {
      return WrongView(
        onClicked: () {},
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class RewardsList extends StatelessWidget {
  const RewardsList({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocBuilder<RewardsCubit, RewardsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: state.rewards.isEmpty
              ? EmptyList(
                  description: context.t.noRewards.capitalizeFirst(),
                  icon: FeatureIcons.reward,
                )
              : isMobile
                  ? _itemsList(state)
                  : _itemsGrid(state),
        );
      },
    );
  }

  MasonryGridView _itemsGrid(RewardsState state) {
    return MasonryGridView.builder(
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      mainAxisSpacing: kDefaultPadding / 2,
      crossAxisSpacing: kDefaultPadding / 2,
      itemBuilder: (context, index) {
        final reward = state.rewards[index];

        return Container(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: Theme.of(context).cardColor,
          ),
          child: getRewardColumn(reward),
        );
      },
      itemCount: state.rewards.length,
    );
  }

  ListView _itemsList(RewardsState state) {
    return ListView.separated(
      itemBuilder: (context, index) {
        final reward = state.rewards[index];

        return Container(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: Theme.of(context).cardColor,
          ),
          child: getRewardColumn(reward),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
      itemCount: state.rewards.length,
    );
  }

  Widget getRewardColumn(RewardModel rewardModel) {
    if (rewardModel is RatingReward) {
      return RatingColumn(ratingReward: rewardModel);
    } else if (rewardModel is UncensoredNoteReward) {
      return UncensoredColumn(uncensoredNoteReward: rewardModel);
    } else if (rewardModel is SealedReward) {
      return SealedColumn(sealedReward: rewardModel);
    } else {
      return const SizedBox.shrink();
    }
  }
}

class RatingColumn extends StatelessWidget {
  const RatingColumn({
    super.key,
    required this.ratingReward,
  });

  final RatingReward ratingReward;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.onDate(
            date: dateFormat4.format(ratingReward.rating.createdAt),
          ),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  height: 1,
                ),
            children: [
              TextSpan(text: '${context.t.youHaveRated} '),
              WidgetSpan(
                child: SvgPicture.asset(
                  ratingReward.rating.ratingValue
                      ? FeatureIcons.like
                      : FeatureIcons.dislike,
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              TextSpan(text: ' ${context.t.theFollowingNote}'),
            ],
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        _uncensoredNoteComponent(),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        ClaimButton(
          status: ratingReward.status,
          createdAt: ratingReward.rating.createdAt,
          eventId: ratingReward.rating.id,
          kind: EventKind.REACTION,
          isAuthor: true,
          useTimer: true,
        ),
      ],
    );
  }

  UncensoredNoteComponent _uncensoredNoteComponent() {
    return UncensoredNoteComponent(
      note: ratingReward.note,
      flashNewsPubkey: '-1',
      isUncensoredNoteAuthor:
          ratingReward.note.pubKey == currentSigner!.getPublicKey(),
      isComponent: true,
      isSealed: ratingReward.note.isUnSealed,
      sealedNote: ratingReward.note.isUnSealed
          ? SealedNote(
              createdAt: ratingReward.note.createdAt,
              uncensoredNote: ratingReward.note,
              flashNewsId: ratingReward.note.flashNewsId,
              noteAuthor: ratingReward.note.pubKey,
              raters: [],
              reasons: [],
              isAuthentic: true,
              isHelpful: true,
              id: ratingReward.note.id,
            )
          : null,
      sealDisable: true,
      onDelete: (d) {},
      onLike: () {},
      onDislike: () {},
    );
  }
}

class UncensoredColumn extends StatelessWidget {
  const UncensoredColumn({
    super.key,
    required this.uncensoredNoteReward,
  });

  final UncensoredNoteReward uncensoredNoteReward;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.onDate(
            date: dateFormat4.format(uncensoredNoteReward.note.createdAt),
          ),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          context.t.youHaveLeftNote.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                height: 1,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        _flashnewsContainer(context),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        ClaimButton(
          status: uncensoredNoteReward.status,
          eventId: uncensoredNoteReward.note.id,
          createdAt: uncensoredNoteReward.note.createdAt,
          kind: EventKind.TEXT_NOTE,
          isAuthor: true,
          useTimer: false,
        ),
      ],
    );
  }

  SingleEventProvider _flashnewsContainer(BuildContext context) {
    return SingleEventProvider(
      id: uncensoredNoteReward.note.flashNewsId,
      isReplaceable: false,
      child: (event) {
        if (event == null) {
          return Text(context.t.paidNoteLoading.capitalizeFirst());
        }

        final flash = FlashNews.fromEvent(event);

        return FlashNewsContainer(
          mainFlashNews: MainFlashNews(flashNews: flash),
          flashNewsType: FlashNewsType.display,
          onClicked: () {
            Navigator.pushNamed(
              context,
              UnFlashNewsDetails.routeName,
              arguments: UnFlashNews(
                flashNews: flash,
                uncensoredNotes: [],
                isSealed: false,
              ),
            );
          },
          isComponent: true,
        );
      },
    );
  }
}

class SealedColumn extends StatelessWidget {
  const SealedColumn({
    super.key,
    required this.sealedReward,
  });

  final SealedReward sealedReward;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.onDate(
            date: dateFormat4.format(sealedReward.note.createdAt),
          ),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          sealedReward.isAuthor
              ? context.t.yourNoteSealed.capitalizeFirst()
              : context.t.ratedNoteSealed.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                height: 1,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        UncensoredNoteComponent(
          note: sealedReward.note.uncensoredNote,
          flashNewsPubkey: '-1',
          isUncensoredNoteAuthor: sealedReward.note.uncensoredNote.pubKey ==
              currentSigner!.getPublicKey(),
          isComponent: true,
          isSealed: true,
          sealedNote: sealedReward.note,
          sealDisable: true,
          onDelete: (d) {},
          onLike: () {},
          onDislike: () {},
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        ClaimButton(
          status: sealedReward.status,
          createdAt: sealedReward.note.createdAt,
          eventId: sealedReward.note.id,
          kind: EventKind.APP_CUSTOM,
          isAuthor: sealedReward.isAuthor,
          useTimer: false,
        ),
      ],
    );
  }
}

class ClaimButton extends HookWidget {
  const ClaimButton({
    super.key,
    required this.status,
    required this.isAuthor,
    required this.eventId,
    required this.kind,
    required this.createdAt,
    required this.useTimer,
  });

  final RewardStatus status;
  final bool isAuthor;
  final String eventId;
  final int kind;
  final DateTime createdAt;
  final bool useTimer;

  @override
  Widget build(BuildContext context) {
    final timerShown = useState(
      useTimer && DateTime.now().difference(createdAt).inSeconds < 350,
    );

    final timerText = useState('');

    useMemoized(() {
      if (timerShown.value) {
        final topDate =
            createdAt.add(const Duration(minutes: 5)).toSecondsSinceEpoch();

        return Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            if (!context.mounted) {
              timer.cancel();
              return;
            }

            if (timerShown.value) {
              final currentTime =
                  topDate - DateTime.now().toSecondsSinceEpoch();
              timerText.value = currentTime.formattedSeconds();
              if (currentTime <= 0) {
                timerShown.value = false;
                timer.cancel();
              }
            }
          },
        );
      }
    });

    return BlocBuilder<RewardsCubit, RewardsState>(
      buildWhen: (previous, current) =>
          previous.loadingClaims != current.loadingClaims,
      builder: (context, state) {
        final isLoading = state.loadingClaims.contains(eventId);

        return Row(
          children: [
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            SvgPicture.asset(
              FeatureIcons.reward,
              width: 17,
              height: 17,
              colorFilter: const ColorFilter.mode(
                kMainColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Text(
              '${kind == EventKind.TEXT_NOTE ? state.initNotePrice : kind == EventKind.REACTION ? state.initRatingPrice : isAuthor ? state.sealedNotePrice : state.sealedRatingPrice} SATS',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: kMainColor,
                  ),
            ),
            const Spacer(),
            _textButton(isLoading, timerShown, context, timerText),
          ],
        );
      },
    );
  }

  Align _textButton(bool isLoading, ValueNotifier<bool> timerShown,
      BuildContext context, ValueNotifier<String> timerText) {
    return Align(
      alignment: Alignment.centerRight,
      child: AbsorbPointer(
        absorbing: isLoading,
        child: TextButton(
          onPressed: () {
            if (!timerShown.value && !isLoading) {
              context
                  .read<RewardsCubit>()
                  .claimReward(eventId: eventId, kind: kind);
            }
          },
          style: TextButton.styleFrom(
            visualDensity: const VisualDensity(
              vertical: -2,
            ),
            backgroundColor: timerShown.value
                ? Theme.of(context).highlightColor
                : status == RewardStatus.not_claimed
                    ? kMainColor
                    : status == RewardStatus.in_progress
                        ? Theme.of(context).highlightColor
                        : kGreen,
          ),
          child: timerShown.value
              ? Text(
                  context.t.claimTime(
                    time: timerText.value,
                  ),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: kBlack,
                      ),
                )
              : isLoading
                  ? const Center(
                      child: SpinKitThreeBounce(
                        color: kWhite,
                        size: 20,
                      ),
                    )
                  : Text(
                      status == RewardStatus.not_claimed
                          ? context.t.claim.capitalizeFirst()
                          : status == RewardStatus.in_progress
                              ? context.t.requestInProgress.capitalizeFirst()
                              : context.t.granted.capitalizeFirst(),
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium!
                          .copyWith(color: kWhite),
                    ),
        ),
      ),
    );
  }
}
