import 'package:flutter/material.dart';

import '../../common/media_handler/media_handler.dart';
import '../../utils/utils.dart';

class MediaSelector extends StatelessWidget {
  const MediaSelector({
    super.key,
    required this.onSuccess,
  });

  final Function(List<String>) onSuccess;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
      child: Container(
        width: 100.w,
        margin: const EdgeInsets.all(kDefaultPadding),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding * 2),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    context.t.pickYourMedia.capitalizeFirst(),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  Text(
                    context.t.uploadSendMedia.capitalizeFirst(),
                    style: TextStyle(
                      color: Theme.of(context).highlightColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  _options(context),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IntrinsicHeight _options(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: MediaChoice(
              onSuccess: onSuccess,
              icon: FeatureIcons.camera,
              title: context.t.image.capitalizeFirst(),
              mediaType: MediaType.cameraImage,
              onClicked: () {},
            ),
          ),
          const VerticalDivider(
            indent: kDefaultPadding / 2,
            endIndent: kDefaultPadding / 2,
          ),
          Expanded(
            child: MediaChoice(
              onSuccess: onSuccess,
              icon: FeatureIcons.video,
              title: context.t.video.capitalizeFirst(),
              mediaType: MediaType.cameraVideo,
            ),
          ),
          const VerticalDivider(
            indent: kDefaultPadding / 2,
            endIndent: kDefaultPadding / 2,
          ),
          Expanded(
            child: MediaChoice(
              onSuccess: onSuccess,
              icon: FeatureIcons.image,
              title: context.t.gallery.capitalizeFirst(),
              mediaType: MediaType.gallery,
            ),
          ),
        ],
      ),
    );
  }
}

class MediaChoice extends StatelessWidget {
  const MediaChoice({
    super.key,
    required this.mediaType,
    required this.title,
    required this.icon,
    this.onClicked,
    required this.onSuccess,
  });

  final MediaType mediaType;
  final String title;
  final String icon;
  final Function()? onClicked;
  final Function(List<String>) onSuccess;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        if (mediaType == MediaType.gallery) {
          final medias = await MediaHandler.selectMultiMediaAndUpload();
          if (medias.isNotEmpty) {
            onSuccess.call(medias);
          }
        } else {
          final media = await MediaHandler.selectMediaAndUpload(mediaType);

          if (media != null) {
            onSuccess.call([media]);
          }
        }
      },
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
