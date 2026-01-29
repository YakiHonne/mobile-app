// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import 'animated_flip_counter.dart';

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    super.key,
    required this.onClicked,
    required this.icon,
    required this.size,
    required this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.iconData,
    this.imageUrl,
    this.widget,
    this.emoji,
    this.value,
    this.onLongPress,
    this.onDoubleTap,
    this.borderRadius,
    this.vd,
    this.borderColor,
    this.borderWidth,
    this.fontSize,
    this.blendMode,
  });

  final Function() onClicked;
  final Function()? onLongPress;
  final Function()? onDoubleTap;
  final String icon;
  final double size;
  final Color backgroundColor;
  final IconData? iconData;
  final String? imageUrl;
  final Widget? widget;
  final String? emoji;
  final Color? iconColor;
  final Color? textColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? borderWidth;
  final String? value;
  final double? vd;
  final double? fontSize;
  final BlendMode? blendMode;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        child: IconButton(
          onPressed: onClicked,
          padding: EdgeInsets.zero,
          style: _style(),
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget != null)
                widget!
              else if (iconData != null)
                Icon(
                  iconData,
                  size: size,
                  color: iconColor ?? Theme.of(context).primaryColorDark,
                )
              else if (emoji != null)
                _emoji(context)
              else if (imageUrl != null)
                _image(context)
              else
                _svg(context),
              if (value != null) ...[
                _text(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _style() {
    return IconButton.styleFrom(
      backgroundColor: backgroundColor,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: borderRadius != null
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius!),
            )
          : borderColor != null
              ? StadiumBorder(
                  side: BorderSide(
                    color: borderColor!,
                    width: borderWidth ?? 0.5,
                  ),
                )
              : null,
      visualDensity: vd != null
          ? VisualDensity(
              vertical: vd!,
              horizontal: vd!,
            )
          : null,
    );
  }

  RepaintBoundary _text(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 4,
        ),
        child: AnimatedFlipCounter(
          value: int.tryParse(value!) ?? 0,
          textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: fontSize,
              ),
          enableAbbreviation: true,
        ),
      ),
    );
  }

  SvgPicture _svg(BuildContext context) {
    return SvgPicture.asset(
      icon,
      width: size,
      height: size,
      colorFilter: iconColor == kTransparent
          ? null
          : ColorFilter.mode(
              iconColor ?? Theme.of(context).primaryColorDark,
              blendMode ?? BlendMode.srcIn,
            ),
    );
  }

  ExtendedImage _image(BuildContext context) {
    return ExtendedImage.network(
      imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return Center(
              child: SizedBox(
                width: size,
                height: size,
                child: const CircularProgressIndicator(),
              ),
            );

          case LoadState.failed:
            return SvgPicture.asset(
              icon,
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(
                iconColor ?? Theme.of(context).primaryColorDark,
                blendMode ?? BlendMode.srcIn,
              ),
            );

          case LoadState.completed:
            return null;
        }
      },
    );
  }

  SizedBox _emoji(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        child: Text(
          emoji!.trim(),
          style: TextStyle(
            fontSize: size * 6,
            color: iconColor ?? Theme.of(context).primaryColorDark,
            height: 1.0,
            textBaseline: TextBaseline.alphabetic,
          ),
        ),
      ),
    );
  }
}

class CustomIconButtonWithTooltip extends StatelessWidget {
  const CustomIconButtonWithTooltip({
    super.key,
    required this.onClicked,
    required this.message,
    required this.icon,
    required this.size,
    required this.backgroundColor,
    this.iconColor,
    this.value,
  });

  final Function() onClicked;
  final String message;
  final String icon;
  final double size;
  final Color backgroundColor;
  final Color? iconColor;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
      child: IconButton(
        onPressed: onClicked,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _svg(context),
            if (value != null) ...[
              _text(context),
            ],
          ],
        ),
      ),
    );
  }

  Padding _text(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 4),
      child: Text(
        value!,
        style: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }

  SvgPicture _svg(BuildContext context) {
    return SvgPicture.asset(
      icon,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        iconColor ?? Theme.of(context).primaryColorDark,
        BlendMode.srcIn,
      ),
    );
  }
}
