// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/relay_feed_cubit/relay_feed_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/article_model.dart';
import '../../../models/curation_model.dart';
import '../../../models/detailed_note_model.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/video_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../article_view/article_view.dart';
import '../../curation_view/curation_view.dart';
import '../../explore_relays_view/explore_relays_view.dart';
import '../../media_view/media_view.dart';
import '../../settings_view/widgets/keys_view.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/article_container.dart';
import '../../widgets/classic_footer.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/curation_container.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/fluid_content_card.dart';
import '../../widgets/media_components/horizontal_video_view.dart';
import '../../widgets/media_components/vertical_video_view.dart';
import '../../widgets/note_stats.dart';
import '../../widgets/tag_container.dart';
import '../../widgets/video_common_container.dart';
import 'relay_reviews_list_bottom_sheet.dart';

class RelayContentFeed extends StatefulWidget {
  const RelayContentFeed({
    super.key,
  });

  @override
  State<RelayContentFeed> createState() => _RelayContentFeedState();
}

class _RelayContentFeedState extends State<RelayContentFeed>
    with SingleTickerProviderStateMixin {
  RelayContentType selectedExploreType = RelayContentType.notes;
  final scrollController = ScrollController();
  final refreshController = RefreshController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: RelayContentType.values.length,
      vsync: this,
      initialIndex: RelayContentType.values.indexOf(selectedExploreType),
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final type = RelayContentType.values[_tabController.index];
    if (selectedExploreType == type) {
      return;
    }
    setState(() {
      selectedExploreType = type;
    });
    buildRelayFeed(context, false);
  }

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    refreshController.dispose();
    super.dispose();
  }

  void buildRelayFeed(BuildContext context, bool isAdding) {
    context.read<RelayFeedCubit>().buildRelayFeed(
          type: selectedExploreType,
          isAdding: isAdding,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return BlocConsumer<RelayFeedCubit, RelayFeedState>(
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
              previous.onLoading != current.onLoading,
          builder: (context, state) {
            final relay = context.read<RelayFeedCubit>().relay;

            final scrollBody = SmartRefresher(
              controller: refreshController,
              scrollController: scrollController,
              enablePullUp: true,
              header: const RefresherClassicHeader(),
              footer: const RefresherClassicFooter(),
              onLoading: () => buildRelayFeed.call(context, true),
              onRefresh: () => buildRelayFeed.call(context, false),
              child: CustomScrollView(
                slivers: [
                  if (relayInfoCubit.state.relayInfos[relay] != null)
                    _relayBox(context),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                  ),
                  _relayReviews(context),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: kDefaultPadding),
                  ),
                  _nip43Action(context),
                  if (!isFluid()) _appbar(context),
                  if (state.onLoading)
                    SliverToBoxAdapter(
                      child: selectedExploreType == RelayContentType.media
                          ? const MediaPlaceholder()
                          : const ContentPlaceholder(),
                    )
                  else
                    ContentList(
                      type: selectedExploreType,
                      scrollController: scrollController,
                    ),
                ],
              ),
            );

            if (isFluid()) {
              return Stack(
                children: [
                  scrollBody,
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom +
                        kDefaultPadding / 2,
                    left: kDefaultPadding / 2,
                    right: kDefaultPadding / 2,
                    child: Align(child: _buildFluidRelayTabBar(context)),
                  ),
                ],
              );
            }
            return scrollBody;
          },
        );
      },
    );
  }

  SliverAppBar _appbar(BuildContext context) {
    return SliverAppBar(
      leading: const SizedBox.shrink(),
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      titleSpacing: 0,
      floating: true,
      title: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 36,
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => const SizedBox(
              width: kDefaultPadding / 4,
            ),
            itemBuilder: (context, index) {
              final type = RelayContentType.values[index];

              return TagContainer(
                title: typeName(type: type, context: context).capitalizeFirst(),
                isActive: selectedExploreType == type,
                style: Theme.of(context).textTheme.labelLarge,
                onClick: () {
                  _tabController.animateTo(
                    RelayContentType.values.indexOf(type),
                  );
                  setState(
                    () {
                      selectedExploreType = type;
                      HapticFeedback.lightImpact();
                      buildRelayFeed.call(context, false);
                    },
                  );
                },
              );
            },
            itemCount: RelayContentType.values.length,
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _relayBox(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          left: kDefaultPadding / 2,
          right: kDefaultPadding / 2,
          top: kDefaultPadding / 2,
        ),
        child: RelayBox(
          relay: context.read<RelayFeedCubit>().relay,
          enableBrowse: false,
        ),
      ),
    );
  }

  Widget _nip43Action(BuildContext context) {
    if (!canSign()) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final cubit = context.read<RelayFeedCubit>();

    return BlocBuilder<RelayFeedCubit, RelayFeedState>(
      builder: (context, state) {
        if (!state.isNip43Supported) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            child: Row(
              spacing: kDefaultPadding / 4,
              children: [
                if (state.isMember)
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final code = await cubit.requestRelayInviteCode();
                        if (code != null && context.mounted) {
                          _showInviteCodeModal(context, code);
                        } else {
                          BotToastUtils.showError(context.t.noInviteCodeFound);
                        }
                      },
                      child: Builder(builder: (context) {
                        final inviteRow = Row(
                          spacing: kDefaultPadding / 4,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(
                              FeatureIcons.codeText,
                              size: 20,
                              color: Theme.of(context).primaryColorDark,
                            ),
                            Flexible(
                              child: Text(
                                context.t.getInviteCode.capitalizeFirst(),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                        return isFluid()
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4,
                                ),
                                child: FluidCardContainer(
                                  borderRadius: kDefaultPadding / 2,
                                  padding:
                                      const EdgeInsets.all(kDefaultPadding / 2),
                                  child: inviteRow,
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(
                                    kDefaultPadding / 2,
                                  ),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                    width: 0.5,
                                  ),
                                ),
                                margin: const EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4,
                                ),
                                padding:
                                    const EdgeInsets.all(kDefaultPadding / 2),
                                child: inviteRow,
                              );
                      }),
                    ),
                  ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (state.isMember) {
                        cubit.leaveRelay();
                      } else {
                        showModalBottomSheet(
                          elevation: 0,
                          context: context,
                          builder: (_) {
                            return BlocProvider.value(
                              value: cubit,
                              child: const RequestRelayJoin(),
                            );
                          },
                          isScrollControlled: true,
                          useRootNavigator: true,
                          useSafeArea: true,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        );
                      }
                    },
                    child: Builder(builder: (context) {
                      final joinLeaveRow = Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (state.checkMembership)
                            Center(
                              child: SpinKitCircle(
                                color: Theme.of(context).primaryColorDark,
                                size: 20,
                              ),
                            )
                          else
                            Flexible(
                              child: state.isMember
                                  ? Row(
                                      spacing: kDefaultPadding / 4,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const AppIcon(
                                          FeatureIcons.log,
                                          size: 20,
                                          color: kRed,
                                        ),
                                        Flexible(
                                          child: Text(
                                            context.t.leaveRelay
                                                .capitalizeFirst(),
                                            style: const TextStyle(color: kRed),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      spacing: kDefaultPadding / 4,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AppIcon(
                                          FeatureIcons.log,
                                          size: 20,
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                        ),
                                        Flexible(
                                          child: Text(
                                            context.t.joinRelay
                                                .capitalizeFirst(),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                        ],
                      );
                      return isFluid()
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: kDefaultPadding / 4,
                              ),
                              child: FluidCardContainer(
                                borderRadius: kDefaultPadding / 2,
                                padding:
                                    const EdgeInsets.all(kDefaultPadding / 2),
                                child: joinLeaveRow,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(
                                  kDefaultPadding / 2,
                                ),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                  width: 0.5,
                                ),
                              ),
                              margin: const EdgeInsets.symmetric(
                                vertical: kDefaultPadding / 4,
                              ),
                              padding:
                                  const EdgeInsets.all(kDefaultPadding / 2),
                              child: joinLeaveRow,
                            );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInviteCodeModal(BuildContext context, String code) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
              ),
              child: Column(
                children: [
                  const ModalBottomSheetHandle(),
                  Expanded(
                    child: Column(
                      spacing: kDefaultPadding,
                      children: [
                        Text(
                          context.t.relayInviteCode,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Container(
                          width: 200,
                          height: 200,
                          padding: const EdgeInsets.all(kDefaultPadding / 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2),
                          ),
                          child: PrettyQrView.data(
                            data: code,
                            decoration: PrettyQrDecoration(
                              shape: PrettyQrRoundedSymbol(
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: code));
                            BotToastUtils.showSuccess(
                                context.t.codeCopiedToClipboard);
                          },
                          child: DottedContainer(
                            value: code,
                            title: context.t.inviteCode,
                            onClicked: () {
                              Clipboard.setData(ClipboardData(text: code));
                              BotToastUtils.showSuccess(
                                  context.t.codeCopiedToClipboard);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                  Row(
                    spacing: kDefaultPadding / 4,
                    children: [
                      Expanded(
                        child: SendOptionsButton(
                          onClicked: () => YNavigator.pop(context),
                          title: context.t.close.capitalizeFirst(),
                          icon: FeatureIcons.closeRaw,
                          textColor: kWhite,
                          backgroundColor: kRed,
                        ),
                      ),
                      Expanded(
                        child: SendOptionsButton(
                          onClicked: () => shareContent(text: code),
                          title: context.t.share.capitalizeFirst(),
                          icon: FeatureIcons.shareExternal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _relayReviews(BuildContext context) {
    return BlocBuilder<RelayFeedCubit, RelayFeedState>(
      buildWhen: (previous, current) => previous.reviews != current.reviews,
      builder: (context, state) {
        final reviewsRow = Row(
          children: [
            Expanded(
              child: state.onLoadingReviews
                  ? Row(
                      spacing: kDefaultPadding / 4,
                      children: [
                        Flexible(
                          child: Text(
                            context.t.loadingReviews.capitalizeFirst(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        SpinKitCircle(
                          color: Theme.of(context).primaryColorDark,
                          size: 15,
                        ),
                      ],
                    )
                  : Row(
                      spacing: kDefaultPadding / 2,
                      children: [
                        Flexible(
                          child: ReviewsTotalRating(
                            reviews: state.reviews,
                          ),
                        ),
                        Text(
                          context.t.reviewsCount(
                            number: state.reviews.length.toString(),
                          ),
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: Theme.of(context).highlightColor,
                                  ),
                        ),
                      ],
                    ),
            ),
            AppIcon(
              FeatureIcons.arrowRight,
              size: 17,
              color: Theme.of(context).highlightColor,
            ),
          ],
        );

        return SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: context.read<RelayFeedCubit>(),
                  child: RelayReviewListBottomSheet(
                    relay: context.read<RelayFeedCubit>().relay,
                  ),
                ),
              );
            },
            child: isFluid()
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                    ),
                    child: FluidCardContainer(
                      borderRadius: kDefaultPadding / 2,
                      padding: const EdgeInsets.all(kDefaultPadding / 2),
                      child: reviewsRow,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                    ),
                    padding: const EdgeInsets.all(kDefaultPadding / 2),
                    child: reviewsRow,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFluidRelayTabBar(BuildContext context) {
    return FluidBlurContainer(
      padding: const EdgeInsets.all(3),
      backgroundAlpha: 0.5,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 1.5,
          vertical: 3,
        ),
        indicator: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(300),
        ),
        labelStyle: Theme.of(context)
            .textTheme
            .labelMedium!
            .copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: Theme.of(context)
            .textTheme
            .labelMedium!
            .copyWith(fontWeight: FontWeight.w500),
        tabs: RelayContentType.values
            .map(
              (type) => Tab(
                height: 28,
                text: typeName(type: type, context: context).capitalizeFirst(),
              ),
            )
            .toList(),
      ),
    );
  }

  String typeName(
      {required RelayContentType type, required BuildContext context}) {
    switch (type) {
      case RelayContentType.articles:
        return context.t.articles;
      case RelayContentType.media:
        return context.t.media;
      case RelayContentType.curations:
        return context.t.curations;
      case RelayContentType.notes:
        return context.t.notes;
    }
  }
}

class RequestRelayJoin extends HookWidget {
  const RequestRelayJoin({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RelayFeedCubit>();
    final textController = useTextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        maxChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: Column(
              children: [
                const ModalBottomSheetHandle(),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.t.joinRelay,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      Text(
                        context.t.joinRelayDesc,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).highlightColor,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      TextFormField(
                        controller: textController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2),
                          ),
                          hintText: context.t.inviteCode,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kDefaultPadding / 2),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      cubit.joinRelay(
                        inviteCode: textController.text,
                        onSuccess: () {
                          Navigator.pop(context);
                        },
                      );
                    },
                    child: Text(context.t.joinRelay),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContentList extends StatelessWidget {
  const ContentList({
    super.key,
    required this.type,
    required this.scrollController,
  });

  final RelayContentType type;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

    return BlocBuilder<RelayFeedCubit, RelayFeedState>(
      buildWhen: (previous, current) => previous.content != current.content,
      builder: (context, state) {
        final content = state.content;

        if (content.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyList(
              description: context.t.noResultsNoFilterMessage,
              icon: FeatureIcons.search,
              title: context.t.noResults,
            ),
          );
        }

        if (type == RelayContentType.media) {
          return MediaGrid(
            content: content,
            loadVideos: true,
          );
        }

        if (isTablet && !useSingleColumn) {
          return _itemsGrid(content);
        } else {
          return _itemsList(content);
        }
      },
    );
  }

  SliverPadding _itemsList(List<BaseEventModel> content) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      sliver: SliverList.separated(
        itemCount: content.length,
        separatorBuilder: (context, index) => useFluidCards()
            ? const SizedBox(height: kDefaultPadding / 2)
            : const Divider(
                height: kDefaultPadding,
                thickness: 0.5,
              ),
        itemBuilder: (context, index) {
          final item = content[index];

          return getItem(item, context);
        },
      ),
    );
  }

  SliverPadding _itemsGrid(List<BaseEventModel> content) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        childCount: content.length,
        crossAxisSpacing: kDefaultPadding / 2,
        mainAxisSpacing: kDefaultPadding / 2,
        itemBuilder: (context, index) {
          final item = content[index];

          return getItem(item, context);
        },
      ),
    );
  }

  Widget getItem(BaseEventModel item, BuildContext context) {
    return FluidContentCard(child: _content(item, context));
  }

  Widget _content(BaseEventModel item, BuildContext context) {
    if (item is Article) {
      return MutedUserProvider(
        pubkey: item.pubkey,
        child: (isMuted) => ArticleContainer(
          article: item,
          highlightedTag: '',
          isMuted: isMuted,
          isBookmarked: false,
          onClicked: () {
            Navigator.pushNamed(
              context,
              ArticleView.routeName,
              arguments: item,
            );
          },
          isFollowing: contactListCubit.contacts.contains(item.pubkey),
        ),
      );
    } else if (item is VideoModel) {
      final video = item;

      return MutedUserProvider(
        pubkey: item.pubkey,
        child: (isMuted) => VideoCommonContainer(
          isBookmarked: false,
          isMuted: isMuted,
          isFollowing: contactListCubit.contacts.contains(video.pubkey),
          video: video,
          onTap: () {
            Navigator.pushNamed(
              context,
              video.isHorizontal
                  ? HorizontalVideoView.routeName
                  : VerticalVideoView.routeName,
              arguments: [video],
            );
          },
        ),
      );
    } else if (item is Curation) {
      final curation = item;

      return MutedUserProvider(
        pubkey: item.pubkey,
        child: (isMuted) => CurationContainer(
          padding: 0,
          isProfileAccessible: true,
          isBookmarked: false,
          isMuted: isMuted,
          isFollowing: contactListCubit.contacts.contains(curation.pubkey),
          curation: curation,
          onClicked: () {
            YNavigator.pushPage(
              context,
              (context) => CurationView(curation: curation),
            );
          },
        ),
      );
    } else if (item is DetailedNoteModel) {
      return DetailedNoteContainer(
        key: ValueKey(item.id),
        note: item,
        isMain: false,
        addLine: false,
        enableReply: true,
        isExtended: true,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  List<dynamic> getFilteredContent(
    List<dynamic> totalContent,
    int contentType,
  ) {
    if (contentType == 3) {
      return totalContent.whereType<Article>().toList();
    } else if (contentType == 4) {
      return totalContent.whereType<VideoModel>().toList();
    } else if (contentType == 5) {
      return totalContent.whereType<Curation>().toList();
    } else if (contentType == 2) {
      return totalContent.whereType<DetailedNoteModel>().toList();
    } else if (contentType == 1) {
      return totalContent;
    } else {
      return [];
    }
  }
}
