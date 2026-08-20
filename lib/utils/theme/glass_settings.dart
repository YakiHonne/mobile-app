import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Per-component glass tuning.
///
/// Every glass surface in the app pulls its [LiquidGlassSettings] from here so
/// each one can be dialled independently. Entries start on [_base] — package
/// defaults with the tint pinned to the theme — and only override what they
/// need. Tune a single component by editing its entry, not [_base].
///
/// Three things make glass loud: the specular hotspot (`lightIntensity` +
/// `specularSharpness`), the Fresnel rim (`fresnelStrength` — the "border"),
/// and an oversaturated backdrop (`saturation`, package default 1.5).
class GlassSettings {
  const GlassSettings._();

  // ---------------------------------------------------------------- surfaces

  /// Main view app bar. Thicker and less saturated than the base so the
  /// toolbar reads as a distinct plate above the content.
  static LiquidGlassSettings appBar(BuildContext context) => _base(
        context,
        thickness: 30,
        blur: 3,
        chromaticAberration: 0.3,
        lightIntensity: 0.6,
        refractiveIndex: 1.59,
        saturation: 0.7,
        ambientStrength: 1,
        lightAngle: 0.75 * math.pi,
      );

  /// Inner-view app bars (`CustomAppBar`).
  static LiquidGlassSettings innerAppBar(BuildContext context) =>
      _base(context);

  /// Bottom navigation bar.
  static LiquidGlassSettings bottomBar(BuildContext context) => _base(context);

  /// Floating tab bar pill (`GlassTabBar.bottom`).
  static LiquidGlassSettings floatingTabBar(BuildContext context) =>
      _base(context);

  /// In-page tab switcher (`GlassTabBar.inline`).
  static LiquidGlassSettings inlineTabBar(BuildContext context) =>
      _base(context);

  /// Segmented control.
  static LiquidGlassSettings segmentedControl(BuildContext context) =>
      _base(context);

  // ------------------------------------------------------------- containers

  /// Generic glass panel (`FluidBlurContainer`).
  static LiquidGlassSettings container(BuildContext context) => _base(context);

  /// Floating card / panel.
  static LiquidGlassSettings card(BuildContext context) => _base(context);

  /// Grouped settings section.
  static LiquidGlassSettings groupedSection(BuildContext context) =>
      _base(context);

  static LiquidGlassSettings divider(BuildContext context) => _base(context);

  // ------------------------------------------------------------ interactive

  static LiquidGlassSettings button(BuildContext context) => _base(context);

  static LiquidGlassSettings iconButton(BuildContext context) => _base(context);

  static LiquidGlassSettings chip(BuildContext context) => _base(context);

  static LiquidGlassSettings glassSwitch(BuildContext context) =>
      _base(context);

  static LiquidGlassSettings slider(BuildContext context) => _base(context);

  // ----------------------------------------------------------------- inputs

  static LiquidGlassSettings searchBar(BuildContext context) =>
      const LiquidGlassSettings();

  // --------------------------------------------------------------- overlays

  static LiquidGlassSettings modalSheet(BuildContext context) => _base(context);

  /// ponytail: unused — dialogs stayed on CupertinoAlertDialog. Glass has no
  /// backdrop to refract over a dimmed barrier, so it reads as a faint outline.
  static LiquidGlassSettings dialog(BuildContext context) => _base(context);

  static LiquidGlassSettings menu(BuildContext context) => _base(context);

  static LiquidGlassSettings actionSheet(BuildContext context) =>
      _base(context);

  static LiquidGlassSettings progressIndicator(BuildContext context) =>
      _base(context);

  // ------------------------------------------------------------------- base

  /// Package defaults with the tint pinned to the theme — the `0x3DFFFFFF`
  /// white wash reads too bright over dark themes. Named arguments act as the
  /// `copyWith` that [LiquidGlassSettings] doesn't provide.
  static LiquidGlassSettings _base(
    BuildContext context, {
    double visibility = 1.0,
    Color? glassColor,
    double thickness = 20,
    double blur = 5,
    double chromaticAberration = .01,
    double? lightAngle,
    double lightIntensity = .5,
    double ambientStrength = 0,
    double ambientRim = 0,
    double fresnelStrength = 1.0,
    double refractiveIndex = 1.2,
    double saturation = 1.5,
    double glowIntensity = 0.75,
    GlassSpecularSharpness specularSharpness = GlassSpecularSharpness.medium,
    double standardOpacityMultiplier = 1.0,
    double shadowElevation = 1.0,
    List<BoxShadow>? shadow,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass tint per theme, chosen so the surface reads as glass rather than a
    // flat wash. The shader mixes `glassColor.rgb` into the blurred backdrop by
    // the color's alpha, and a chromatic tint hue-shifts (luminance-preserving)
    // instead of just dimming like flat black/white does.
    // - Light (white/cream): a cool near-white at 33% — clearly frosted over the
    //   bright scaffolds without going milky, and the cool hue stays readable on
    //   the warm cream theme. A flat white at ~21% vanished into the page.
    // - Dark (graphite/black): a neutral dark grey at 30% — clearly lifts the
    //   plate off the scaffold without a hue cast (the navy tint read blueish).
    //   A flat black disappears into the dark scaffold and reads muddy.
    return LiquidGlassSettings(
      visibility: visibility,
      glassColor: glassColor ??
          (isDark ? const Color(0x4D2A2A2A) : const Color(0x54EFF3FA)),
      thickness: thickness,
      blur: blur,
      chromaticAberration: chromaticAberration,
      lightAngle: lightAngle ?? GlassDefaults.lightAngle,
      lightIntensity: lightIntensity,
      ambientStrength: ambientStrength,
      ambientRim: ambientRim,
      fresnelStrength: fresnelStrength,
      refractiveIndex: refractiveIndex,
      saturation: saturation,
      glowIntensity: glowIntensity,
      specularSharpness: specularSharpness,
      standardOpacityMultiplier: standardOpacityMultiplier,
      shadowElevation: shadowElevation,
      shadow: shadow,
    );
  }
}
