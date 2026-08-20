import 'package:flutter/material.dart';

import '../../utils/utils.dart';

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
    final topRadius = Radius.circular(borderRadius);
    final br = BorderRadius.only(topLeft: topRadius, topRight: topRadius);
    final bSide = BorderSide(
      color: Theme.of(context).dividerColor,
      width: 0.5,
    );

    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: br,
        border: Border(top: bSide, left: bSide, right: bSide),
      ),
      width: double.infinity,
      height: height,
      padding: padding,
      child: child,
    );
  }
}
