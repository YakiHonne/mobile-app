// ignore_for_file: public_member_api_docs, sort_constructors_first, library_private_types_in_public_api
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:interactiveviewer_gallery_plus/hero_dialog_route.dart';
import 'package:interactiveviewer_gallery_plus/interactiveviewer_gallery_plus.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../common/media_handler/media_handler.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../../utils/video_utils.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/content_renderer/hidden_media_container.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/link_previewer.dart';

class GalleryImageView extends StatelessWidget {
  /// The image to display
  final Map<String, UrlType> media;

  /// The gallery width
  final double width;

  /// The gallery height
  final double height;

  /// The image BoxDecoration
  final BoxDecoration? imageDecoration;

  /// The image BoxFit
  final BoxFit boxFit;

  /// The Gallery short image is maximum 4 images.
  final bool shortImage;

  /// Font size
  final double fontSize;

  /// Text color
  final Color textColor;

  final Color seperatorColor;

  final bool isHidden;

  final bool invertColor;

  final Function(String) onDownload;

  const GalleryImageView({
    super.key,
    required this.media,
    this.boxFit = BoxFit.cover,
    this.imageDecoration,
    this.width = 100,
    this.height = 100,
    this.shortImage = true,
    this.fontSize = 32,
    required this.onDownload,
    required this.seperatorColor,
    this.textColor = Colors.white,
    required this.isHidden,
    required this.invertColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: _uiImage4(context),
    );
  }

  Widget _uiImage4(BuildContext context) {
    final int imgMore = media.length > 4 ? media.length - 4 : 0;

    return Container(
      decoration: BoxDecoration(
        color: seperatorColor,
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _firstRow(imgMore),
              if (media.length > 2) ...[
                Container(
                  height: 3,
                  width: double.infinity,
                  color: seperatorColor,
                ),
                _secondRaw(imgMore),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Expanded _secondRaw(int imgMore) {
    return Expanded(
      child: Row(
        children: [
          if (media.length > 2)
            Expanded(
              child: GalleryComponent(
                media: media,
                onDownload: onDownload,
                imageDecoration: imageDecoration,
                imgMore: imgMore,
                textColor: textColor,
                fontSize: fontSize,
                index: 2,
                isHidden: isHidden,
                invertColor: invertColor,
              ),
            ),
          if (media.length > 3) ...[
            Container(
              height: double.infinity,
              width: 3,
              color: seperatorColor,
            ),
            Expanded(
              child: GalleryComponent(
                media: media,
                onDownload: onDownload,
                imageDecoration: imageDecoration,
                imgMore: imgMore,
                textColor: textColor,
                fontSize: fontSize,
                index: 3,
                isHidden: isHidden,
                invertColor: invertColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Expanded _firstRow(int imgMore) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: GalleryComponent(
              media: media,
              onDownload: onDownload,
              imageDecoration: imageDecoration,
              imgMore: imgMore,
              textColor: textColor,
              fontSize: fontSize,
              index: 0,
              isHidden: isHidden,
              invertColor: invertColor,
            ),
          ),
          if (media.length > 1) ...[
            Container(
              height: double.infinity,
              width: 3,
              color: seperatorColor,
            ),
            Expanded(
              child: GalleryComponent(
                media: media,
                onDownload: onDownload,
                imageDecoration: imageDecoration,
                imgMore: imgMore,
                textColor: textColor,
                fontSize: fontSize,
                index: 1,
                isHidden: isHidden,
                invertColor: invertColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GalleryComponent extends HookWidget {
  const GalleryComponent({
    super.key,
    required this.media,
    required this.onDownload,
    required this.imageDecoration,
    required this.imgMore,
    required this.textColor,
    required this.fontSize,
    required this.index,
    required this.isHidden,
    required this.invertColor,
  });

  final Map<String, UrlType> media;
  final Function(String p1) onDownload;
  final BoxDecoration? imageDecoration;
  final int imgMore;
  final Color textColor;
  final double fontSize;
  final int index;
  final bool isHidden;
  final bool invertColor;

  @override
  Widget build(BuildContext context) {
    final entry = media.entries.toList()[index];
    final hideImageStatus = useState(isHidden);

    return GestureDetector(
      onTap: () => openGallery(
        source: entry,
        context: context,
        index: index,
        sources: media,
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: imageDecoration,
            child: Stack(
              children: [
                _thumbnail(entry, context),
                if (index >= 3)
                  Align(
                    child: Text(
                      imgMore >= 1 ? '+$imgMore' : '',
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        shadows: textShadow,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hideImageStatus.value && entry.value == UrlType.image)
            HiddenMediaContainer(
              hideImageStatus: hideImageStatus,
              invertColor: invertColor,
              useBorder: false,
              url: entry.key,
            ),
        ],
      ),
    );
  }

  Positioned _thumbnail(MapEntry<String, UrlType> entry, BuildContext context) {
    return Positioned.fill(
      child: entry.value == UrlType.image
          ? CommonThumbnail(
              image: entry.key,
              radius: 0,
              fit: BoxFit.cover,
              isRound: false,
            )
          : _videoImage(entry, context),
    );
  }

  FutureBuilder<String?> _videoImage(
    MapEntry<String, UrlType> entry,
    BuildContext context,
  ) {
    return FutureBuilder(
      future: VideoUtils.getVideoThumbnailImage(
        videoURL: entry.key,
        context: context,
      ),
      builder: (context, snapshot) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: kDimGrey2,
              child: snapshot.hasData && snapshot.data != null
                  ? ExtendedImage.file(
                      File(snapshot.data!),
                      fit: BoxFit.cover,
                      compressionRatio: 16 / 9,
                    )
                  : null,
            ),
            Positioned.fill(
              child: Align(
                child: Container(
                  decoration: BoxDecoration(
                    color: kBlack.withValues(alpha: 0.5),
                    borderRadius: BorderRadiusDirectional.circular(300),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: SvgPicture.asset(
                    FeatureIcons.videoOcta,
                    width: 25,
                    height: 25,
                    colorFilter: const ColorFilter.mode(
                      kWhite,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

void openGallery({
  required MapEntry<String, UrlType> source,
  required int index,
  required BuildContext context,
  Map<String, UrlType>? sources,
}) {
  final media = sources ?? {source.key: source.value};

  Navigator.of(context).push(
    HeroDialogRoute<void>(
      builder: (BuildContext context) {
        return OpenGalleryWidget(
          media: media.entries.toList(),
          index: index,
          entry: source,
        );
      },
    ),
  );
}

class OpenGalleryWidget extends HookWidget {
  const OpenGalleryWidget({
    super.key,
    required this.media,
    required this.index,
    required this.entry,
    this.isGallery = true,
    this.isRound = true,
    this.addBlackLayer = false,
  });

  final List<MapEntry<String, UrlType>> media;
  final MapEntry<String, UrlType> entry;
  final int index;
  final bool isGallery;
  final bool isRound;
  final bool addBlackLayer;

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(index);
    final currentSource = useState(entry);
    final bottomPadding = useState<double>(kBottomNavigationBarHeight);

    void calculateBottomPadding() {
      if (media[currentIndex.value].value == UrlType.video) {
        bottomPadding.value = kBottomNavigationBarHeight + 35;
      } else {
        bottomPadding.value = kBottomNavigationBarHeight;
      }
    }

    useMemoized(() {
      return () {
        calculateBottomPadding();
      };
    });

    return DisplayGesture(
      child: Stack(
        children: [
          _interactiveViewer(
            context,
            currentIndex,
            currentSource,
            calculateBottomPadding,
            isRound,
          ),
          if (addBlackLayer)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        kBlack,
                        kTransparent,
                      ],
                      stops: [0, 0.3],
                    ),
                  ),
                ),
              ),
            ),
          if (media.length > 1) _count(bottomPadding, context, currentIndex),
          _viewer(currentIndex, context, currentSource),
        ],
      ),
    );
  }

  Positioned _viewer(ValueNotifier<int> currentIndex, BuildContext context,
      ValueNotifier<MapEntry<String, UrlType>> currentSource) {
    return Positioned(
      top: 0,
      right: 0,
      left: 0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: media[currentIndex.value].value == UrlType.video
            ? const SizedBox(
                key: ValueKey('empty'),
              )
            : SafeArea(
                key: const ValueKey('safe_area'),
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  child: Row(
                    spacing: kDefaultPadding / 4,
                    children: [
                      CustomIconButton(
                        onClicked: () {
                          YNavigator.pop(context);
                        },
                        vd: -1,
                        icon: isGallery
                            ? FeatureIcons.closeRaw
                            : FeatureIcons.arrowLeft,
                        size: 20,
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                      const Spacer(),
                      CustomIconButton(
                        onClicked: () => MediaHandler.saveNetworkImage(
                          currentSource.value.key,
                        ),
                        vd: -1,
                        icon: FeatureIcons.download,
                        iconData: Icons.download_rounded,
                        size: 22,
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                      _pulldownButton(context, currentSource),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  PullDownButton _pulldownButton(BuildContext context,
      ValueNotifier<MapEntry<String, UrlType>> currentSource) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          PullDownMenuItem(
            title: context.t.copy.capitalizeFirst(),
            onTap: () => MediaUtils.copyImageToClipboard(entry.key),
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: SvgPicture.asset(
              FeatureIcons.copy,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
          PullDownMenuItem(
            title: context.t.share.capitalizeFirst(),
            onTap: () => MediaUtils.shareImage(currentSource.value.key),
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: SvgPicture.asset(
              FeatureIcons.shareGlobal,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => CustomIconButton(
        onClicked: showMenu,
        vd: -1,
        icon: FeatureIcons.more,
        size: 20,
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
  }

  AnimatedPositioned _count(ValueNotifier<double> bottomPadding,
      BuildContext context, ValueNotifier<int> currentIndex) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: bottomPadding.value,
      left: kDefaultPadding / 2,
      right: kDefaultPadding / 2,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              '${currentIndex.value + 1} / ',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              media.length.toString(),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).highlightColor,
                  ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: (currentIndex.value + 1) / media.length,
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(kDefaultPadding),
                backgroundColor: Theme.of(context).cardColor,
              ),
            )
          ],
        ),
      ),
    );
  }

  Positioned _interactiveViewer(
      BuildContext context,
      ValueNotifier<int> currentIndex,
      ValueNotifier<MapEntry<String, UrlType>> currentSource,
      Function() calculateBottomPadding,
      bool isRound) {
    return Positioned.fill(
      child: GestureDetector(
        onLongPress: () {
          MediaUtils.shareImage(currentSource.value.key);
        },
        child: InteractiveviewerGalleryPlus<MapEntry<String, UrlType>>(
          sources: media,
          initIndex: index,
          itemBuilder: (ctx, index, isFocus) {
            return itemBuilder(
              entry: media[index],
              context: context,
              isRound: isRound,
            );
          },
          onPageChanged: (int pageIndex) {
            currentIndex.value = pageIndex;
            currentSource.value = media[pageIndex];
            calculateBottomPadding();
          },
        ),
      ),
    );
  }
}

Widget itemBuilder({
  required MapEntry<String, UrlType> entry,
  required BuildContext context,
  required bool isRound,
}) {
  if (entry.value == UrlType.video) {
    return SafeArea(child: CustomVideoPlayer(link: entry.key));
  } else {
    return Builder(
      builder: (context) {
        return SafeArea(
          child: CommonThumbnail(
            image: entry.key,
            fit: BoxFit.contain,
            radius: isRound ? kDefaultPadding / 2 : 0,
            useDefaultNoMedia: false,
            isRound: isRound,
          ),
        );
      },
    );
  }
}

class DisplayGesture extends StatefulWidget {
  const DisplayGesture({super.key, this.child});

  final Widget? child;

  @override
  _DisplayGestureState createState() => _DisplayGestureState();
}

class _DisplayGestureState extends State<DisplayGesture> {
  List<PointerEvent> displayModelList = [];

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        displayModelList.add(event);
        setState(() {});
      },
      onPointerMove: (PointerMoveEvent event) {
        for (int i = 0; i < displayModelList.length; i++) {
          if (displayModelList[i].pointer == event.pointer) {
            displayModelList[i] = event;
            setState(() {});
            return;
          }
        }
      },
      onPointerUp: (PointerUpEvent event) {
        for (int i = 0; i < displayModelList.length; i++) {
          if (displayModelList[i].pointer == event.pointer) {
            displayModelList.removeAt(i);
            setState(() {});
            return;
          }
        }
      },
      child: widget.child,
    );
  }
}

const textShadow = <Shadow>[
  Shadow(offset: Offset(-2.0, 0.0), blurRadius: 4.0, color: Colors.black54),
  Shadow(offset: Offset(0.0, 2.0), blurRadius: 4.0, color: Colors.black54),
  Shadow(offset: Offset(2.0, 0.0), blurRadius: 4.0, color: Colors.black54),
  Shadow(offset: Offset(0.0, -2.0), blurRadius: 4.0, color: Colors.black54),
];
