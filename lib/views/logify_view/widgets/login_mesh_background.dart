import 'dart:math' as math;

import 'package:flutter/material.dart';

class LoginMeshBackground extends StatefulWidget {
  const LoginMeshBackground({super.key});

  @override
  State<LoginMeshBackground> createState() => _LoginMeshBackgroundState();
}

class _LoginMeshBackgroundState extends State<LoginMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Node> _nodes;
  static const _dist = 140.0;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _nodes = List.generate(36, (_) => _Node());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _MeshPainter(_nodes, _dist, _size, primary),
          child: LayoutBuilder(
            builder: (context, constraints) {
              _size = Size(constraints.maxWidth, constraints.maxHeight);
              for (final n in _nodes) {
                n.tick(_size);
              }
              return const SizedBox.expand();
            },
          ),
        );
      },
    );
  }
}

class _Node {
  final _rng = math.Random();
  double x = 0, y = 0, vx = 0, vy = 0, r = 0;
  bool _init = false;

  void init(Size size) {
    x = _rng.nextDouble() * size.width;
    y = _rng.nextDouble() * size.height;
    vx = (_rng.nextDouble() - 0.5) * 0.35;
    vy = (_rng.nextDouble() - 0.5) * 0.35;
    r = _rng.nextDouble() * 1.2 + 0.4;
    _init = true;
  }

  void tick(Size size) {
    if (!_init || size.isEmpty) {
      init(size);
      return;
    }
    x += vx;
    y += vy;
    if (x < 0 || x > size.width) {
      vx *= -1;
    }
    if (y < 0 || y > size.height) {
      vy *= -1;
    }
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter(this.nodes, this.dist, this.size, this.primary);

  final List<_Node> nodes;
  final double dist;
  final Size size;
  final Color primary;

  @override
  void paint(Canvas canvas, Size s) {
    final linePaint = Paint()..strokeWidth = 0.7;
    final dotPaint = Paint()..color = primary.withValues(alpha: 0.28);

    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final dx = nodes[i].x - nodes[j].x;
        final dy = nodes[i].y - nodes[j].y;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < dist) {
          final alpha = ((1 - d / dist) * 0.14).clamp(0.0, 1.0);
          linePaint.color = primary.withValues(alpha: alpha);
          canvas.drawLine(
            Offset(nodes[i].x, nodes[i].y),
            Offset(nodes[j].x, nodes[j].y),
            linePaint,
          );
        }
      }
    }
    for (final n in nodes) {
      canvas.drawCircle(Offset(n.x, n.y), n.r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => true;
}
