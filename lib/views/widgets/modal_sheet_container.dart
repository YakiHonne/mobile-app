import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import 'fluid_blur_container.dart';

/// Drop-in replacement for the boilerplate top-rounded [Container] used as the
/// root surface of every modal bottom sheet.
///
/// Normal mode: solid [scaffoldBackgroundColor] fill, top-only rounded corners,
/// 3-sided border (top + left + right — bottom edge is off-screen).
///
/// Fluid/glass mode: [FluidBlurContainer] with backdrop blur, same shape,
/// semi-transparent fill (backgroundAlpha 0.55).
///
/// Usage — replace the existing [Container] + [BoxDecoration] at the widget root:
/// ```dart
/// ModalSheetContainer(
///   child: ...,
/// )
/// ```
/// Keep any [Padding] for [MediaQuery.viewInsets.bottom] (keyboard) OUTSIDE.
class ModalSheetContainer extends StatelessWidget {
  const ModalSheetContainer({
    super.key,
    required this.child,
    this.borderRadius = kDefaultPadding,
    this.padding,
    this.height,
  });

  final Widget child;

  /// Corner radius for the top-left and top-right corners. Defaults to
  /// [kDefaultPadding] (20) — the standard throughout the app.
  final double borderRadius;

  /// Optional inner padding, forwarded to [FluidBlurContainer].
  final EdgeInsetsGeometry? padding;

  /// Optional fixed height, forwarded to [FluidBlurContainer].
  final double? height;

  @override
  Widget build(BuildContext context) {
    final fluid = isFluid();
    final topRadius = Radius.circular(borderRadius);
    final br = BorderRadius.only(topLeft: topRadius, topRight: topRadius);
    final bSide = BorderSide(
      color: Theme.of(context).dividerColor,
      width: 0.5,
    );

    return FluidBlurContainer(
      blur: fluid,
      sigma: 20,
      backgroundAlpha: fluid ? 0.55 : 1.0,
      customBorderRadius: br,
      customBorder: Border(top: bSide, left: bSide, right: bSide),
      width: double.infinity,
      height: height,
      padding: padding,
      child: child,
    );
  }
}
