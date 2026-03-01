// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/material.dart';

class CustomDismissible extends StatefulWidget {
  const CustomDismissible({
    super.key,
    required this.child,
    this.onDismissed,
    this.onDismissDragStart,
    this.onDismissDragCancel,
    this.dismissThreshold = 0.2,
    this.enabled = true,
  });

  final Widget child;
  final double dismissThreshold;
  final VoidCallback? onDismissed;
  final VoidCallback? onDismissDragStart;
  final VoidCallback? onDismissDragCancel;
  final bool enabled;

  @override
  _CustomDismissibleState createState() => _CustomDismissibleState();
}

class _CustomDismissibleState extends State<CustomDismissible>
    with SingleTickerProviderStateMixin {
  late AnimationController _animateController;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Decoration> _opacityAnimation;

  // Drag state
  bool _dragUnderway = false;
  Offset _dragOffset = Offset.zero;
  Offset _initialPointerPos = Offset.zero;

  // Pointer tracking
  int _pointerCount = 0;
  bool _hadMultiTouch = false;

  // --- Android pinch gap compensation ---
  // On Android (Pixel), the OS can deliver two onPointerDown events for a
  // pinch up to ~150ms apart. During that gap, move events for finger 1
  // look identical to a dismiss swipe. We buffer those early move events
  // and only process them after a short delay, by which point finger 2
  // will have arrived (if this is a pinch) and set _hadMultiTouch = true.
  static const Duration _moveBufferDelay = Duration(milliseconds: 160);
  Timer? _moveBufferTimer;
  final List<PointerMoveEvent> _bufferedMoves = [];
  bool _gestureResolved = false; // true once we know single vs multi finger

  @override
  void initState() {
    super.initState();
    _animateController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _updateMoveAnimation();
  }

  @override
  void dispose() {
    _moveBufferTimer?.cancel();
    _animateController.dispose();
    super.dispose();
  }

  void _updateMoveAnimation() {
    final double endY = _dragOffset.dy.sign;
    final double endX = _dragOffset.dy.abs() < 0.001
        ? 0.0
        : _dragOffset.dx.sign * (_dragOffset.dx.abs() / _dragOffset.dy.abs());

    _moveAnimation = _animateController.drive(
      Tween<Offset>(begin: Offset.zero, end: Offset(endX, endY)),
    );
    _scaleAnimation = _animateController.drive(
      Tween<double>(begin: 1.0, end: 0.5),
    );
    _opacityAnimation = DecorationTween(
      begin: const BoxDecoration(color: Color(0xFF000000)),
      end: const BoxDecoration(color: Color(0x00000000)),
    ).animate(_animateController);
  }

  void _cancelActiveDrag() {
    if (_dragUnderway) {
      _dragUnderway = false;
      _animateController.reverse();
      widget.onDismissDragCancel?.call();
    }
  }

  void _resetGestureSession() {
    _moveBufferTimer?.cancel();
    _moveBufferTimer = null;
    _bufferedMoves.clear();
    _gestureResolved = false;
    _hadMultiTouch = false;
    _pointerCount = 0;
  }

  /// Called after the buffer delay. At this point we know whether a second
  /// finger arrived. If not, it's a real single-finger drag — process the
  /// buffered moves now.
  void _resolveGesture() {
    _gestureResolved = true;
    _moveBufferTimer = null;

    if (_hadMultiTouch) {
      // Second finger arrived during the buffer window — this is a pinch.
      // Discard all buffered moves.
      _bufferedMoves.clear();
      _cancelActiveDrag();
      return;
    }

    // It's a genuine single-finger gesture. Process buffered moves now.
    _bufferedMoves.forEach(_processMoveEvent);
    _bufferedMoves.clear();
  }

  void _processMoveEvent(PointerMoveEvent event) {
    if (!widget.enabled || _pointerCount != 1 || _hadMultiTouch) {
      _cancelActiveDrag();
      return;
    }

    final Offset delta = event.localPosition - _initialPointerPos;

    if (!_dragUnderway) {
      // Require a clear vertical intent before committing.
      final bool isVertical =
          delta.dy.abs() > 45 && delta.dy.abs() > delta.dx.abs() * 2.5;
      if (!isVertical) {
        return;
      }

      _dragUnderway = true;
      _dragOffset = Offset.zero;
      _animateController.value = 0.0;
      widget.onDismissDragStart?.call();
    }

    if (_animateController.isAnimating) {
      _animateController.stop();
    }

    _dragOffset = delta;
    setState(_updateMoveAnimation);
    _animateController.value =
        (_dragOffset.dy.abs() / context.size!.height).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = DecoratedBoxTransition(
      decoration: _opacityAnimation,
      child: SlideTransition(
        position: _moveAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _pointerCount++;

        if (_pointerCount == 1) {
          // First finger — start a fresh gesture session.
          _resetGestureSession();
          _initialPointerPos = event.localPosition;

          // Start the buffer timer. Move events are held until this fires
          // or a second finger arrives (whichever comes first).
          _moveBufferTimer = Timer(_moveBufferDelay, _resolveGesture);
        } else {
          // Second (or more) finger arrived — this is a pinch.
          _hadMultiTouch = true;
          _gestureResolved = true; // stop buffering, we know the answer

          // Cancel the pending timer — we already know it's multi-touch.
          _moveBufferTimer?.cancel();
          _moveBufferTimer = null;
          _bufferedMoves.clear();

          _cancelActiveDrag();
        }
      },
      onPointerMove: (event) {
        if (_pointerCount != 1 || _hadMultiTouch) {
          _cancelActiveDrag();
          return;
        }

        if (!_gestureResolved) {
          // Still inside the buffer window — accumulate but don't process.
          _bufferedMoves.add(event);
          return;
        }

        // Gesture already resolved as single-finger, process live.
        _processMoveEvent(event);
      },
      onPointerUp: (event) {
        _pointerCount = (_pointerCount - 1).clamp(0, 10);

        if (_pointerCount == 0) {
          final bool wasMultiTouch = _hadMultiTouch;
          _moveBufferTimer?.cancel();
          _moveBufferTimer = null;
          _bufferedMoves.clear();
          _gestureResolved = false;
          _hadMultiTouch = false;

          if (_dragUnderway && !wasMultiTouch) {
            _handleDragEnd();
          } else {
            _cancelActiveDrag();
          }
        }
      },
      onPointerCancel: (event) {
        _pointerCount = (_pointerCount - 1).clamp(0, 10);
        if (_pointerCount == 0) {
          _moveBufferTimer?.cancel();
          _moveBufferTimer = null;
          _bufferedMoves.clear();
          _gestureResolved = false;
          _hadMultiTouch = false;
        }
        _cancelActiveDrag();
      },
      child: content,
    );
  }

  void _handleDragEnd() {
    _dragUnderway = false;
    if (_animateController.isCompleted) {
      return;
    }

    if (!_animateController.isDismissed) {
      if (_animateController.value > widget.dismissThreshold) {
        widget.onDismissed?.call();
      } else {
        widget.onDismissDragCancel?.call();
        _animateController.reverse();
      }
    }
  }
}
