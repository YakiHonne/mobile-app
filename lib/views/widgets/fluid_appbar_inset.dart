import 'package:flutter/material.dart';

/// Provides the current glass app bar top inset to descendant views.
/// When the glass app bar is visible, [inset] = kToolbarHeight + padding.top.
/// When hidden, [inset] = 0 so content fills the full screen.
class FluidAppBarInset extends InheritedWidget {
  const FluidAppBarInset({
    super.key,
    required this.inset,
    required super.child,
  });

  final double inset;

  static double of(BuildContext context) {
    final w = context
        .dependOnInheritedWidgetOfExactType<FluidAppBarInset>();
    return w?.inset ?? 0;
  }

  @override
  bool updateShouldNotify(FluidAppBarInset old) => old.inset != inset;
}
