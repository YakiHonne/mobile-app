// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import 'custom_icon_buttons.dart';

/// Add a dotted border around any [child] widget. The [strokeWidth] property
/// defines the width of the dashed border and [color] determines the stroke
/// paint color. [CircularIntervalList] is populated with the [dashPattern] to
/// render the appropriate pattern. The [radius] property is taken into account
/// only if the [borderType] is [BorderType.rRect]. A [customPath] can be passed in
/// as a parameter if you want to draw a custom shaped border.
///
/// part of 'dotted_border.dart';

typedef PathBuilder = Path Function(Size);

class _DashPainter extends CustomPainter {
  _DashPainter({
    this.strokeWidth = 2,
    this.dashPattern = const <double>[3, 1],
    this.color = Colors.black,
    this.borderType = BorderType.rect,
    this.radius = Radius.zero,
    this.strokeCap = StrokeCap.butt,
    this.customPath,
    this.padding = EdgeInsets.zero,
  }) : assert(dashPattern.isNotEmpty, 'Dash Pattern cannot be empty');

  final double strokeWidth;
  final List<double> dashPattern;
  final Color color;
  final BorderType borderType;
  final Radius radius;
  final StrokeCap strokeCap;
  final PathBuilder? customPath;
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size originalSize) {
    final Size size;
    if (padding == EdgeInsets.zero) {
      size = originalSize;
    } else {
      canvas.translate(padding.left, padding.top);
      size = Size(
        originalSize.width - padding.horizontal,
        originalSize.height - padding.vertical,
      );
    }

    final Paint paint = Paint()
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = strokeCap
      ..style = PaintingStyle.stroke;

    Path path;
    if (customPath != null) {
      path = dashPath(
        customPath!(size),
        dashArray: CircularIntervalList(dashPattern),
      );
    } else {
      path = _getPath(size);
    }

    canvas.drawPath(path, paint);
  }

  /// Returns a [Path] based on the the [borderType] parameter
  Path _getPath(Size size) {
    Path path;
    switch (borderType) {
      case BorderType.circle:
        path = _getCirclePath(size);
      case BorderType.rRect:
        path = _getRRectPath(size, radius);
      case BorderType.rect:
        path = _getRectPath(size);
      case BorderType.oval:
        path = _getOvalPath(size);
    }

    return dashPath(path, dashArray: CircularIntervalList(dashPattern));
  }

  /// Returns a circular path of [size]
  Path _getCirclePath(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double s = size.shortestSide;

    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w > s ? (w - s) / 2 : 0,
            h > s ? (h - s) / 2 : 0,
            s,
            s,
          ),
          Radius.circular(s / 2),
        ),
      );
  }

  /// Returns a Rounded Rectangular Path with [radius] of [size]
  Path _getRRectPath(Size size, Radius radius) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            0,
            0,
            size.width,
            size.height,
          ),
          radius,
        ),
      );
  }

  /// Returns a path of [size]
  Path _getRectPath(Size size) {
    return Path()
      ..addRect(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );
  }

  /// Return an oval path of [size]
  Path _getOvalPath(Size size) {
    return Path()
      ..addOval(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.dashPattern != dashPattern ||
        oldDelegate.padding != padding ||
        oldDelegate.borderType != borderType;
  }
}

class DottedBorder extends StatelessWidget {
  DottedBorder({
    super.key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.borderType = BorderType.rect,
    this.dashPattern = const <double>[3, 1],
    this.padding = const EdgeInsets.all(2),
    this.borderPadding = EdgeInsets.zero,
    this.radius = Radius.zero,
    this.strokeCap = StrokeCap.butt,
    this.customPath,
  }) {
    assert(_isValidDashPattern(dashPattern), 'Invalid dash pattern');
  }
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets borderPadding;
  final double strokeWidth;
  final Color color;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;
  final StrokeCap strokeCap;
  final PathBuilder? customPath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter: _DashPainter(
              padding: borderPadding,
              strokeWidth: strokeWidth,
              radius: radius,
              color: color,
              borderType: borderType,
              dashPattern: dashPattern,
              customPath: customPath,
              strokeCap: strokeCap,
            ),
          ),
        ),
        Padding(
          padding: padding,
          child: child,
        ),
      ],
    );
  }

  /// Compute if [dashPattern] is valid. The following conditions need to be met
  /// * Cannot be null or empty
  /// * If [dashPattern] has only 1 element, it cannot be 0
  bool _isValidDashPattern(List<double>? dashPattern) {
    final Set<double>? dashSet = dashPattern?.toSet();
    if (dashSet == null) {
      return false;
    }
    if (dashSet.length == 1 && dashSet.elementAt(0) == 0.0) {
      return false;
    }
    if (dashSet.isEmpty) {
      return false;
    }
    return true;
  }
}

/// The different supported BorderTypes
enum BorderType { circle, rRect, rect, oval }

class ModalBottomSheetHandle extends StatelessWidget {
  const ModalBottomSheetHandle({
    super.key,
    this.color,
    this.padding,
  });

  final Color? color;
  final double? padding;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding ?? kDefaultPadding / 2),
      child: Container(
        height: 5,
        width: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: color ?? Theme.of(context).highlightColor,
        ),
      ),
    );
  }
}

class ModalBottomSheetAppbar extends StatelessWidget {
  const ModalBottomSheetAppbar({
    super.key,
    this.onClicked,
    this.isBack = true,
    this.secondIcon,
    this.widget,
    this.onSecondClick,
    required this.title,
    this.padding,
  });

  final Function()? onClicked;
  final Function()? onSecondClick;
  final String? secondIcon;
  final bool isBack;
  final String title;
  final double? padding;
  final Widget? widget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: padding ?? kDefaultPadding / 2,
        horizontal: kDefaultPadding / 2,
      ),
      child: Stack(
        children: [
          const SizedBox(
            width: double.infinity,
            height: 40,
          ),
          Positioned.fill(
            child: Align(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding * 2,
                ),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: RotatedBox(
                quarterTurns: isBack ? 1 : 0,
                child: CustomIconButton(
                  onClicked: onClicked ??
                      () {
                        YNavigator.pop(context);
                      },
                  icon: isBack ? FeatureIcons.arrowDown : FeatureIcons.closeRaw,
                  size: 18,
                  vd: -1,
                  backgroundColor: Theme.of(context).cardColor,
                ),
              ),
            ),
          ),
          if (widget != null)
            Positioned.fill(
              child: Align(alignment: Alignment.centerRight, child: widget),
            ),
          if (secondIcon != null && onSecondClick != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: CustomIconButton(
                  onClicked: onSecondClick!,
                  icon: secondIcon!,
                  size: 18,
                  vd: -1,
                  backgroundColor: Theme.of(context).cardColor,
                ),
              ),
            )
        ],
      ),
    );
  }
}
