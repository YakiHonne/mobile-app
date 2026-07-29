import 'package:flutter/material.dart';

/// Wraps a scrollable modal's content so that pulling the content down while
/// it's already scrolled to the top closes the sheet.
///
/// Works inside a [TabBarView] where each tab keeps its own [ScrollController]
/// (so the [DraggableScrollableSheet] controller-handoff can't be used without
/// crashing on tab swipes). Instead it accumulates downward overscroll and pops
/// on release if the pull was intentional.
class SheetDragToClose extends StatefulWidget {
  const SheetDragToClose({super.key, required this.child});

  final Widget child;

  @override
  State<SheetDragToClose> createState() => _SheetDragToCloseState();
}

class _SheetDragToCloseState extends State<SheetDragToClose> {
  // ponytail: 80px pull-down at top closes; bump if accidental closes happen.
  static const double _closeThreshold = 80;

  double _pull = 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification && n.metrics.pixels > 0) {
          _pull = 0;
        } else if (n is OverscrollNotification && n.overscroll < 0) {
          _pull += -n.overscroll;
        } else if (n is ScrollEndNotification) {
          if (_pull > _closeThreshold) {
            Navigator.of(context).maybePop();
          }
          _pull = 0;
        }
        return false;
      },
      child: widget.child,
    );
  }
}
