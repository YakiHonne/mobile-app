import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/constants.dart';

class AnimatedPulseLine extends HookWidget {
  const AnimatedPulseLine({
    super.key,
    this.color = kMainColor,
    this.maxHeight = 2,
  });

  final Color color;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500),
    )..repeat(reverse: true); // back and forth

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = controller.value; // 0 → 1 → 0

        return CustomPaint(
          size: const Size(double.infinity, 5),
          painter: _PulseLinePainter(
            progress: progress,
            color: color,
            bgColor: Theme.of(context).scaffoldBackgroundColor,
            maxHeight: maxHeight,
          ),
        );
      },
    );
  }
}

class _PulseLinePainter extends CustomPainter {
  _PulseLinePainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.maxHeight,
  });

  final double progress;
  final Color color;
  final Color bgColor;
  final double maxHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final path = Path()..moveTo(0, y);

    final lineWidth = size.width;
    final pulseCenter = lineWidth * progress;

    // Build the pulse shape (triangle thickness)
    final gradient = LinearGradient(
      colors: [bgColor.withAlpha(0), color, bgColor.withAlpha(0)],
      stops: [
        (pulseCenter / lineWidth - 0.2).clamp(0.0, 1.0),
        (pulseCenter / lineWidth).clamp(0.0, 1.0),
        (pulseCenter / lineWidth + 0.2).clamp(0.0, 1.0),
      ],
    );

    final rect = Rect.fromLTWH(0, 0, lineWidth, size.height);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = maxHeight
      ..shader = gradient.createShader(rect);

    path.lineTo(lineWidth, y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseLinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.maxHeight != maxHeight;
}
