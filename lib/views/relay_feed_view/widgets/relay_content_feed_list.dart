import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/relay_feed_cubit/relay_feed_cubit.dart';
import '../../../models/article_model.dart';
import '../../../models/curation_model.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/video_model.dart';
import '../../../utils/utils.dart';
import '../../article_view/article_view.dart';
import '../../curation_view/curation_view.dart';
import '../../widgets/article_container.dart';
import '../../widgets/curation_container.dart';
import '../../widgets/video_common_container.dart';
import '../../widgets/video_components/horizontal_video_view.dart';
import '../../widgets/video_components/vertical_video_view.dart';

class RelayContentFeedList extends StatelessWidget {
  const RelayContentFeedList({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<RelayFeedCubit, RelayFeedState>(
      builder: (context, state) {
        if (isTablet) {
          return SliverPadding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              itemBuilder: (context, index) {
                final item = state.content[index];

                return getItem(item);
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
                return const Divider(
                  thickness: 0.3,
                  height: kDefaultPadding * 1.5,
                );
              },
              itemBuilder: (context, index) {
                final item = state.content[index];

                return getItem(item);
              },
            ),
          );
        }
      },
    );
  }

  Widget getItem(BaseEventModel item) {
    return BlocBuilder<RelayFeedCubit, RelayFeedState>(
      builder: (context, state) {
        if (item is Article) {
          return ArticleContainer(
            article: item,
            highlightedTag: '',
            isMuted: false,
            isBookmarked: false,
            onClicked: () {
              Navigator.pushNamed(
                context,
                ArticleView.routeName,
                arguments: item,
              );
            },
            isFollowing: false,
          );
        } else if (item is VideoModel) {
          final video = item;

          return VideoCommonContainer(
            isBookmarked: false,
            video: video,
            isMuted: false,
            isFollowing: false,
            onTap: () {
              Navigator.pushNamed(
                context,
                video.isHorizontal
                    ? HorizontalVideoView.routeName
                    : VerticalVideoView.routeName,
                arguments: [video],
              );
            },
          );
        } else if (item is Curation) {
          final curation = item;

          return CurationContainer(
            curation: curation,
            isFollowing: false,
            isBookmarked: false,
            isProfileAccessible: false,
            onClicked: () {
              Navigator.pushNamed(
                context,
                CurationView.routeName,
                arguments: curation,
              );
            },
            padding: 0,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
