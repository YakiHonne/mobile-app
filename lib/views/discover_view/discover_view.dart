// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../logic/app_settings_manager_cubit/app_settings_manager_cubit.dart';
import '../../logic/discover_cubit/discover_cubit.dart';
import '../../logic/metadata_cubit/metadata_cubit.dart';
import '../../logic/relay_info_cubit/relay_info_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/flash_news_model.dart';
import '../../models/relays_feed.dart';
import '../../utils/utils.dart';
import '../leading_view/leading_view.dart';
import '../widgets/classic_footer.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/content_manager/add_discover_filter.dart';
import '../widgets/content_manager/discover_filter_list.dart';
import '../widgets/content_manager/discover_sources_list.dart';
import '../widgets/content_placeholder.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/data_providers.dart';
import '../widgets/profile_picture.dart';
import 'widgets/discover_feed.dart';

class DiscoverView extends StatefulWidget {
  DiscoverView({
    super.key,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Discover view');
  }

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  ExploreType selectedExploreType = ExploreType.articles;

  final refreshController = RefreshController();

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  void buildExploreFeed(BuildContext context, bool isAdding) {
    context.read<DiscoverCubit>().buildDiscoverFeed(
          exploreType: selectedExploreType,
          isAdding: isAdding,
        );
  }

  void reset(BuildContext context) {
    buildExploreFeed.call(context, false);
    context.read<DiscoverCubit>().resetExtra();
  }

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    widgets.add(
      BlocConsumer<DiscoverCubit, DiscoverState>(
        listener: (context, state) {
          if (state.onAddingData == UpdatingState.success) {
            refreshController.loadComplete();
          } else if (state.onAddingData == UpdatingState.idle) {
            refreshController.loadNoData();
          }

          if (!state.onLoading) {
            refreshController.refreshCompleted();
          }
        },
        buildWhen: (previous, current) =>
            previous.onLoading != current.onLoading ||
            previous.showFollowingListMessage !=
                current.showFollowingListMessage,
        builder: (context, state) {
          return SmartRefresher(
            controller: refreshController,
            enablePullUp: true,
            header: const RefresherClassicHeader(),
            footer: const RefresherClassicFooter(),
            onLoading: () => buildExploreFeed.call(context, true),
            onRefresh: () => reset(context),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
                // _appbar(context),
                if (state.showFollowingListMessage)
                  const SliverToBoxAdapter(
                    child: ShowFollowingListMessageBox(),
                  ),
                if (state.onLoading)
                  const SliverToBoxAdapter(child: ContentPlaceholder())
                else
                  const ExploreFeed(),
              ],
            ),
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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          nostrRepository.mainCubit.updateIndex(MainViews.leading);
        },
        child: Builder(
          builder: (context) {
            return Stack(
              children: widgets,
            );
          },
        ),
      ),
    );
  }

  // SliverAppBar _appbar(BuildContext context) {
  //   return SliverAppBar(
  //     leading: const SizedBox.shrink(),
  //     automaticallyImplyLeading: false,
  //     leadingWidth: 0,
  //     titleSpacing: 0,
  //     title: Container(
  //       color: Theme.of(context).scaffoldBackgroundColor,
  //       padding: const EdgeInsets.all(8.0),
  //       child: SizedBox(
  //         height: 36,
  //         width: double.infinity,
  //         child: ListView.separated(
  //           scrollDirection: Axis.horizontal,
  //           separatorBuilder: (context, index) => const SizedBox(
  //             width: kDefaultPadding / 4,
  //           ),
  //           itemBuilder: (context, index) {
  //             final type = ExploreType.values[index];

  //             return TagContainer(
  //               title: typeName(type: type, context: context).capitalizeFirst(),
  //               isActive: selectedExploreType == type,
  //               style: Theme.of(context).textTheme.labelLarge,
  //               onClick: () {
  //                 setState(
  //                   () {
  //                     selectedExploreType = type;
  //                     HapticFeedback.lightImpact();
  //                   },
  //                 );

  //                 reset(context);
  //               },
  //             );
  //           },
  //           itemCount: ExploreType.values.length,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  String typeName({required ExploreType type, required BuildContext context}) {
    switch (type) {
      case ExploreType.all:
        return context.t.all;
      case ExploreType.articles:
        return context.t.articles;
      case ExploreType.videos:
        return context.t.videos;
      case ExploreType.curations:
        return context.t.curations;
    }
  }
}

class SourceButton extends HookWidget {
  const SourceButton({
    super.key,
    required this.onSourceChanged,
    required this.viewType,
  });

  final ViewDataTypes viewType;
  final Function() onSourceChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppSettingsManagerCubit, AppSettingsManagerState>(
      listener: (context, state) {
        onSourceChanged.call();
      },
      listenWhen: (previous, current) =>
          previous.selectedDiscoverSource != current.selectedDiscoverSource ||
          previous.selectedNotesSource != current.selectedNotesSource ||
          previous.selectedMediaSource != current.selectedMediaSource,
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                return AppSourcesList(viewType: viewType);
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          behavior: HitTestBehavior.translucent,
          child: _optionContainer(state),
        );
      },
    );
  }

  Container _optionContainer(AppSettingsManagerState state) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: kDefaultPadding / 4,
        children: [
          SourceImage(
            viewType: viewType,
          ),
          Flexible(
            child: Builder(
              builder: (context) {
                final source = viewType == ViewDataTypes.articles
                    ? appSettingsManagerCubit.getDiscoverSelectedSource()
                    : viewType == ViewDataTypes.notes
                        ? appSettingsManagerCubit.getNotesSelectedSource()
                        : appSettingsManagerCubit.getMediaSelectedSource();

                final title = source.key == AppContentSource.relay
                    ? Relay.removeSocket(source.value.value) ??
                        source.value.value
                    : source.key == AppContentSource.relaySet
                        ? (source.value.value as UserRelaySet).getTitle()
                        : getSourceName(
                            name: viewType == ViewDataTypes.articles
                                ? state.selectedDiscoverSource.value
                                : viewType == ViewDataTypes.notes
                                    ? state.selectedNotesSource.value
                                    : state.selectedMediaSource.value,
                          ).capitalizeFirst();

                return Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                );
              },
            ),
          ),
          const SizedBox(
            width: 30,
            height: 30,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class SourceImage extends StatelessWidget {
  const SourceImage({super.key, required this.viewType});

  final ViewDataTypes viewType;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        final source = viewType == ViewDataTypes.articles
            ? appSettingsManagerCubit.getDiscoverSelectedSource()
            : viewType == ViewDataTypes.notes
                ? appSettingsManagerCubit.getNotesSelectedSource()
                : appSettingsManagerCubit.getMediaSelectedSource();

        return SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: source.key == AppContentSource.community
                    ? kTransparent
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(
                  kDefaultPadding / 4,
                ),
              ),
              alignment: Alignment.center,
              child: source.key == AppContentSource.community
                  ? getCommunityImage(context: context, url: source.value.value)
                  : source.key == AppContentSource.relaySet
                      ? getRelaySetImage(
                          context: context,
                          url: (source.value.value as UserRelaySet).image,
                        )
                      : getRelayImage(
                          context: context,
                          url: source.value.value,
                        ),
            ),
          ),
        );
      },
    );
  }

  Widget getRelaySetImage(
      {required BuildContext context, required String url}) {
    return CommonThumbnail(
      image: url,
      width: 26,
      height: 26,
      isRound: true,
      radius: kDefaultPadding / 4,
    );
  }

  Widget getCommunityImage({
    required BuildContext context,
    required String url,
  }) {
    final nameIcon = getSourceIcon(url);

    return SvgPicture.asset(
      nameIcon,
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(
        Theme.of(context).primaryColorDark,
        BlendMode.srcIn,
      ),
    );
  }

  Widget getRelayImage({required BuildContext context, required String url}) {
    return BlocBuilder<RelayInfoCubit, RelayInfoState>(
      builder: (context, state) {
        final relayInfo = state.relayInfos[url];

        return relayInfo != null && relayInfo.icon.isNotEmpty
            ? CommonThumbnail(
                image: relayInfo.icon,
                width: 26,
                height: 26,
                isRound: true,
                radius: kDefaultPadding / 4,
              )
            : Text(
                url.isEmpty
                    ? ''
                    : url
                        .split('wss://')
                        .last
                        .characters
                        .first
                        .capitalizeFirst(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              );
      },
    );
  }
}

class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.onFilterChanged,
    required this.viewType,
  });

  final ViewDataTypes viewType;
  final Function() onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppSettingsManagerCubit, AppSettingsManagerState>(
      listener: (context, state) {
        onFilterChanged.call();
      },
      listenWhen: (previous, current) =>
          previous.selectedDiscoverFilter != current.selectedDiscoverFilter ||
          previous.selectedNotesFilter != current.selectedNotesFilter ||
          previous.selectedMediaFilter != current.selectedMediaFilter ||
          previous.discoverFilters != current.discoverFilters ||
          previous.notesFilters != current.notesFilters ||
          previous.mediaFilters != current.mediaFilters,
      builder: (context, state) {
        final title = viewType == ViewDataTypes.articles
            ? state.discoverFilters[state.selectedDiscoverFilter]?.title ?? ''
            : viewType == ViewDataTypes.notes
                ? state.notesFilters[state.selectedNotesFilter]?.title ?? ''
                : state.mediaFilters[state.selectedMediaFilter]?.title ?? '';

        return Row(
          spacing: kDefaultPadding / 8,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (title.isNotEmpty) _actionStack(context, title),
            _filterButton(state, context),
          ],
        );
      },
    );
  }

  GestureDetector _filterButton(
      AppSettingsManagerState state, BuildContext context) {
    return GestureDetector(
      onTap: () {
        doIfCanSign(
          func: () {
            Widget view;

            if (viewType == ViewDataTypes.articles) {
              if (state.discoverFilters.isEmpty) {
                view = AddDiscoverFilter(
                  discoverFilter:
                      appSettingsManagerCubit.getSelectedDiscoverFilter(),
                );
              } else {
                view = AppFilterList(
                  viewType: viewType,
                );
              }
            } else if (viewType == ViewDataTypes.notes) {
              if (state.notesFilters.isEmpty) {
                view = AddNotesFilter(
                  notesFilter: appSettingsManagerCubit.getSelectedNotesFilter(),
                );
              } else {
                view = AppFilterList(
                  viewType: viewType,
                );
              }
            } else {
              if (state.mediaFilters.isEmpty) {
                view = AddMediaFilter(
                  mediaFilter: appSettingsManagerCubit.getSelectedMediaFilter(),
                );
              } else {
                view = AppFilterList(
                  viewType: viewType,
                );
              }
            }

            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                return view;
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          context: context,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 3,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: SvgPicture.asset(
          FeatureIcons.filter,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Flexible _actionStack(BuildContext context, String title) {
    return Flexible(
      child: Stack(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.only(
              left: kDefaultPadding / 2,
              top: kDefaultPadding / 3,
              bottom: kDefaultPadding / 3,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CustomIconButton(
                    onClicked: () {
                      appSettingsManagerCubit.setFilter(
                        id: '',
                        viewType: viewType,
                      );
                    },
                    icon: FeatureIcons.closeRaw,
                    size: 13,
                    vd: -2,
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeadingNewContentComponent extends HookWidget {
  const LeadingNewContentComponent({
    super.key,
    required this.widget,
  });

  final DiscoverView widget;

  @override
  Widget build(BuildContext context) {
    final isShowing = useState(discoverCubit.state.extraContent.isNotEmpty);

    return BlocConsumer<DiscoverCubit, DiscoverState>(
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
            discoverCubit.appendExtra();
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

  final List<BaseEventModel> extraContent;
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
        key: ValueKey(extraContent.hashCode),
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

class NewContentContainer extends HookWidget {
  const NewContentContainer({
    super.key,
    required this.isShowing,
    required this.pubkeys,
    required this.text,
    required this.onClose,
    required this.onClicked,
    required this.onDrag,
  });

  final ValueNotifier<bool> isShowing;
  final List<String> pubkeys;
  final String text;
  final Function() onClose;
  final Function() onClicked;
  final Function() onDrag;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );

    useEffect(() {
      if (isShowing.value) {
        controller.forward();
      } else {
        controller.reverse();
      }
      return null;
    }, [isShowing.value]);

    final List<Widget> images = [];

    for (int i = 0; i < (pubkeys.length); i++) {
      final pubkey = pubkeys.elementAt(i);

      images.add(
        MetadataProvider(
          key: ValueKey(pubkey),
          pubkey: pubkey,
          child: (metadata, p1) {
            return RepaintBoundary(
              child: ProfilePicture2(
                size: 32,
                image: metadata.picture,
                pubkey: metadata.pubkey,
                padding: 0,
                strokeWidth: 2,
                strokeColor: Theme.of(context).cardColor,
                onClicked: onClicked,
              ),
            );
          },
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedOpacity(
        opacity: isShowing.value ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: SlideTransition(
          position: slideAnimation,
          child: GestureDetector(
            onTap: onClicked,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: isShowing.value
                  ? BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(300),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                          color: kBlack.withValues(alpha: 0.3),
                        ),
                      ],
                    )
                  : null,
              padding: const EdgeInsets.all(kDefaultPadding / 4),
              margin: const EdgeInsets.only(
                bottom: kToolbarHeight,
                left: kDefaultPadding,
                right: kDefaultPadding,
              ),
              child: _item(images),
            ),
          ),
        ),
      ),
    );
  }

  BlocBuilder<MetadataCubit, MetadataState> _item(List<Widget> images) {
    return BlocBuilder<MetadataCubit, MetadataState>(
      builder: (context, state) {
        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          firstChild: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: kDefaultPadding / 2,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 32,
                    width: 32 + (images.length - 1) * 18,
                  ),
                  ...images.reversed.map(
                    (e) => Positioned(
                      left: images.indexOf(e) * 18,
                      child: e,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                    ),
                    Text(
                      context.t.newKey,
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            // color: Theme.of(context).highlightColor,
                            height: 1,
                          ),
                    ),
                  ],
                ),
              ),
              CustomIconButton(
                onClicked: onClose,
                icon: FeatureIcons.closeRaw,
                size: 17,
                vd: -2,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isShowing.value
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
        );
      },
    );
  }
}
