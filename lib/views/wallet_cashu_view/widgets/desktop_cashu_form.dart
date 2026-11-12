import 'package:flutter/material.dart';

import '../../../utils/platform_utils.dart';

/// Allows the fiat equivalent to wrap beneath SATS in narrow desktop forms.
class CashuAmountLine extends StatelessWidget {
  const CashuAmountLine({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing = 0,
    required this.children,
  });

  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isDesktopPlatform) {
      return Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: spacing,
          children: children,
        ),
      );
    }
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      spacing: spacing,
      children: children,
    );
  }
}
