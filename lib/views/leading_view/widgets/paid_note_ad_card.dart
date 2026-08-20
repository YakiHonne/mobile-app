import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/note_stats.dart';

class PaidNoteAdCard extends StatefulWidget {
  const PaidNoteAdCard({super.key, required this.event});
  final Event event;

  @override
  State<PaidNoteAdCard> createState() => _PaidNoteAdCardState();
}

class _PaidNoteAdCardState extends State<PaidNoteAdCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void initState() {
    super.initState();
    leadingCubit.markPaidNoteAdSeen(widget.event.id);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(
          thickness: 0.3,
          height: kDefaultPadding * 1.5,
          indent: kDefaultPadding * 3,
          endIndent: kDefaultPadding * 3,
        ),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => CustomPaint(
            foregroundPainter: _SpinningBorderPainter(
              rotation: _ctrl.value * 2 * math.pi,
            ),
            child: child,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
                left: BorderSide(
                  width: 0.5,
                  color: Theme.of(context).dividerColor,
                ),
                right: BorderSide(
                  width: 0.5,
                  color: Theme.of(context).dividerColor,
                ),
                bottom: BorderSide(
                  width: 0.5,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailedNoteContainer(
                  key: PageStorageKey<String>('ad_${widget.event.id}'),
                  note: DetailedNoteModel.fromEvent(widget.event),
                  isMain: false,
                  addLine: false,
                  isExtended: true,
                  showFollowButton: true,
                  onMuteActionSuccess: (_, __) {},
                ),
              ],
            ),
          ),
        ),
        const Divider(
          thickness: 0.3,
          height: kDefaultPadding * 1.5,
          indent: kDefaultPadding * 3,
          endIndent: kDefaultPadding * 3,
        ),
      ],
    );
  }
}

// Matches the web's paid-note-ad-border-spinner conic gradient, adapted from
// GlassButton's _BorderPainter: SweepGradient + GradientRotation + glow stroke.
class _SpinningBorderPainter extends CustomPainter {
  const _SpinningBorderPainter({required this.rotation});
  final double rotation;

  // Fractions of the CSS conic-gradient stops:
  //   transparent 0–300°, purple 330°, pink 345°, amber 355°, transparent 360°
  static const _colors = [
    Colors.transparent,
    Colors.transparent,
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Colors.transparent,
  ];

  static const _stops = [0.0, 0.667, 0.800, 0.900, 0.967, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));

    final gradient = SweepGradient(
      colors: _colors,
      stops: _stops,
      transform: GradientRotation(rotation),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..shader = gradient.createShader(rect),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SpinningBorderPainter old) => old.rotation != rotation;
}
