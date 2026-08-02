// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../utils/utils.dart';
import 'animated_flip_counter.dart';
import 'app_icon.dart';

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    super.key,
    required this.onClicked,
    required this.icon,
    required this.size,
    required this.backgroundColor,
    this.iconColor,
    this.textColor,
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
    this.isGlass = false,
  });

  final Function() onClicked;
  final Function()? onLongPress;
  final Function()? onDoubleTap;
  final IconData icon;
  final double size;
  final Color backgroundColor;
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
  final bool isGlass;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: onLongPress,
        // Right-click is the desktop spelling of long-press (md/
        // DESKTOP_IMPLEMENTATION.md item 9). Every long-pressable icon button in
        // the app routes through here, so one line covers all of them instead of
        // 31 per-site GestureDetectors. Null on mobile, so the phone gesture
        // arena is untouched.
        onSecondaryTap: isDesktopPlatform ? onLongPress : null,
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
              else if (emoji != null)
                _emoji(context)
              else if (imageUrl != null)
                _image(context)
              else
                _icon(context),
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
    if (isGlass) {
      return ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        visualDensity:
            vd != null ? VisualDensity(vertical: vd!, horizontal: vd!) : null,
        backgroundBuilder: (context, states, child) {
          final bs = BorderSide(
            color: borderColor ?? Theme.of(context).dividerColor,
            width: borderWidth ?? 0.5,
          );

          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: bs.copyWith(width: 1),
                left: bs,
                right: bs,
                bottom: bs,
              ),
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  backgroundColor.withValues(alpha: 0.95),
                  backgroundColor,
                  backgroundColor.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.15, 1.0],
              ),
            ),
            child: child,
          );
        },
      );
    }

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

  AppIcon _icon(BuildContext context) {
    return AppIcon(
      icon,
      size: size,
      color: iconColor == kTransparent
          ? null
          : iconColor ?? Theme.of(context).primaryColorDark,
    );
  }

  ExtendedImage _image(BuildContext context) {
    return ExtendedImage.network(
      imageUrl!,
      width: size,
      height: size,
      // ponytail: decode at display size, not source size.
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      fit: BoxFit.cover,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return Center(
              child: SpinKitCircle(
                color: Theme.of(context).primaryColorDark,
                size: size,
              ),
            );

          case LoadState.failed:
            return _icon(context);

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
  final IconData icon;
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
            AppIcon(
              icon,
              size: size,
              color: iconColor ?? Theme.of(context).primaryColorDark,
            ),
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
}
