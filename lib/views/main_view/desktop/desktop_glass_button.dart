import 'package:flutter/material.dart';

import '../../../utils/theme/custom/buttons_theme.dart';

/// Keeps the visible text-button surface aligned with adjacent glass icons.
class DesktopGlassButtonHeight extends StatelessWidget {
  const DesktopGlassButtonHeight({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kDesktopGlassButtonHeight),
        child: child,
      );
}
