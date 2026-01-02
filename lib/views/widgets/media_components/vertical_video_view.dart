// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

import '../../../logic/horizontal_video_cubit/horizontal_video_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/video_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../search_view/search_view.dart';
import '../buttons_containers_widgets.dart';
import '../content_stats.dart';
import '../custom_app_bar.dart';
import '../link_previewer.dart';
import '../no_content_widgets.dart';
import 'picture_view.dart';

class VerticalVideoView extends HookWidget {
  static const routeName = '/verticalVideoView';
  static Route route(RouteSettings settings) {
    final items = settings.arguments! as List;

    return CupertinoPageRoute(
      builder: (_) => VerticalVideoView(
        video: items[0],
        enableSound: items.length > 1 ? items[1] : false,
      ),
    );
  }

  final VideoModel video;
  final bool enableSound;

  VerticalVideoView({
    super.key,
    required this.video,
    this.enableSound = false,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Video view');
  }

  @override
  Widget build(BuildContext context) {
    useMemoized(
      () {
        if (enableSound) {
          videoControllerManagerCubit
              .getChewieController(video.url)
              ?.setVolume(1);
        }
      },
    );

    useEffect(() {
      return () {
        if (enableSound) {
          videoControllerManagerCubit
              .getChewieController(video.url)
              ?.setVolume(0);
        }
      };
    }, [video.url]);

    return BlocProvider(
      create: (context) => HorizontalVideoCubit(
        video: video,
      )..initView(),
      child: BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
        builder: (context, state) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: kBlack,
            appBar: CustomAppBar(
              title: context.t.video.capitalizeFirst(),
              color: kTransparent,
            ),
            bottomNavigationBar: _bottomNavBar(context),
            body: BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
              builder: (context, state) {
                return isUserMuted(video.pubkey)
                    ? Center(
                        child: MutedUserContent(
                          pubkey: video.pubkey,
                        ),
                      )
                    : _content(context, state);
              },
            ),
          );
        },
      ),
    );
  }

  Stack _content(BuildContext context, HorizontalVideoState state) {
    return Stack(
      children: [
        _videoPlayer(),
        _gradient(),
        Positioned(
          bottom: kDefaultPadding,
          left: kDefaultPadding / 2,
          right: kDefaultPadding / 2,
          child: MediaInfoColumn(
            pubkey: video.pubkey,
            title: video.title,
            content: video.summary,
            createdAt: video.createdAt,
            onFollowAction: () {},
          ),
        )
      ],
    );
  }

  // GestureDetector _videoInfoColumn(
  //     BuildContext context, HorizontalVideoState state) {
  //   return GestureDetector(
  //     onTap: () {
  //       showModalBottomSheet(
  //         context: context,
  //         elevation: 0,
  //         builder: (_) {
  //           return HVDescription(
  //             createdAt: video.createdAt,
  //             description: video.summary,
  //             title: video.title,
  //             tags: video.tags,
  //             upvotes: state.votes.values
  //                 .map((element) => element.vote)
  //                 .toList()
  //                 .length
  //                 .toString(),
  //             views: state.viewsCount.length.toString(),
  //           );
  //         },
  //         isScrollControlled: true,
  //         useRootNavigator: true,
  //         useSafeArea: true,
  //         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  //       );
  //     },
  //     behavior: HitTestBehavior.translucent,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         if (video.title.isNotEmpty) ...[
  //           Text(
  //             video.title.trim(),
  //             maxLines: 2,
  //             overflow: TextOverflow.ellipsis,
  //             style: Theme.of(context).textTheme.labelLarge!.copyWith(
  //               fontWeight: FontWeight.w600,
  //               shadows: [
  //                 Shadow(
  //                   color: Theme.of(context).primaryColorLight,
  //                   blurRadius: 2,
  //                 )
  //               ],
  //             ),
  //           ),
  //           const SizedBox(
  //             height: kDefaultPadding / 2,
  //           ),
  //         ],
  //         _videoStats(context, state),
  //       ],
  //     ),
  //   );
  // }

  // Row _videoStats(BuildContext context, HorizontalVideoState state) {
  //   return Row(
  //     children: [
  //       Text(
  //         context.t
  //             .viewsNumber(
  //               number: state.viewsCount.length.toString(),
  //             )
  //             .capitalizeFirst(),
  //         style: Theme.of(context).textTheme.labelSmall!.copyWith(
  //           shadows: [
  //             Shadow(
  //               color: Theme.of(context).primaryColorLight,
  //               blurRadius: 2,
  //             )
  //           ],
  //         ),
  //       ),
  //       DotContainer(
  //         color: Theme.of(context).highlightColor,
  //         size: 3,
  //       ),
  //       Text(
  //         StringUtil.formatTimeDifference(
  //           video.createdAt,
  //         ),
  //         style: Theme.of(context).textTheme.labelSmall!.copyWith(
  //           shadows: [
  //             Shadow(
  //               color: Theme.of(context).primaryColorLight,
  //               blurRadius: 2,
  //             )
  //           ],
  //         ),
  //       ),
  //       const SizedBox(
  //         width: kDefaultPadding / 4,
  //       ),
  //       Text(
  //         context.t.moreDots.capitalizeFirst(),
  //         style: Theme.of(context).textTheme.labelSmall!.copyWith(
  //           fontWeight: FontWeight.w600,
  //           shadows: [
  //             Shadow(
  //               color: Theme.of(context).primaryColorLight,
  //               blurRadius: 2,
  //             )
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Positioned _gradient() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kBlack,
                kBlack.withValues(alpha: 0.1),
                kTransparent,
                kBlack.withValues(alpha: 0.1),
                kBlack,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );
  }

  Visibility _bottomNavBar(BuildContext context) {
    return Visibility(
      visible: !isUserMuted(video.pubkey),
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        height:
            kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
        child: Column(
          children: [
            const Divider(
              height: 0,
              thickness: 0.5,
            ),
            SizedBox(
              height: kBottomNavigationBarHeight,
              child: ContentStats(
                attachedEvent: video,
                pubkey: video.pubkey,
                kind: video.kind,
                identifier: video.id,
                createdAt: video.createdAt,
                title: video.title,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LayoutBuilder _videoPlayer() {
    return LayoutBuilder(
      builder: (context, constraints) => CustomVideoPlayer(
        link: video.url,
        ratio: constraints.maxWidth / constraints.maxHeight,
        removePadding: true,
        removeBorders: true,
        removeControls: true,
        fallbackUrls: video.fallbackUrls,
      ),
    );
  }
}

class MediaTagsRow extends StatelessWidget {
  const MediaTagsRow({
    super.key,
    required this.tags,
  });

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ScrollShadow(
        color: Theme.of(context).primaryColorLight,
        size: 10,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tags.length,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          separatorBuilder: (context, index) {
            return const SizedBox(
              width: kDefaultPadding / 4,
            );
          },
          itemBuilder: (context, index) {
            final tag = tags[index];
            if (tag.trim().isEmpty) {
              return const SizedBox.shrink();
            }

            return Center(
              child: InfoRoundedContainer(
                tag: tag,
                useOpacity: true,
                color: Theme.of(context).cardColor,
                textColor: Theme.of(context).primaryColorDark,
                onClicked: () {
                  YNavigator.pushPage(
                    context,
                    (context) => SearchView(
                      search: tag,
                      index: 3,
                    ),
                    type: PushPageType.opacity,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
