// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../../logic/write_video_cubit/write_video_cubit.dart';
import '../../../../utils/bot_toast_util.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/link_previewer.dart';

class VideoContent extends HookWidget {
  const VideoContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final titleController = useTextEditingController(
        text: context.read<WriteVideoCubit>().state.title);

    return BlocBuilder<WriteVideoCubit, WriteVideoState>(
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
          children: [
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              controller: titleController,
              style: Theme.of(context).textTheme.bodyMedium,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Title',
              ),
              onChanged: (text) {
                context
                    .read<AddContentCubit>()
                    .setBottomNavigationBarState(false);
                context.read<WriteVideoCubit>().setTitle(text);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            if (state.videoUrl.isEmpty)
              const VideoSelectionContainer()
            else
              Stack(
                children: [
                  CustomVideoPlayer(link: state.videoUrl),
                  Positioned(
                    top: kDefaultPadding / 1.5,
                    left: kDefaultPadding / 4,
                    child: CustomIconButton(
                      onClicked: () {
                        context.read<WriteVideoCubit>().setUrl('');
                      },
                      icon: FeatureIcons.closeRaw,
                      size: 20,
                      backgroundColor: Theme.of(context)
                          .primaryColorLight
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
        );
      },
    );
  }
}

class VideoSelectionContainer extends HookWidget {
  const VideoSelectionContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final videoSourceType = useState<VideoSourceType?>(null);
    final videoUrlTextEditingController = useTextEditingController();

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          if (videoSourceType.value == null) ...[
            Text(
              context.t.pickYourVideo.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              context.t.canUploadPastLink.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            _viewGallery(context, videoSourceType),
          ] else
            _videoSourceTypes(videoSourceType, videoUrlTextEditingController),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
      ),
    );
  }

  Builder _videoSourceTypes(ValueNotifier<VideoSourceType?> videoSourceType,
      TextEditingController videoUrlTextEditingController) {
    return Builder(
      builder: (context) {
        return Column(
          children: [
            Text(
              videoSourceType.value == VideoSourceType.link
                  ? context.t.setUpYourLink.capitalize()
                  : context.t.setUpYourNevent.capitalize(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              videoSourceType.value == VideoSourceType.link
                  ? context.t.pasteYourLink.capitalizeFirst()
                  : context.t.pasteKind1063.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              controller: videoUrlTextEditingController,
              decoration: InputDecoration(
                hintText: videoSourceType.value == VideoSourceType.link
                    ? context.t.link
                    : context.t.nevent,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              onChanged: (text) {
                context.read<WriteVideoCubit>().setUrl(text);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _actionsRow(
                videoSourceType, context, videoUrlTextEditingController),
          ],
        );
      },
    );
  }

  Row _actionsRow(
      ValueNotifier<VideoSourceType?> videoSourceType,
      BuildContext context,
      TextEditingController videoUrlTextEditingController) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => videoSourceType.value = null,
            style: TextButton.styleFrom(
              backgroundColor: kRed,
            ),
            child: Text(
              context.t.cancel.capitalize(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: kWhite,
                  ),
            ),
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Expanded(
          child: TextButton(
            onPressed: () {
              final url = videoUrlTextEditingController.text.trim();
              if (url.isEmpty) {
                BotToastUtils.showError(
                  context.t.addProperUrlNevent.capitalizeFirst(),
                );
              } else {
                if (videoSourceType.value == VideoSourceType.link) {
                  context.read<WriteVideoCubit>().setUrl(url);
                } else {
                  context.read<WriteVideoCubit>().addFileMetadata(url);
                }
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColorDark,
            ),
            child: Text(
              context.t.submit.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).primaryColorLight,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  IntrinsicHeight _viewGallery(
      BuildContext context, ValueNotifier<VideoSourceType?> videoSourceType) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: VideoPickChoice(
              onClicked: () {
                context
                    .read<AddContentCubit>()
                    .setBottomNavigationBarState(false);
                context.read<WriteVideoCubit>().selectAndUploadVideo();
              },
              icon: FeatureIcons.videoGallery,
              title: context.t.gallery.capitalize(),
            ),
          ),
          const VerticalDivider(
            indent: kDefaultPadding / 2,
            endIndent: kDefaultPadding / 2,
          ),
          Expanded(
            child: VideoPickChoice(
              onClicked: () {
                context
                    .read<AddContentCubit>()
                    .setBottomNavigationBarState(false);
                videoSourceType.value = VideoSourceType.link;
              },
              icon: FeatureIcons.videoLink,
              title: context.t.link.capitalizeFirst(),
            ),
          ),
          const VerticalDivider(
            indent: kDefaultPadding / 2,
            endIndent: kDefaultPadding / 2,
          ),
          Expanded(
            child: VideoPickChoice(
              onClicked: () {
                context
                    .read<AddContentCubit>()
                    .setBottomNavigationBarState(false);
                videoSourceType.value = VideoSourceType.kind1063;
              },
              icon: FeatureIcons.share,
              title: context.t.fileSharing.capitalizeFirst(),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPickChoice extends StatelessWidget {
  const VideoPickChoice({
    super.key,
    required this.title,
    required this.icon,
    required this.onClicked,
  });

  final String title;
  final String icon;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClicked,
      child: Column(
        children: [
          SvgPicture.asset(
            icon,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
            width: 30,
            height: 30,
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          )
        ],
      ),
    );
  }
}
