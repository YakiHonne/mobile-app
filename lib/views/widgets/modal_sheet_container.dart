import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../utils/utils.dart';

/// Marks the shared desktop dialog surface so its root sheet does not draw a
/// second border or background inside the dialog padding.
class DesktopModalSurfaceScope extends InheritedWidget {
  const DesktopModalSurfaceScope({super.key, required super.child});

  @override
  bool updateShouldNotify(DesktopModalSurfaceScope oldWidget) => false;
}

/// Drop-in replacement for the [DraggableScrollableSheet] at the root of a modal
/// sheet body — same parameters, so migrating a body is a one-word rename.
///
/// Mobile is untouched. On desktop [showAdaptiveModal] presents the body as a
/// centered dialog, where dragging means nothing and a fractional child would
/// render at 70%-ish of the dialog box and leave a transparent gap. There the
/// content simply fills the card and gets a plain [ScrollController].
class AdaptiveDraggableSheet extends HookWidget {
  const AdaptiveDraggableSheet({
    super.key,
    required this.builder,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 1.0,
    // Same default as DraggableScrollableSheet, so this stays a rename-only
    // substitution at the call sites.
    this.expand = true,
    this.snap = false,
    this.snapSizes,
  });

  final ScrollableWidgetBuilder builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool expand;
  final bool snap;
  final List<double>? snapSizes;

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();

    if (isDesktopPlatform) {
      return builder(context, controller);
    }

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: expand,
      snap: snap,
      snapSizes: snapSizes,
      builder: builder,
    );
  }
}

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
    this.color,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? height;

  /// Defaults to the scaffold background so the sheet is opaque even when the
  /// host sheet is transparent (floating panels pass their own color).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final inDesktopSurface = isDesktopPlatform &&
        context.dependOnInheritedWidgetOfExactType<
                DesktopModalSurfaceScope>() !=
            null &&
        context.findAncestorWidgetOfExactType<ModalSheetContainer>() == null;
    final topRadius = Radius.circular(borderRadius);
    final br = BorderRadius.only(topLeft: topRadius, topRight: topRadius);
    final bSide = BorderSide(
      color: Theme.of(context).dividerColor,
      width: 0.5,
    );

    return Container(
      decoration: BoxDecoration(
        color: color ??
            (inDesktopSurface
                ? Colors.transparent
                : Theme.of(context).scaffoldBackgroundColor),
        borderRadius: inDesktopSurface ? null : br,
        border: inDesktopSurface
            ? null
            : Border(top: bSide, left: bSide, right: bSide),
      ),
      width: double.infinity,
      height: height,
      padding: padding,
      child: child,
    );
  }
}
