// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

import './custom_dismissible.dart';
import './interactive_viewer_boundary.dart';

typedef IndexedFocusedWidgetBuilder = Widget Function(
    BuildContext context, int index, bool isFocus);

class YakiGallery<T> extends StatefulWidget {
  const YakiGallery({
    super.key,
    required this.sources,
    required this.initIndex,
    required this.itemBuilder,
    this.maxScale = 2.5,
    this.minScale = 1.0,
    this.onPageChanged,
    this.onDismissDragStart,
    this.onDismissDragCancel,
  });

  final List<T> sources;
  final int initIndex;
  final IndexedFocusedWidgetBuilder itemBuilder;
  final double maxScale;
  final double minScale;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onDismissDragStart;
  final VoidCallback? onDismissDragCancel;

  @override
  _YakiGalleryState createState() => _YakiGalleryState();
}

class _YakiGalleryState extends State<YakiGallery>
    with SingleTickerProviderStateMixin {
  PageController? _pageController;
  TransformationController? _transformationController;

  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  bool _enablePageView = true;

  // _enableDismiss is gone — CustomDismissible now owns pinch detection
  // internally via _hadMultiTouch and does not need an external prop for this.
  // We keep `enabled: true` permanently and let CustomDismissible sort it out.

  late Offset _doubleTapLocalPosition;
  int? currentIndex;
  int currentTouchPointNum = 0;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initIndex);
    _transformationController = TransformationController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )
      ..addListener(() {
        _transformationController!.value =
            _animation?.value ?? Matrix4.identity();
      })
      ..addStatusListener((AnimationStatus status) {
        // No longer need to re-enable dismiss here since CustomDismissible
        // manages that itself.
        if (status == AnimationStatus.completed) {
          if (_currentScale <= widget.minScale && !_enablePageView) {
            setState(() => _enablePageView = true);
          }
        }
      });

    currentIndex = widget.initIndex;
  }

  @override
  void dispose() {
    _pageController!.dispose();
    _animationController.dispose();
    _transformationController!.dispose();
    super.dispose();
  }

  void _onScaleChanged(double scale) {
    _currentScale = scale;
    final bool atBaseScale = scale <= widget.minScale;

    if (atBaseScale) {
      if (!_enablePageView && currentTouchPointNum <= 1) {
        setState(() => _enablePageView = true);
      }
    } else {
      if (_enablePageView) {
        setState(() => _enablePageView = false);
      }
    }
  }

  void _onLeftBoundaryHit() {
    if (!_enablePageView &&
        _pageController!.page!.floor() > 0 &&
        _currentScale <= 1.01) {
      setState(() => _enablePageView = true);
    }
  }

  void _onRightBoundaryHit() {
    if (!_enablePageView &&
        _pageController!.page!.floor() < widget.sources.length - 1 &&
        _currentScale <= 1.01) {
      setState(() => _enablePageView = true);
    }
  }

  void _onNoBoundaryHit() {
    if (_enablePageView && _currentScale > 1.01) {
      setState(() => _enablePageView = false);
    }
  }

  void _onPageChanged(int page) {
    setState(() => currentIndex = page);
    widget.onPageChanged?.call(page);

    if (_transformationController!.value != Matrix4.identity()) {
      _animation = Matrix4Tween(
        begin: _transformationController!.value,
        end: Matrix4.identity(),
      ).animate(
        CurveTween(curve: Curves.easeOut).animate(_animationController),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewerBoundary(
      controller: _transformationController,
      boundaryWidth: MediaQuery.of(context).size.width,
      onScaleChanged: _onScaleChanged,
      onLeftBoundaryHit: _onLeftBoundaryHit,
      onRightBoundaryHit: _onRightBoundaryHit,
      onNoBoundaryHit: _onNoBoundaryHit,
      maxScale: widget.maxScale,
      minScale: widget.minScale,
      child: Listener(
        // This Listener only tracks touch count for PageView/zoom purposes.
        // Dismiss logic is fully inside CustomDismissible now.
        onPointerDown: (event) {
          currentTouchPointNum++;
          if (currentTouchPointNum > 1 && _enablePageView) {
            setState(() => _enablePageView = false);
          }
        },
        onPointerUp: (event) {
          currentTouchPointNum = (currentTouchPointNum - 1).clamp(0, 10);
          if (currentTouchPointNum <= 1 &&
              _currentScale <= widget.minScale &&
              !_enablePageView) {
            setState(() => _enablePageView = true);
          }
        },
        child: CustomDismissible(
          onDismissed: () => Navigator.of(context).pop(),
          onDismissDragStart: () {
            widget.onDismissDragStart?.call();
            setState(() => _enablePageView = false);
          },
          onDismissDragCancel: () {
            widget.onDismissDragCancel?.call();
            setState(() => _enablePageView = true);
          },
          child: PageView.builder(
            onPageChanged: _onPageChanged,
            controller: _pageController,
            physics:
                _enablePageView ? null : const NeverScrollableScrollPhysics(),
            itemCount: widget.sources.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onDoubleTapDown: (TapDownDetails details) {
                  _doubleTapLocalPosition = details.localPosition;
                },
                onDoubleTap: onDoubleTap,
                child:
                    widget.itemBuilder(context, index, index == currentIndex),
              );
            },
          ),
        ),
      ),
    );
  }

  void onDoubleTap() {
    Matrix4 matrix = _transformationController!.value.clone();
    final double currentScale = matrix.row0.x;
    double targetScale = widget.minScale;

    if (currentScale <= widget.minScale) {
      targetScale = widget.maxScale * 0.7;
    }

    final double offSetX = targetScale == 1.0
        ? 0.0
        : -_doubleTapLocalPosition.dx * (targetScale - 1);
    final double offSetY = targetScale == 1.0
        ? 0.0
        : -_doubleTapLocalPosition.dy * (targetScale - 1);

    matrix = Matrix4.fromList([
      targetScale,
      matrix.row1.x,
      matrix.row2.x,
      matrix.row3.x,
      matrix.row0.y,
      targetScale,
      matrix.row2.y,
      matrix.row3.y,
      matrix.row0.z,
      matrix.row1.z,
      targetScale,
      matrix.row3.z,
      offSetX,
      offSetY,
      matrix.row2.w,
      matrix.row3.w,
    ]);

    _animation = Matrix4Tween(
      begin: _transformationController!.value,
      end: matrix,
    ).animate(
      CurveTween(curve: Curves.easeOut).animate(_animationController),
    );
    _animationController
        .forward(from: 0)
        .whenComplete(() => _onScaleChanged(targetScale));
  }
}
