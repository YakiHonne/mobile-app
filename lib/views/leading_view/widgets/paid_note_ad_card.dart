import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/note_stats.dart';

class PaidNoteAdCard extends StatelessWidget {
  const PaidNoteAdCard({super.key, required this.event});
  final Event event;

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
        CustomPaint(
          foregroundPainter: const _CornerBracketsPainter(
            topLeftColor: Color(0xFF8B5CF6),
            bottomRightColor: Color(0xFFEC4899),
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
                  key: PageStorageKey<String>('ad_${event.id}'),
                  note: DetailedNoteModel.fromEvent(event),
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

/// Static L-shaped marks at the top-left (purple) and bottom-right (pink)
/// corners, mirroring PremiumContainer's bracket style.
class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter({
    required this.topLeftColor,
    required this.bottomRightColor,
  });

  final Color topLeftColor;
  final Color bottomRightColor;

  static const _radius = kDefaultPadding / 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    // Each arm gets its own linear gradient: opaque at the corner, fading to
    // transparent at the arm's tip. Per-arm (not radial) so a wide, short box
    // still fades along its vertical arms.
    final armX = size.width * 0.55;
    final armY = size.height * 0.55;

    void drawArm(Path path, Offset from, Offset to, Color color) {
      canvas.drawPath(
        path,
        Paint()
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..shader = ui.Gradient.linear(
            from,
            to,
            [color, color.withValues(alpha: 0)],
          ),
      );
    }

    // Top-left: horizontal arm (carries the corner arc) + vertical arm.
    drawArm(
      Path()
        ..moveTo(0, _radius)
        ..arcToPoint(
          const Offset(_radius, 0),
          radius: const Radius.circular(_radius),
        )
        ..lineTo(armX, 0),
      Offset.zero,
      Offset(armX, 0),
      topLeftColor,
    );
    drawArm(
      Path()
        ..moveTo(0, _radius)
        ..lineTo(0, armY),
      Offset.zero,
      Offset(0, armY),
      topLeftColor,
    );

    // Bottom-right: mirrored.
    drawArm(
      Path()
        ..moveTo(size.width, size.height - _radius)
        ..arcToPoint(
          Offset(size.width - _radius, size.height),
          radius: const Radius.circular(_radius),
        )
        ..lineTo(size.width - armX, size.height),
      Offset(size.width, size.height),
      Offset(size.width - armX, size.height),
      bottomRightColor,
    );
    drawArm(
      Path()
        ..moveTo(size.width, size.height - _radius)
        ..lineTo(size.width, size.height - armY),
      Offset(size.width, size.height),
      Offset(size.width, size.height - armY),
      bottomRightColor,
    );
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter oldDelegate) =>
      oldDelegate.topLeftColor != topLeftColor ||
      oldDelegate.bottomRightColor != bottomRightColor;
}
