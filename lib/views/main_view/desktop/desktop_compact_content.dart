import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../main.dart' show AppConstants;

/// Constrains wide desktop panels and exposes the resulting local width.
class DesktopCompactContent extends StatelessWidget {
  const DesktopCompactContent({super.key, required this.child});

  static const double maxWidth = 680;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(0.0, maxWidth);
          final media = MediaQuery.of(context);
          return Center(
            child: SizedBox(
              width: width,
              child: MediaQuery(
                data: media.copyWith(size: Size(width, media.size.height)),
                child: ResponsiveBreakpoints.builder(
                  breakpoints: AppConstants.responsiveBreakpoints,
                  child: child,
                ),
              ),
            ),
          );
        },
      );
}
