import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../logic/leading_cubit/leading_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../discover_view/discover_view.dart';
import '../settings_view/widgets/property_analytics_cache.dart';
import '../widgets/classic_footer.dart';
import '../widgets/content_placeholder.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/empty_list.dart';
import 'widgets/leading_feed.dart';
import 'widgets/media_box.dart';

class LeadingView extends StatefulWidget {
  LeadingView({
    super.key,
    required this.scrollController,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Home view');
  }

  final ScrollController scrollController;

  @override
  State<LeadingView> createState() => _LeadingViewState();
}

class _LeadingViewState extends State<LeadingView> {
  final refreshController = RefreshController();
  CommonFeedTypes? mainType;

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  void buildExploreFeed(
    BuildContext context,
    bool isAdding,
  ) {
    context.read<LeadingCubit>().buildLeadingFeed(
          isAdding: isAdding,
        );
  }

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    widgets.add(
      Builder(
        builder: (context) {
          return BlocConsumer<LeadingCubit, LeadingState>(
            listener: (context, state) {
              if (state.onAddingData == UpdatingState.success) {
                refreshController.loadComplete();
              } else if (state.onAddingData == UpdatingState.idle) {
                refreshController.loadNoData();
              }

              if (!state.onContentLoading) {
                refreshController.refreshCompleted();
              }
            },
            builder: (context, state) {
              return SmartRefresher(
                controller: refreshController,
                enablePullUp: true,
                header: const RefresherClassicHeader(),
                footer: const RefresherClassicFooter(),
                onLoading: () => buildExploreFeed.call(
                  context,
                  true,
                ),
                onRefresh: () => buildExploreFeed.call(
                  context,
                  false,
                ),
                child: CustomScrollView(
                  controller: widget.scrollController,
                  slivers: [
                    if (state.showSuggestions &&
                        (state.onMediaLoading ||
                            (!state.onMediaLoading &&
                                state.media.isNotEmpty))) ...[
                      if (canSign()) ...[
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                        ),
                        _suggestions(context),
                      ],
                      _mediaBox(),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ),
                    if (state.showFollowingListMessage) ...[
                      const SliverToBoxAdapter(
                        child: ShowFollowingListMessageBox(),
                      )
                    ],
                    if (state.onContentLoading)
                      const SliverToBoxAdapter(child: NotesPlaceholder())
                    else if (state.content.isEmpty)
                      SliverToBoxAdapter(
                        child: EmptyList(
                          description: appSettingsManagerCubit
                                  .getSelectedNotesFilter()
                                  .id
                                  .isEmpty
                              ? context.t.noResultsNoFilterMessage
                              : context.t.noResultsFilterMessage,
                          icon: LogosIcons.logoMarkWhite,
                          title: context.t.noResults,
                        ),
                      )
                    else
                      const LeadingFeed(key: ValueKey('Leading')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );

    widgets.add(
      Positioned(
        top: kDefaultPadding / 2,
        left: 0,
        right: 0,
        child: LeadingNewContentComponent(widget: widget),
      ),
    );

    return FadeIn(
      child: Stack(
        children: widgets,
      ),
    );
  }

  BlocBuilder<LeadingCubit, LeadingState> _mediaBox() {
    return BlocBuilder<LeadingCubit, LeadingState>(
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: state.onMediaLoading ||
                  (!state.onMediaLoading && state.media.isNotEmpty)
              ? SizedBox(
                  height: 250,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: state.onMediaLoading
                        ? const LeadingMediaPlaceholder()
                        : const MediaBox(),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  SliverToBoxAdapter _suggestions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.t.suggestions.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ),
            _pullDownButton(context),
          ],
        ),
      ),
    );
  }

  PullDownButton _pullDownButton(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        return [
          PullDownMenuItem(
            title: context.t.hideSuggestions,
            onTap: () {
              nostrRepository.hideFeedSuggestions();
            },
            itemTheme: PullDownMenuItemTheme(
              textStyle: Theme.of(context).textTheme.labelMedium,
            ),
            iconWidget: SvgPicture.asset(
              FeatureIcons.notVisible,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => RotatedBox(
        quarterTurns: 1,
        child: IconButton(
          onPressed: showMenu,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            visualDensity: const VisualDensity(
              horizontal: -4,
              vertical: -4,
            ),
            padding: EdgeInsets.zero,
          ),
          icon: Icon(
            Icons.more_vert_rounded,
            color: Theme.of(context).primaryColorDark,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class LeadingNewContentComponent extends HookWidget {
  const LeadingNewContentComponent({
    super.key,
    required this.widget,
  });

  final LeadingView widget;

  @override
  Widget build(BuildContext context) {
    final isShowing = useState(leadingCubit.state.extraContent.isNotEmpty);

    return BlocConsumer<LeadingCubit, LeadingState>(
      listenWhen: (previous, current) =>
          previous.extraContent != current.extraContent,
      listener: (context, state) {
        if (state.extraContent.isNotEmpty) {
          isShowing.value = true;
        } else {
          isShowing.value = false;
        }
      },
      builder: (context, state) {
        return LeadingNewContentBox(
          extraContent: state.extraContent,
          isShowing: isShowing,
          onClicked: () {
            leadingCubit.appendExtra(() {
              widget.scrollController.jumpTo(0.0);
            });
          },
        );
      },
    );
  }
}

class LeadingNewContentBox extends HookWidget {
  const LeadingNewContentBox({
    super.key,
    required this.extraContent,
    required this.isShowing,
    required this.onClicked,
  });

  final List<Event> extraContent;
  final ValueNotifier<bool> isShowing;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    final length =
        extraContent.length > 100 ? '99+' : extraContent.length.toString();

    final uniquePubkeys = extraContent.map((e) => e.pubkey).toSet().toList();

    final pubkeys = uniquePubkeys.sublist(
      0,
      uniquePubkeys.length >= 3 ? 2 : uniquePubkeys.length,
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: NewContentContainer(
        isShowing: isShowing,
        pubkeys: pubkeys,
        text: length,
        onClicked: onClicked,
        onDrag: () {},
        onClose: () {
          isShowing.value = false;
        },
      ),
    );
  }
}

class ShowFollowingListMessageBox extends StatelessWidget {
  const ShowFollowingListMessageBox({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: Column(
        children: [
          const Divider(
            thickness: 0.5,
            height: kDefaultPadding,
          ),
          Row(
            spacing: kDefaultPadding / 2,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                FeatureIcons.visible,
                width: 25,
                height: 25,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
              Text(
                context.t.viewAs,
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            context.t.showFollowingList,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            textAlign: TextAlign.center,
          ),
          const Divider(
            thickness: 0.5,
            height: kDefaultPadding,
          ),
        ],
      ),
    );
  }
}

class CacheExceedsSizeContainer extends HookWidget {
  const CacheExceedsSizeContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final exceedsSize = useState(false);

    useMemoized(
      () async {
        final res = await Future.wait([
          nc.db.getDatabaseSizeInMB(),
          getCachedMediaSizeInMB(),
        ]);

        final dataSize = res[0];
        final mediaSize = res[1];

        exceedsSize.value =
            ((mediaSize > cacheMaxSize) || (dataSize > cacheMaxSize)) &&
                nostrRepository.showCacheExceedsSize;
      },
    );

    return exceedsSize.value
        ? _sizeExceedsContainer(context, exceedsSize)
        : const SizedBox.shrink();
  }

  Container _sizeExceedsContainer(
      BuildContext context, ValueNotifier<bool> exceedsSize) {
    return Container(
      padding: const EdgeInsets.only(
        right: kDefaultPadding / 4,
        left: kDefaultPadding / 2,
        bottom: kDefaultPadding / 4,
        top: kDefaultPadding / 4,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: kRed.withValues(
          alpha: 0.2,
        ),
        border: Border.all(
          color: kRed,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  context.t.appCache,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                right: 0,
                child: CustomIconButton(
                  onClicked: () {
                    exceedsSize.value = false;
                    nostrRepository.showCacheExceedsSize = false;
                  },
                  icon: FeatureIcons.closeRaw,
                  size: 18,
                  backgroundColor: kTransparent,
                  vd: -4,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            context.t.appCacheNotice,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () {
              YNavigator.pushPage(
                context,
                (context) => PropertyAnalyticsCache(),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: kTransparent,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              context.t.manageCache,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
