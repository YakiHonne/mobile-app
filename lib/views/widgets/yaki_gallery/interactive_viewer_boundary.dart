import 'package:flutter/material.dart';

typedef ScaleChanged = void Function(double scale);

class InteractiveViewerBoundary extends StatefulWidget {
  const InteractiveViewerBoundary({
    super.key,
    required this.child,
    required this.boundaryWidth,
    this.controller,
    this.onScaleChanged,
    this.onLeftBoundaryHit,
    this.onRightBoundaryHit,
    this.onNoBoundaryHit,
    this.maxScale,
    this.minScale,
  });

  final Widget child;
  final double boundaryWidth;
  final TransformationController? controller;
  final ScaleChanged? onScaleChanged;
  final VoidCallback? onLeftBoundaryHit;
  final VoidCallback? onRightBoundaryHit;
  final VoidCallback? onNoBoundaryHit;
  final double? maxScale;
  final double? minScale;

  @override
  InteractiveViewerBoundaryState createState() =>
      InteractiveViewerBoundaryState();
}

class InteractiveViewerBoundaryState extends State<InteractiveViewerBoundary> {
  TransformationController? _controller;
  double? _scale;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TransformationController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller!.dispose();
    }
    super.dispose();
  }

  void _updateBoundaryDetection() {
    final double scale = _controller!.value.row0[0];

    if (_scale != scale) {
      _scale = scale;
      widget.onScaleChanged?.call(scale);
    }

    if (scale <= 1.01) {
      return;
    }

    final double xOffset = _controller!.value.row0[3];
    final double boundaryWidth = widget.boundaryWidth;
    final double boundaryEnd = boundaryWidth * scale;
    final double xPos = boundaryEnd + xOffset;

    if (boundaryEnd.round() == xPos.round()) {
      widget.onLeftBoundaryHit?.call();
    } else if (boundaryWidth.round() == xPos.round()) {
      widget.onRightBoundaryHit?.call();
    } else {
      widget.onNoBoundaryHit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: widget.maxScale ?? 2.5,
      minScale: widget.minScale ?? 1.0,
      transformationController: _controller,
      onInteractionEnd: (_) => _updateBoundaryDetection(),
      child: widget.child,
    );
  }
}
