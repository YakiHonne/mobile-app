// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/media_handler/media_handler.dart';
import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../utils/utils.dart';

class CameraOptions extends StatelessWidget {
  const CameraOptions({
    super.key,
    required this.pubkey,
    required this.onFailed,
    required this.onSuccess,
    this.replyId,
  });

  final String pubkey;
  final String? replyId;
  final Function() onFailed;
  final Function() onSuccess;

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
            child: PickChoice(
              pubkey: pubkey,
              replyId: replyId,
              onSuccess: onSuccess,
              onFailed: onFailed,
              icon: FeatureIcons.camera,
              title: context.t.image.capitalizeFirst(),
              mediaType: MediaType.cameraImage,
            ),
          ),
          const VerticalDivider(
            indent: kDefaultPadding / 2,
            endIndent: kDefaultPadding / 2,
          ),
          Expanded(
            child: PickChoice(
              pubkey: pubkey,
              replyId: replyId,
              onSuccess: onSuccess,
              onFailed: onFailed,
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
            child: PickChoice(
              pubkey: pubkey,
              replyId: replyId,
              onSuccess: onSuccess,
              onFailed: onFailed,
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

class PickChoice extends StatelessWidget {
  const PickChoice({
    super.key,
    required this.pubkey,
    required this.mediaType,
    required this.title,
    required this.icon,
    required this.replyId,
    required this.onSuccess,
    required this.onFailed,
    this.onClicked,
  });

  final String pubkey;
  final MediaType mediaType;
  final String title;
  final String icon;
  final String? replyId;
  final Function() onSuccess;
  final Function() onFailed;
  final Function()? onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClicked ??
          () async {
            final media = await MediaHandler.selectMedia(mediaType);

            if (media != null && context.mounted) {
              context.read<DmsCubit>().uploadMediaAndSend(
                    file: media,
                    pubkey: pubkey,
                    replyId: replyId,
                    onSuccess: onSuccess,
                    onFailed: onFailed,
                  );
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
