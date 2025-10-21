import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/relay_feed_cubit/relay_feed_cubit.dart';
import '../../../models/article_model.dart';
import '../../../models/curation_model.dart';
import '../../../models/detailed_note_model.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/video_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../article_view/article_view.dart';
import '../../curation_view/curation_view.dart';
import '../../explore_relays_view/explore_relays_view.dart';
import '../../widgets/article_container.dart';
import '../../widgets/classic_footer.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/curation_container.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/note_stats.dart';
import '../../widgets/tag_container.dart';
import '../../widgets/video_common_container.dart';
import '../../widgets/video_components/horizontal_video_view.dart';
import '../../widgets/video_components/vertical_video_view.dart';

class RelayContentFeed extends StatefulWidget {
  const RelayContentFeed({
    super.key,
  });

  @override
  State<RelayContentFeed> createState() => _RelayContentFeedState();
}

class _RelayContentFeedState extends State<RelayContentFeed> {
  RelayContentType selectedExploreType = RelayContentType.all;
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
              child: NestedScrollView(
                controller: scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    if (relayInfoCubit.state.relayInfos[relay] != null)
                      _relayBox(context),
                    _appbar(context),
                  ];
                },
                body: state.onLoading
                    ? const ContentPlaceholder()
                    : const ContentList(),
              ),
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
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: RelayBox(
          relay: context.read<RelayFeedCubit>().relay,
          enableBrowse: false,
        ),
      ),
    );
  }

  String typeName(
      {required RelayContentType type, required BuildContext context}) {
    switch (type) {
      case RelayContentType.all:
        return context.t.all;
      case RelayContentType.articles:
        return context.t.articles;
      case RelayContentType.videos:
        return context.t.videos;
      case RelayContentType.curations:
        return context.t.curations;
      case RelayContentType.notes:
        return context.t.notes;
    }
  }
}

class ContentList extends StatelessWidget {
  const ContentList({
    super.key,
  });

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
          return EmptyList(
            description: context.t.noResultsNoFilterMessage,
            icon: LogosIcons.logoMarkWhite,
            title: context.t.noResults,
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

  Widget _itemsList(List<BaseEventModel> content) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: ListView.separated(
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

  Widget _itemsGrid(List<BaseEventModel> content) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        itemCount: content.length,
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
