import 'package:flutter/material.dart';

/// Gives the existing flexible forms room to lay out in short dialogs.
/// The entire form remains reachable by scrolling, including its actions.
class DesktopScrollableForm extends StatelessWidget {
  const DesktopScrollableForm({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 3.0);
        final minHeight = 600 * scale;
        return SingleChildScrollView(
          child: SizedBox(
            height: constraints.maxHeight > minHeight
                ? constraints.maxHeight
                : minHeight,
            child: child,
          ),
        );
      },
    );
  }
}
