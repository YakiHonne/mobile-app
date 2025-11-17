import 'package:flutter/material.dart';

class DismissiblePage extends StatefulWidget {
  const DismissiblePage({
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
  DismissiblePageState createState() => DismissiblePageState();
}

class DismissiblePageState extends State<DismissiblePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animateController;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Decoration> _opacityAnimation;

  bool _dragUnderway = false;
  Offset _dragOffset = Offset.zero;
  bool get _isActive => _dragUnderway || _animateController.isAnimating;

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
    _animateController.dispose();
    super.dispose();
  }

  void _updateMoveAnimation() {
    final double endY = _dragOffset.dy.sign;
    final double endX =
        _dragOffset.dx.sign * (_dragOffset.dx.abs() / _dragOffset.dy.abs());

    _moveAnimation = _animateController.drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: Offset(endX, endY),
      ),
    );

    _scaleAnimation = _animateController.drive(Tween<double>(
      begin: 1,
      end: 0.5,
    ));

    _opacityAnimation = DecorationTween(
      begin: const BoxDecoration(
        color: Color(0xFF000000),
      ),
      end: const BoxDecoration(
        color: Color(0x00000000),
      ),
    ).animate(_animateController);
  }

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    widget.onDismissDragStart?.call();
    if (_animateController.isAnimating) {
      _animateController.stop();
    } else {
      _dragOffset = Offset.zero;
      _animateController.value = 0.0;
    }
    setState(_updateMoveAnimation);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isActive || _animateController.isAnimating) {
      return;
    }

    _dragUnderway = false;

    if (_animateController.isCompleted) {
      return;
    }

    if (!_animateController.isDismissed) {
      // if the dragged value exceeded the dismissThreshold, call onDismissed
      // else animate back to initial position.
      if (_animateController.value > widget.dismissThreshold) {
        widget.onDismissed?.call();
      } else {
        widget.onDismissDragCancel?.call();
        _animateController.reverse();
      }
    }
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
      onPointerMove: widget.enabled ? _onPointerMove : null,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: widget.enabled ? _handleDragStart : null,
        onVerticalDragEnd: widget.enabled ? _handleDragEnd : null,
        child: content,
      ),
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_dragUnderway) {
      final delta = event.delta;
      if (!_isActive || _animateController.isAnimating) {
        return;
      }
      _dragOffset += delta;

      setState(_updateMoveAnimation);

      if (!_animateController.isAnimating) {
        _animateController.value = _dragOffset.dy.abs() / context.size!.height;
      }
    }
  }
}
