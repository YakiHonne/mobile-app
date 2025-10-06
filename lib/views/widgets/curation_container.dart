// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/curation_model.dart';
import '../../utils/utils.dart';
import 'content_container.dart';

class CurationContainer extends HookWidget {
  const CurationContainer({
    super.key,
    required this.curation,
    required this.onClicked,
    required this.padding,
    required this.isBookmarked,
    required this.isFollowing,
    required this.isProfileAccessible,
    this.margin,
    this.isMuted,
    this.reduceImageSize = false,
  });

  final Curation curation;
  final Function() onClicked;
  final double padding;
  final bool isBookmarked;
  final bool isFollowing;
  final bool isProfileAccessible;
  final double? margin;
  final bool? isMuted;
  final bool reduceImageSize;

  @override
  Widget build(BuildContext context) {
    return ContentContainer(
      id: curation.identifier,
      event: curation,
      kind: curation.kind,
      isSensitive: false,
      isFollowing: isFollowing,
      createdAt: curation.createdAt,
      title: curation.title,
      thumbnail: curation.image,
      description: curation.description,
      isBookmarked: isBookmarked,
      pubkey: curation.pubkey,
      contentType: ContentType.curation,
      onClicked: onClicked,
      attachedText: curation.kind == EventKind.CURATION_ARTICLES
          ? context.t
              .articlesNum(number: curation.eventsIds.length.toString())
              .capitalizeFirst()
          : context.t.videosNum(number: curation.eventsIds.length.toString())
        ..capitalizeFirst(),
      onProfileClicked: () {
        openProfileFastAccess(context: context, pubkey: curation.pubkey);
      },
      isMuted: isMuted,
    );
  }
}

class NoMediaPlaceHolder extends StatelessWidget {
  const NoMediaPlaceHolder({
    super.key,
    this.isRound,
    this.value,
    this.isTopRounded,
    this.isLeftRounded,
    this.height,
    this.width,
    this.useDefault = true,
    required this.isError,
    required this.image,
  });

  final bool? isRound;
  final bool? isTopRounded;
  final bool? isLeftRounded;
  final double? value;
  final bool isError;
  final String image;
  final double? height;
  final double? width;
  final bool useDefault;

  @override
  Widget build(BuildContext context) {
    final radius = isTopRounded != null
        ? BorderRadius.only(
            topLeft: Radius.circular(value ?? kDefaultPadding),
            topRight: Radius.circular(value ?? kDefaultPadding),
          )
        : isLeftRounded != null
            ? BorderRadius.only(
                topLeft: Radius.circular(value ?? kDefaultPadding),
                bottomLeft: Radius.circular(value ?? kDefaultPadding),
              )
            : BorderRadius.circular(
                isRound != null
                    ? isRound!
                        ? value ?? 300
                        : 0
                    : kDefaultPadding,
              );

    final s = useDefault
        ? ExtendedImage.asset(
            image.isEmpty ? randomCovers.first : image,
            fit: BoxFit.cover,
            shape: BoxShape.rectangle,
            borderRadius: radius,
          )
        : SizedBox(
            width: width,
            height: height,
            child: const NoImage2PlaceHolder(
              icon: FeatureIcons.noImage,
            ),
          );

    return height != null && width != null
        ? SizedBox(
            width: width,
            height: height,
            child: s,
          )
        : LayoutBuilder(builder: (context, constraints) => s);
  }
}

class LoadingMediaPlaceHolder extends StatelessWidget {
  const LoadingMediaPlaceHolder({
    super.key,
    this.isRound,
    this.value,
    this.isTopRounded,
    this.isLeftRounded,
    this.height,
    this.width,
    this.isPfp = false,
  });

  final bool? isRound;
  final bool? isTopRounded;
  final bool? isLeftRounded;
  final double? value;
  final double? height;
  final double? width;
  final bool isPfp;

  @override
  Widget build(BuildContext context) {
    final s = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: isTopRounded != null
            ? BorderRadius.only(
                topLeft: Radius.circular(value ?? kDefaultPadding),
                topRight: Radius.circular(value ?? kDefaultPadding),
              )
            : isLeftRounded != null
                ? BorderRadius.only(
                    topLeft: Radius.circular(value ?? kDefaultPadding),
                    bottomLeft: Radius.circular(value ?? kDefaultPadding),
                  )
                : BorderRadius.circular(
                    isRound != null
                        ? isRound!
                            ? value ?? 300
                            : 0
                        : kDefaultPadding,
                  ),
      ),
      child: isPfp
          ? Center(
              child: SpinKitCircle(
                color: Theme.of(context).primaryColorDark,
                size: 20,
              ),
            )
          : null,
    );

    return height != null && width != null
        ? SizedBox(
            width: width,
            height: height,
            child: s,
          )
        : LayoutBuilder(builder: (context, constraints) => s);
  }
}

class NoImagePlaceHolder extends StatelessWidget {
  const NoImagePlaceHolder({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          gradient: const LinearGradient(
            colors: [
              Color(0xffED213A),
              Color(0xff93291E),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: SvgPicture.asset(
              FeatureIcons.forbidden,
              colorFilter: const ColorFilter.mode(kWhite, BlendMode.srcIn),
              width: 30,
              height: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class NoImage2PlaceHolder extends StatelessWidget {
  const NoImage2PlaceHolder({
    super.key,
    required this.icon,
  });

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: SvgPicture.asset(
            icon,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
            width: 30,
            height: 30,
          ),
        ),
      ),
    );
  }
}

class ImageLoadingPlaceHolder extends StatelessWidget {
  const ImageLoadingPlaceHolder({
    super.key,
    this.round,
  });

  final double? round;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 25,
        height: 25,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: kWhite,
        ),
      ),
    );
  }
}

class NoThumbnailPlaceHolder extends StatelessWidget {
  const NoThumbnailPlaceHolder({
    super.key,
    this.isRound,
    this.value,
    this.isTopRounded,
    this.isRightRounded,
    this.isMonoColor,
    required this.isError,
    required this.icon,
  });

  final bool? isRound;
  final bool? isTopRounded;
  final bool? isRightRounded;
  final double? value;
  final String? icon;
  final bool? isMonoColor;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: isTopRounded != null
            ? const BorderRadius.only(
                topLeft: Radius.circular(kDefaultPadding),
                topRight: Radius.circular(kDefaultPadding),
              )
            : isRightRounded != null
                ? const BorderRadius.only(
                    bottomRight: Radius.circular(kDefaultPadding),
                    topRight: Radius.circular(kDefaultPadding),
                  )
                : BorderRadius.circular(
                    isRound != null
                        ? isRound!
                            ? value ?? 300
                            : 0
                        : kDefaultPadding,
                  ),
        gradient: isMonoColor == null
            ? const LinearGradient(
                colors: [
                  Color(0xff8E2DE2),
                  Color(0xff4B1248),
                ],
              )
            : null,
        color: isMonoColor != null ? kDimGrey2 : null,
      ),
      child: Center(
        child: SvgPicture.asset(
          icon != null && icon!.isNotEmpty ? icon! : LogosIcons.logoMarkWhite,
          colorFilter: const ColorFilter.mode(kWhite, BlendMode.srcIn),
          width: 35,
          height: 35,
        ),
      ),
    );
  }
}
