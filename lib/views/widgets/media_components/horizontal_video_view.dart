// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
// import 'package:last_pod_player/last_pod_player.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:numeral/numeral.dart';

import '../../../logic/horizontal_video_cubit/horizontal_video_cubit.dart';
import '../../../logic/notes_events_cubit/notes_events_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/video_model.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../buttons_containers_widgets.dart';
import '../content_stats.dart';
import '../custom_app_bar.dart';
import '../data_providers.dart';
import '../link_previewer.dart';
import '../no_content_widgets.dart';
import '../profile_picture.dart';
import 'horizontal_video_container.dart';

class HorizontalVideoView extends HookWidget {
  static const routeName = '/horizontalVideoView';
  static Route route(RouteSettings settings) {
    final items = settings.arguments! as List;

    return CupertinoPageRoute(
      builder: (_) => HorizontalVideoView(
        video: items[0],
      ),
    );
  }

  final VideoModel video;

  HorizontalVideoView({
    super.key,
    required this.video,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Video view');
  }

  @override
  Widget build(BuildContext context) {
    final videoSuggestions = useState(
      nostrRepository.getVideoSuggestions(
        video.id,
      ),
    );

    return BlocProvider(
      create: (context) => HorizontalVideoCubit(
        video: video,
      )..initView(),
      child: BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
        builder: (context, state) {
          return Scaffold(
            appBar: CustomAppBar(
              title: context.t.video.capitalizeFirst(),
            ),
            bottomNavigationBar: _bottomNavBar(context),
            body: isUserMuted(video.pubkey)
                ? Center(
                    child: MutedUserContent(
                      pubkey: video.pubkey,
                    ),
                  )
                : _content(videoSuggestions),
          );
        },
      ),
    );
  }

  Widget _content(ValueNotifier<List<VideoModel>> videoSuggestions) {
    return BlocBuilder<NotesEventsCubit, NotesEventsState>(
      buildWhen: (previous, current) =>
          current.eventsStats[video.getId()] !=
          previous.eventsStats[video.getId()],
      builder: (context, state) {
        return BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
          builder: (context, state) {
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: CustomVideoPlayer(
                    link: video.url,
                    removeBorders: true,
                    removePadding: true,
                    fallbackUrls: video.fallbackUrls,
                  ),
                ),
                _videoData(context, state),
                // SliverToBoxAdapter(
                //   child: GestureDetector(
                //     behavior: HitTestBehavior.translucent,
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         CupertinoPageRoute(
                //           builder: (_) => ContentThreadsView(
                //             aTag: video.id,
                //           ),
                //         ),
                //       );
                //     },
                //     child: Container(
                //       decoration: BoxDecoration(
                //         color: Theme.of(context).cardColor,
                //         borderRadius:
                //             BorderRadius.circular(kDefaultPadding / 2),
                //       ),
                //       padding: const EdgeInsets.all(kDefaultPadding / 2),
                //       margin: const EdgeInsets.symmetric(
                //         horizontal: kDefaultPadding / 2,
                //         vertical: kDefaultPadding / 2,
                //       ),
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           _replies(context, state),
                //           const SizedBox(
                //             height: kDefaultPadding / 2,
                //           ),
                //           if (state.replies.isEmpty)
                //             _noReplies(context)
                //           else
                //             _firstReply(state),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
                if (videoSuggestions.value.isNotEmpty) ...[
                  _videoSuggestions(context),
                  _videoSuggestionsList(videoSuggestions),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding,
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  SliverPadding _videoSuggestionsList(
      ValueNotifier<List<VideoModel>> videoSuggestions) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      sliver: SliverList.builder(
        itemBuilder: (context, index) {
          final video = videoSuggestions.value[index];

          return HorizontalVideoContainer(
            video: video,
            onClicked: () {
              Navigator.pushNamed(
                context,
                HorizontalVideoView.routeName,
                arguments: [
                  video,
                  <VideoModel>[],
                ],
              );
            },
          );
        },
        itemCount: videoSuggestions.value.length,
      ),
    );
  }

  SliverToBoxAdapter _videoSuggestions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        child: Column(
          children: [
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Row(
              children: [
                const Expanded(
                  child: Divider(
                    endIndent: kDefaultPadding,
                  ),
                ),
                Text(
                  context.t.seeAlso.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Expanded(
                  child: Divider(
                    indent: kDefaultPadding,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Builder _firstReply(HorizontalVideoState state) {
  //   return Builder(
  //     builder: (context) {
  //       final comment = state.replies.first;

  //       return MetadataProvider(
  //         pubkey: comment.pubkey,
  //         child: (metadata, nip05) {
  //           return Row(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               ProfilePicture2(
  //                 size: 25,
  //                 image: metadata.picture,
  //                 pubkey: metadata.pubkey,
  //                 padding: 0,
  //                 strokeWidth: 1,
  //                 strokeColor: Theme.of(context).primaryColorDark,
  //                 onClicked: () {},
  //               ),
  //               const SizedBox(
  //                 width: kDefaultPadding / 2,
  //               ),
  //               _replyMetadataRow(metadata, context, comment),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // Expanded _replyMetadataRow(
  //     Metadata metadata, BuildContext context, DetailedNoteModel comment) {
  //   return Expanded(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           metadata.getName(),
  //           style: Theme.of(context).textTheme.labelLarge!.copyWith(
  //                 fontWeight: FontWeight.w700,
  //                 height: 1,
  //               ),
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //         ),
  //         const SizedBox(
  //           height: kDefaultPadding / 4,
  //         ),
  //         Text(
  //           comment.content,
  //           style: Theme.of(context).textTheme.labelMedium,
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Column _noReplies(BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         context.t.noCommentsCanBeFound.capitalizeFirst(),
  //         style: Theme.of(context).textTheme.titleSmall!.copyWith(
  //               fontWeight: FontWeight.w800,
  //             ),
  //         textAlign: TextAlign.start,
  //       ),
  //       const SizedBox(
  //         height: kDefaultPadding / 4,
  //       ),
  //       Text(
  //         context.t.beFirstCommentThisVideo.capitalizeFirst(),
  //         style: Theme.of(context).textTheme.bodySmall!.copyWith(),
  //         textAlign: TextAlign.start,
  //       ),
  //     ],
  //   );
  // }

  // Row _replies(BuildContext context, HorizontalVideoState state) {
  //   return Row(
  //     children: [
  //       Text(
  //         context.t.comments.capitalizeFirst(),
  //         style: Theme.of(context).textTheme.labelMedium!.copyWith(
  //               fontWeight: FontWeight.w600,
  //             ),
  //       ),
  //       DotContainer(
  //         color: Theme.of(context).highlightColor,
  //         size: 3,
  //       ),
  //       Text(
  //         '${state.replies.length}',
  //         style: Theme.of(context).textTheme.labelMedium!.copyWith(
  //               fontWeight: FontWeight.w600,
  //               color: Theme.of(context).primaryColor,
  //             ),
  //       ),
  //     ],
  //   );
  // }

  SliverToBoxAdapter _videoData(
      BuildContext context, HorizontalVideoState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: MetadataProvider(
          pubkey: video.pubkey,
          search: false,
          child: (metadata, isNip05Valid) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _videoInfo(context, state),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                _actionsRow(metadata, context, isNip05Valid, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Row _actionsRow(Metadata metadata, BuildContext context, bool isNip05Valid,
      HorizontalVideoState state) {
    return Row(
      children: [
        ProfilePicture2(
          size: 30,
          image: metadata.picture,
          pubkey: metadata.pubkey,
          padding: 0,
          strokeWidth: 0,
          reduceSize: true,
          strokeColor: kTransparent,
          onClicked: () {
            openProfileFastAccess(
              context: context,
              pubkey: metadata.pubkey,
            );
          },
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        _metadataRow(metadata, context, isNip05Valid),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        _follow(state),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        _sendZap(context, state),
      ],
    );
  }

  NewBorderedIconButton _sendZap(
      BuildContext context, HorizontalVideoState state) {
    return NewBorderedIconButton(
      onClicked: () {
        showModalBottomSheet(
          elevation: 0,
          context: context,
          builder: (_) {
            return SendZapsView(
              metadata: state.author,
              isZapSplit: video.zapsSplits.isNotEmpty,
              zapSplits: video.zapsSplits,
              eventId: state.video.id,
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      icon: FeatureIcons.zaps,
      buttonStatus:
          !state.canBeZapped ? ButtonStatus.disabled : ButtonStatus.inactive,
    );
  }

  Builder _follow(HorizontalVideoState state) {
    return Builder(
      builder: (context) {
        final isDisabled = !canSign() || state.isSameArticleAuthor;

        return AbsorbPointer(
          absorbing: isDisabled,
          child: TextButton(
            onPressed: () {
              if (!canSign()) {
              } else {
                context.read<HorizontalVideoCubit>().setFollowingState();
              }
            },
            style: TextButton.styleFrom(
              visualDensity: const VisualDensity(
                vertical: -1,
              ),
              backgroundColor: isDisabled
                  ? Theme.of(context).highlightColor
                  : state.isFollowingAuthor
                      ? Theme.of(context).cardColor
                      : Theme.of(context).primaryColor,
            ),
            child: Text(
              state.isFollowingAuthor
                  ? context.t.unfollow.capitalizeFirst()
                  : context.t.follow.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: state.isFollowingAuthor
                        ? Theme.of(context).primaryColorDark
                        : kWhite,
                  ),
            ),
          ),
        );
      },
    );
  }

  Expanded _metadataRow(
      Metadata metadata, BuildContext context, bool isNip05Valid) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: Text(
              metadata.getName(),
              style: Theme.of(context).textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isNip05Valid)
            Row(
              children: [
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                SvgPicture.asset(
                  FeatureIcons.verified,
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  GestureDetector _videoInfo(BuildContext context, HorizontalVideoState state) {
    return GestureDetector(
      onTap: () {
        // showModalBottomSheet(
        //   context: context,
        //   elevation: 0,
        //   builder: (_) {
        //     return HVDescription(
        //       createdAt: video.createdAt,
        //       description: video.summary,
        //       title: video.title,
        //       tags: video.tags,
        //       upvotes: state.votes.values
        //           .map((element) => element.vote)
        //           .toList()
        //           .length
        //           .toString(),
        //       views: state.viewsCount.length.toString(),
        //     );
        //   },
        //   isScrollControlled: true,
        //   useRootNavigator: true,
        //   useSafeArea: true,
        //   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // );
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Row(
            children: [
              Text(
                context.t
                    .viewsNumber(
                      number: state.viewsCount.length.numeral(),
                    )
                    .capitalizeFirst(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              DotContainer(
                color: Theme.of(context).highlightColor,
                size: 3,
              ),
              Text(
                StringUtil.formatTimeDifference(video.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              Text(
                context.t.moreDots.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Visibility _bottomNavBar(BuildContext context) {
    return Visibility(
      visible: !isUserMuted(video.pubkey),
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: SizedBox(
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
}
