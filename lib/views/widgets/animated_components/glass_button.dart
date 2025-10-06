import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/utils.dart';

class GlassButton extends HookWidget {
  const GlassButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 3),
    )..repeat();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BorderPainter(
              rotation: controller.value * 6.28319,
              color: kMainColor,
              bgColor: Theme.of(context).scaffoldBackgroundColor,
              context: context,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 3,
                horizontal: kDefaultPadding,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              ),
              child: Text(
                context.t.redeem.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: kMainColor.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  _BorderPainter({
    required this.rotation,
    required this.color,
    required this.bgColor,
    required this.context,
  });

  final double rotation;
  final Color color;
  final Color bgColor;
  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final borderRadius = BorderRadius.circular(300);
    final path = Path()..addRRect(borderRadius.toRRect(rect));

    // Shared sweep gradient for both glow & main stroke
    final gradient = SweepGradient(
      endAngle: 6.28319,
      colors: [
        color.withValues(alpha: 0.9),
        bgColor.withAlpha(0),
        color.withValues(alpha: 0.9),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(rotation),
    );

    // Glow stroke (blurred, bigger)
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..shader = gradient.createShader(rect);

    // Main crisp stroke
    final mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = gradient.createShader(rect);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, mainPaint);
  }

  @override
  bool shouldRepaint(_BorderPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.color != color;
}
