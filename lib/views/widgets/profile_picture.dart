// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import 'common_thumbnail.dart';

class ProfilePicture2 extends StatelessWidget {
  const ProfilePicture2({
    super.key,
    required this.size,
    required this.pubkey,
    required this.image,
    required this.padding,
    required this.strokeWidth,
    required this.strokeColor,
    required this.onClicked,
    this.backgroundColor,
    this.reduceSize,
  });

  final double size;
  final String image;
  final String pubkey;
  final double padding;
  final double strokeWidth;
  final Color strokeColor;
  final Color? backgroundColor;
  final bool? reduceSize;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onClicked,
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: size,
          width: size,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: strokeWidth, color: strokeColor),
            color: backgroundColor ?? Theme.of(context).primaryColorLight,
          ),
          child: RepaintBoundary(
            child: CommonThumbnail(
              image: image,
              radius: 1000,
              isRound: true,
              isPfp: true,
              height: size,
              width: size,
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePicture3 extends StatelessWidget {
  const ProfilePicture3({
    super.key,
    required this.size,
    required this.image,
    required this.pubkey,
    required this.padding,
    required this.strokeWidth,
    required this.strokeColor,
    required this.onClicked,
    this.backgroundColor,
    this.reduceSize,
  });

  final double size;
  final String image;
  final String pubkey;
  final double padding;
  final double strokeWidth;
  final Color strokeColor;
  final Color? backgroundColor;
  final bool? reduceSize;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onClicked,
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: size,
          width: size,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            border: Border.all(width: strokeWidth, color: strokeColor),
            color: backgroundColor ?? Theme.of(context).primaryColorLight,
          ),
          child: CommonThumbnail(
            image: image,
            radius: kDefaultPadding / 2,
            isRound: true,
            isPfp: true,
            height: size,
            width: size,
          ),
        ),
      ),
    );
  }
}
