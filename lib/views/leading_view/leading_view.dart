import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../logic/leading_cubit/leading_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../discover_view/discover_view.dart';
import '../settings_view/widgets/property_analytics_cache.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/classic_footer.dart';
import '../widgets/content_placeholder.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/empty_list.dart';
import '../widgets/fluid_pull_down_button.dart';
import '../widgets/fluid_source_filter_row.dart';
import '../widgets/upgrade_banner.dart';
import 'widgets/leading_feed.dart';
import 'widgets/media_box.dart';

class LeadingView extends StatefulWidget {
  LeadingView({
    super.key,
    required this.scrollController,
    this.barsVisible,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Home view');
  }

  final ScrollController scrollController;
  final ValueNotifier<bool>? barsVisible;

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
                    if (isFluid())
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.top +
                              kToolbarHeight +
                              40,
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: kDefaultPadding),
                        child: UpgradeBanner(dismissible: true),
                      ),
                    ),
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
                          icon: FeatureIcons.search,
                          title: context.t.noResults,
                        ),
                      )
                    else
                      const LeadingFeed(key: ValueKey('Leading')),
                    if (themeCubit.state.isFluid)
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom: kBottomNavigationBarHeight +
                              kDefaultPadding * 2 +
                              MediaQuery.of(context).padding.bottom / 2,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );

    if (!isFluid()) {
      widgets.add(
        Positioned(
          top: kDefaultPadding / 2,
          left: 0,
          right: 0,
          child: LeadingNewContentComponent(widget: widget),
        ),
      );
    }

    if (isFluid()) {
      widgets.add(
        Positioned(
          left: kDefaultPadding / 2,
          right: kDefaultPadding / 2,
          top: MediaQuery.of(context).padding.top +
              kToolbarHeight +
              kDefaultPadding / 2,
          child: Align(
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.barsVisible ?? ValueNotifier(true),
              builder: (context, visible, child) => IgnorePointer(
                ignoring: !visible,
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, -1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: child,
                  ),
                ),
              ),
              child: FluidSourceFilterRow(
                viewType: ViewDataTypes.notes,
                onSourceChanged: () =>
                    leadingCubit.buildLeadingFeed(isAdding: false),
              ),
            ),
          ),
        ),
      );
    }

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

  FluidPullDownButton _pullDownButton(BuildContext context) {
    return FluidPullDownButton(
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
            iconWidget: AppIcon(
              FeatureIcons.notVisible,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => RotatedBox(
        quarterTurns: 1,
        child: AppIconButton(
          icon: LucideIcons.moreVertical,
          onClicked: showMenu,
          iconSize: 18,
          iconColor: Theme.of(context).primaryColorDark,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            widget.barsVisible?.value = true;
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
              AppIcon(
                FeatureIcons.visible,
                size: 25,
                color: Theme.of(context).primaryColorDark,
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
              backgroundBuilder: (_, __, child) => child!,
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
