import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HeartbeatFade extends HookWidget {
  const HeartbeatFade({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    final opacityAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(controller);

    useEffect(() {
      if (enabled) {
        controller.repeat(reverse: true);
      } else {
        controller.stop();
      }
      return null;
    }, [enabled]);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Opacity(
          opacity: enabled
              ? opacityAnimation.value
              : 1.0, // Fully visible if disabled
          child: child,
        );
      },
    );
  }
}

class RippleEffect extends HookWidget {
  const RippleEffect({
    super.key,
    required this.child,
    this.color = Colors.green,
    this.rippleCount = 2, // number of ripples
    this.minScale = 1.0,
    this.maxScale = 2.5,
    this.duration = const Duration(seconds: 2),
  });

  final Widget child;
  final Color color;
  final int rippleCount;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration)..repeat();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // multiple ripples
            for (int i = 0; i < rippleCount; i++)
              _buildRipple(controller, i / rippleCount),
            // child in center
            child,
          ],
        );
      },
    );
  }

  Widget _buildRipple(AnimationController controller, double offset) {
    final value = (controller.value + offset) % 1.0;
    final scale = minScale + (value * (maxScale - minScale));
    final opacity = 1 - value;

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity * 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
