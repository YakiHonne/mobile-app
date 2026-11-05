import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../../../logic/video_controller_manager_cubit/video_controller_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/link_previewer.dart';
import '../../widgets/media_components/horizontal_video_view.dart';
import '../../widgets/media_components/vertical_video_view.dart';

/// Shared surface geometry for the desktop workspace and player.
const double kDesktopWorkspaceRadius = kDefaultPadding * 1.75;

/// Keeps the player below both panes while the navigation rail stays full height.
class DesktopContentArea extends StatelessWidget {
  const DesktopContentArea({
    super.key,
    required this.content,
    required this.player,
  });

  final Widget content;
  final Widget player;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: content),
          player,
        ],
      );
}

class DesktopNowPlayingBar extends StatelessWidget {
  const DesktopNowPlayingBar({super.key});

  static String _time(Duration duration) {
    final seconds = duration.inSeconds;
    final hours = seconds ~/ 3600;
    final minutes = (seconds ~/ 60) % 60;
    final remainder = seconds % 60;
    return hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}'
        : '$minutes:${remainder.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DesktopVideoSession?>(
      valueListenable: videoControllerManagerCubit.desktopNowPlaying,
      builder: (context, session, _) {
        final controller = videoControllerManagerCubit.desktopVideoController;
        if (session == null || controller == null) {
          return const SizedBox.shrink();
        }
        final video = session.video;
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final duration = value.duration.inMilliseconds;
            final position = value.position.inMilliseconds
                .clamp(0, duration > 0 ? duration : 0);
            final theme = Theme.of(context);
            void openVideo() {
              if (video != null) {
                YNavigator.pushNamed(
                  context,
                  video.isHorizontal
                      ? HorizontalVideoView.routeName
                      : VerticalVideoView.routeName,
                  arguments: [video],
                );
              } else {
                YNavigator.pushPage(
                  context,
                  (_) => Scaffold(
                    appBar:
                        CustomAppBar(title: context.t.video.capitalizeFirst()),
                    body: Center(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: RegularVideoPlayer(
                          link: session.url,
                          isNetwork: session.isNetwork,
                        ),
                      ),
                    ),
                  ),
                  pageName: 'DesktopInlineVideo',
                );
              }
            }

            return Padding(
              padding: const EdgeInsets.only(top: kDefaultPadding / 2),
              child: SizedBox(
                height: kDefaultPadding * 3,
                child: FluidBlurContainer(
                  sigma: 20,
                  borderRadius: kDesktopWorkspaceRadius,
                  child: Material(
                    color: Colors.transparent,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 700;
                        final hasThumbnail = video != null &&
                            !video.contentWarning &&
                            video.thumbnail.trim().isNotEmpty;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 1.5,
                            vertical: kDefaultPadding / 4,
                          ),
                          child: Row(
                            children: [
                              Tooltip(
                                message: context.t.open,
                                child: InkWell(
                                  onTap: openVideo,
                                  borderRadius: BorderRadius.circular(
                                      kDefaultPadding / 2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        kDefaultPadding / 2),
                                    child: SizedBox(
                                      width: 54,
                                      height: 42,
                                      child: hasThumbnail
                                          ? CommonThumbnail(
                                              image: video.thumbnail,
                                              width: 54,
                                              height: 42,
                                              fit: BoxFit.cover,
                                            )
                                          : ColoredBox(
                                              color: theme.cardColor,
                                              child: Icon(LucideIcons.video,
                                                  color: theme.hintColor),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: kDefaultPadding / 2),
                              SizedBox(
                                width: compact ? 120 : 180,
                                child: Tooltip(
                                  message: context.t.open,
                                  child: InkWell(
                                    onTap: openVideo,
                                    child: Text(
                                      video == null || video.title.isEmpty
                                          ? context.t.video.capitalizeFirst()
                                          : video.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: kDefaultPadding / 2),
                              IconButton(
                                tooltip: value.isPlaying
                                    ? context.t.desktopPause
                                    : context.t.desktopPlay,
                                onPressed: () => value.isPlaying
                                    ? controller.pause()
                                    : controller.play(),
                                color: theme.primaryColor,
                                iconSize: 32,
                                icon: Icon(value.isPlaying
                                    ? LucideIcons.circlePause
                                    : LucideIcons.circlePlay),
                              ),
                              const SizedBox(width: kDefaultPadding / 4),
                              Text(_time(value.position),
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: theme.hintColor)),
                              Expanded(
                                child: Slider(
                                  value: position.toDouble(),
                                  max: duration > 0 ? duration.toDouble() : 1,
                                  onChanged: duration > 0
                                      ? (v) => controller.seekTo(
                                          Duration(milliseconds: v.round()))
                                      : null,
                                ),
                              ),
                              Text(_time(value.duration),
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: theme.hintColor)),
                              const SizedBox(width: kDefaultPadding / 4),
                              IconButton(
                                tooltip: value.volume == 0
                                    ? context.t.unmute
                                    : context.t.mute,
                                onPressed: () => controller
                                    .setVolume(value.volume == 0 ? 1 : 0),
                                icon: Icon(value.volume == 0
                                    ? LucideIcons.volumeX
                                    : LucideIcons.volume2),
                              ),
                              IconButton(
                                tooltip: context.t.close,
                                onPressed: videoControllerManagerCubit
                                    .closeDesktopVideo,
                                icon: const Icon(LucideIcons.x),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
