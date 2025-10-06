import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/discover_cubit/discover_cubit.dart';
import '../../../models/article_model.dart';
import '../../../models/curation_model.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/video_model.dart';
import '../../../utils/utils.dart';
import '../../article_view/article_view.dart';
import '../../curation_view/curation_view.dart';
import '../../widgets/article_container.dart';
import '../../widgets/curation_container.dart';
import '../../widgets/suggestions_box/multi_suggestion_box.dart';
import '../../widgets/video_common_container.dart';
import '../../widgets/video_components/horizontal_video_view.dart';
import '../../widgets/video_components/vertical_video_view.dart';

class ExploreFeed extends StatelessWidget {
  const ExploreFeed({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

    return BlocBuilder<DiscoverCubit, DiscoverState>(
      builder: (context, state) {
        if (isTablet && !useSingleColumn) {
          return SliverPadding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              itemBuilder: (context, index) {
                final item = state.content[index];

                return getItem(item, false);
              },
              childCount: state.content.length,
              crossAxisSpacing: kDefaultPadding,
              mainAxisSpacing: kDefaultPadding,
            ),
          );
        } else {
          return SliverPadding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            sliver: SliverList.separated(
              itemCount: state.content.length,
              separatorBuilder: (context, index) {
                if (index > 0 &&
                    index % suggestionDiscoverSeparatorCount == 0 &&
                    index < suggestionDiscoverSeparatorCount * 6) {
                  return MultiSuggestionBox(
                    index: index ~/ suggestionDiscoverSeparatorCount,
                    isLeading: false,
                  );
                } else {
                  return const Divider(
                    thickness: 0.3,
                    height: kDefaultPadding * 1.5,
                  );
                }
              },
              itemBuilder: (context, index) {
                final item = state.content[index];

                return getItem(item, isTablet);
              },
            ),
          );
        }
      },
    );
  }

  Widget getItem(BaseEventModel item, bool reduceImageSize) {
    return BlocBuilder<DiscoverCubit, DiscoverState>(
      builder: (context, state) {
        if (item is Article) {
          return ArticleContainer(
            article: item,
            highlightedTag: '',
            isMuted: state.mutes.contains(item.pubkey),
            isBookmarked: state.bookmarks.contains(item.identifier),
            onClicked: () {
              Navigator.pushNamed(
                context,
                ArticleView.routeName,
                arguments: item,
              );
            },
            isFollowing: state.followings.contains(item.pubkey),
            reduceImageSize: reduceImageSize,
          );
        } else if (item is VideoModel) {
          final video = item;

          return VideoCommonContainer(
            isBookmarked: state.bookmarks.contains(item.id),
            video: video,
            isMuted: state.mutes.contains(item.pubkey),
            isFollowing: state.followings.contains(item.pubkey),
            onTap: () {
              Navigator.pushNamed(
                context,
                video.isHorizontal
                    ? HorizontalVideoView.routeName
                    : VerticalVideoView.routeName,
                arguments: [video],
              );
            },
            reduceImageSize: reduceImageSize,
          );
        } else if (item is Curation) {
          final curation = item;

          return CurationContainer(
            curation: curation,
            isFollowing: state.followings.contains(item.pubkey),
            isBookmarked: state.bookmarks.contains(curation.identifier),
            isProfileAccessible: false,
            onClicked: () {
              Navigator.pushNamed(
                context,
                CurationView.routeName,
                arguments: curation,
              );
            },
            padding: 0,
            reduceImageSize: reduceImageSize,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
