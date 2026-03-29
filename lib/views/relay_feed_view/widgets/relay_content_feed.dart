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
import '../../widgets/article_container.dart';
import '../../widgets/classic_footer.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/curation_container.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';
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

class _RelayContentFeedState extends State<RelayContentFeed> {
  RelayContentType selectedExploreType = RelayContentType.notes;
  final scrollController = ScrollController();
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

            return SmartRefresher(
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
                    _nip43Action(context),
                    _appbar(context),
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
                )

                // ScrollShadow(
                //   color: Theme.of(context).scaffoldBackgroundColor,
                //   child: CustomScrollView(
                //     controller: scrollController,
                //     slivers: [
                //       if (state.onLoading)
                //         const SliverToBoxAdapter(child: ContentPlaceholder())
                //       else
                //         const ContentList(),
                //     ],
                //   ),
                // ),
                );
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius:
                              BorderRadius.circular(kDefaultPadding / 2),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 0.5,
                          ),
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4,
                        ),
                        padding: const EdgeInsets.all(kDefaultPadding / 2),
                        child: Row(
                          spacing: kDefaultPadding / 4,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              FeatureIcons.codeText,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
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
                        ),
                      ),
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius:
                            BorderRadius.circular(kDefaultPadding / 2),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 0.5,
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 4,
                      ),
                      padding: const EdgeInsets.all(kDefaultPadding / 2),
                      child: Row(
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
                                        SvgPicture.asset(
                                          FeatureIcons.log,
                                          width: 20,
                                          height: 20,
                                          colorFilter: const ColorFilter.mode(
                                            kRed,
                                            BlendMode.srcIn,
                                          ),
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
                                        SvgPicture.asset(
                                          FeatureIcons.log,
                                          width: 20,
                                          height: 20,
                                          colorFilter: ColorFilter.mode(
                                            Theme.of(context).primaryColorDark,
                                            BlendMode.srcIn,
                                          ),
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
                      ),
                    ),
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
                          title: context.t.joinRelay.capitalizeFirst(),
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
            child: Container(
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
              child: Row(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                      color: Theme.of(context).highlightColor,
                                    ),
                              ),
                            ],
                          ),
                  ),
                  SvgPicture.asset(
                    FeatureIcons.arrowRight,
                    width: 17,
                    height: 17,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).highlightColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              icon: LogosIcons.logoMarkWhite,
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
        separatorBuilder: (context, index) => const Divider(
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

  Padding _itemsGrid(List<BaseEventModel> content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: SliverMasonryGrid.count(
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
