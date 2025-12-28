// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../models/video_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/media_components/horizontal_video_view.dart';
import '../../widgets/media_components/vertical_video_view.dart';
import '../../widgets/video_common_container.dart';

class ProfileVideos extends StatelessWidget {
  const ProfileVideos({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

    return Scrollbar(
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) =>
            previous.isLoading != current.isLoading ||
            previous.content != current.content ||
            previous.user != current.user ||
            previous.bookmarks != current.bookmarks,
        builder: (context, state) {
          if (state.isLoading) {
            return const SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                child: ContentPlaceholder(),
              ),
            );
          } else {
            if (state.content.isEmpty) {
              return EmptyList(
                description: context.t
                    .userNoVideos(
                      name: state.user.getName(),
                    )
                    .capitalizeFirst(),
                icon: FeatureIcons.videoOcta,
              );
            } else {
              if (isTablet && !useSingleColumn) {
                return _itemsGrid(state);
              } else {
                return _itemsList(state);
              }
            }
          }
        },
      ),
    );
  }

  ListView _itemsList(ProfileState state) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        height: kDefaultPadding * 1.5,
        thickness: 0.5,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final event = state.content[index];
        final video = VideoModel.fromEvent(event);

        return VideoCommonContainer(
          isBookmarked: state.bookmarks.contains(video.id),
          video: video,
          isMuted: state.mutes.contains(video.pubkey),
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
      },
      itemCount: state.content.length,
    );
  }

  MasonryGridView _itemsGrid(ProfileState state) {
    return MasonryGridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      crossAxisSpacing: kDefaultPadding,
      mainAxisSpacing: kDefaultPadding,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding,
      ),
      itemBuilder: (context, index) {
        final event = state.content[index];
        final video = VideoModel.fromEvent(event);

        return VideoCommonContainer(
          isBookmarked: state.bookmarks.contains(video.id),
          isMuted: state.mutes.contains(video.pubkey),
          isFollowing: false,
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
        );
      },
      itemCount: state.content.length,
    );
  }
}
