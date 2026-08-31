import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../utils/utils.dart';

/// Universal glass/fluid surface widget.
///
/// When [blur] is `true` (default): ClipRRect → BackdropFilter → Container
/// with the standard frosted-glass recipe.
/// When [blur] is `false`: same shape and border, solid background —
/// use for inner surfaces that sit above already-blurred content.
///
/// Advanced options:
/// - [customBorderRadius]: asymmetric corners (e.g. top-only rounded sheets).
/// - [customBorder]: asymmetric border (e.g. top/left/right only).
/// - [showBorder]: set `false` to omit the border entirely.
/// - [showDecoration]: set `false` to skip the Container wrapper entirely —
///   produces just ClipRRect → BackdropFilter → child (useful when the child
///   already carries its own visual decoration).
/// - [useClipRect]: set `true` to use `ClipRect` instead of `ClipRRect`
///   (full-width bars with no rounded clipping).
/// A container that replicates the fluid/glass TextButton background:
/// pill-shaped, gradient fill using [Theme.cardColor], and a top-only border.
/// No blur — use this to wrap arbitrary children that need the fluid button look.
class FluidCardContainer extends StatelessWidget {
  const FluidCardContainer({
    super.key,
    required this.child,
    this.borderRadius = 25.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.backgroundColor,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final cardColor = backgroundColor ?? Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: cardColor,
          border: Border(
            top: BorderSide(color: borderColor, width: 1.5),
            left: BorderSide(color: borderColor, width: 0.5),
            right: BorderSide(color: borderColor, width: 0.5),
            bottom: BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class FluidBlurContainer extends StatelessWidget {
  const FluidBlurContainer({
    super.key,
    required this.child,
    this.blur = true,
    this.borderRadius = 300.0,
    this.customBorderRadius,
    this.sigma = 16.0,
    this.backgroundAlpha = 0.55,
    this.padding,
    this.height,
    this.width,
    this.boxShadow,
    this.showBorder = true,
    this.customBorder,
    this.showDecoration = true,
    this.useClipRect = false,
    this.borderWidth,
    this.borderColor,
    this.backgroundLighten = 0.0,
  });

  final Widget child;

  /// Toggle backdrop blur. Set to `false` for inner / nested surfaces.
  final bool blur;

  /// Corner radius. Use `300` for a pill, `kDefaultPadding * 2` for a rounded
  /// card, etc. Ignored when [customBorderRadius] is set.
  final double borderRadius;

  /// Override [borderRadius] with an asymmetric [BorderRadius] (e.g. top-only).
  final BorderRadius? customBorderRadius;

  /// Blur intensity — 16 for small elements, 20 for large surfaces.
  final double sigma;

  /// Opacity of the background fill (0.0–1.0).
  final double backgroundAlpha;

  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final List<BoxShadow>? boxShadow;
  final double? borderWidth;
  final Color? borderColor;

  /// Set `false` to omit the border. Ignored when [customBorder] is set.
  final bool showBorder;

  /// Override the default `Border.all()` with a custom border.
  final BoxBorder? customBorder;

  /// Set `false` to skip the Container decoration entirely — only clips and
  /// blurs the child. [padding], [height], [width], and [backgroundAlpha]
  /// are ignored when `false`.
  final bool showDecoration;

  /// Use `ClipRect` (rectangular) instead of `ClipRRect` (rounded). Useful for
  /// full-width bars that should not clip child content at the corners.
  final bool useClipRect;

  /// Blend amount toward white (0.0-1.0) applied to the background fill —
  /// use to make a surface read as visibly lighter/more prominent.
  final double backgroundLighten;

  @override
  Widget build(BuildContext context) {
    final effectiveBR =
        customBorderRadius ?? BorderRadius.circular(borderRadius);

    // Minimal quality means "no shader, no BackdropFilter either" — the same
    // GPU-saving floor the user picked for the liquid_glass_widgets surfaces
    // applies here too, instead of this raw BackdropFilter ignoring it.
    final effectiveBlur =
        blur && themeCubit.state.glassQuality != GlassQuality.minimal;

    // Light themes let more of the (variable) content behind show through at
    // the same alpha, so black text can lose contrast; dark themes don't have
    // this problem since the blurred backdrop stays dark either way.
    // Without a blur, the fill is the only thing separating this surface from
    // whatever sits behind it (often the same scaffoldBackgroundColor, e.g.
    // the search pill over the main app bar) — push it near-solid so it
    // still reads as a distinct plate instead of blending in.
    final effectiveAlpha = effectiveBlur
        ? (themeCubit.isDark
            ? backgroundAlpha
            : (backgroundAlpha + 0.2).clamp(0.0, 1.0))
        : (backgroundAlpha + 0.35).clamp(0.0, 1.0);

    final baseColor = backgroundLighten > 0
        ? Color.lerp(
            Theme.of(context).scaffoldBackgroundColor,
            kWhite,
            backgroundLighten,
          )!
        : Theme.of(context).scaffoldBackgroundColor;

    final inner = showDecoration
        ? Container(
            height: height,
            width: width,
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: effectiveAlpha),
              borderRadius: useClipRect ? null : effectiveBR,
              border: customBorder ??
                  (showBorder
                      ? Border.all(
                          color: borderColor ?? Theme.of(context).dividerColor,
                          width: borderWidth ?? 0.5,
                        )
                      : null),
              boxShadow: boxShadow,
            ),
            child: child,
          )
        : child;

    final blurred = effectiveBlur
        ? BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: inner,
          )
        : inner;

    return useClipRect
        ? ClipRect(child: blurred)
        : ClipRRect(borderRadius: effectiveBR, child: blurred);
  }
}
