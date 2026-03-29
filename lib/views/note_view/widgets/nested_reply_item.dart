import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../logic/notes_events_cubit/notes_events_cubit.dart';
import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/note_stats.dart'; // where DetailedNoteContainer lives

class NestedReplyItem extends HookWidget {
  const NestedReplyItem({
    super.key,
    required this.note,
    required this.setNote,
    required this.isTransitioning,
    required this.cachedReplies,
    this.isParent = true,
    this.depth = 0,
    this.isLastChild = false,
  });

  final DetailedNoteModel note;
  final bool isParent;
  final Function(DetailedNoteModel note, {bool isRemoving}) setNote;
  final bool isTransitioning;
  final int depth;
  final bool isLastChild;
  final Map<String, List<DetailedNoteModel>> cachedReplies;

  @override
  Widget build(BuildContext context) {
    final cached = cachedReplies[note.id];
    final replies = useState<List<DetailedNoteModel>>(cached ?? []);
    final isLoading = useState(cached == null && depth < 4);

    final updateReplies = useCallback(
      () async {
        if (!context.mounted || depth >= 4) {
          isLoading.value = false;
          return;
        }
        if (cached != null) {
          return;
        }

        isLoading.value = true;

        final evs =
            await context.read<NotesEventsCubit>().loadNoteRelatedEvents(
                  id: note.id,
                  type: NoteRelatedEventsType.replies,
                );

        if (!context.mounted) {
          return;
        }

        final newReplies = evs.map(DetailedNoteModel.fromEvent).toList();
        cachedReplies[note.id] = newReplies;
        replies.value = newReplies;
        isLoading.value = false;
      },
      [note.id, depth, cached],
    );

    useEffect(
      () {
        updateReplies();
        return null;
      },
      [note.id],
    );

    return BlocListener<NotesEventsCubit, NotesEventsState>(
      listenWhen: (prev, curr) =>
          prev.eventsStats[note.id] != curr.eventsStats[note.id] ||
          prev.mutes != curr.mutes ||
          prev.mutesEvents != curr.mutesEvents,
      listener: (_, __) => updateReplies(),
      child: Stack(
        children: [
          // The line drawing
          if (depth > 0)
            Positioned(
              top: 0,
              bottom: 0,
              left: 17.5,
              width: 17.5,
              child: CustomPaint(
                painter: _NestedLinePainter(
                  isLastChild: isLastChild,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          // Content
          Padding(
            padding: EdgeInsets.only(
              left: depth > 0 ? 35.0 : 0.0,
              top: isParent ? 0 : kDefaultPadding / 1.5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                DetailedNoteContainer(
                  note: note,
                  isMain: false,
                  addLine: replies.value.isNotEmpty,
                  onClicked: isTransitioning ? null : () => setNote(note),
                ),
                if (isLoading.value)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: kDefaultPadding),
                    child: Center(
                      child: SpinKitCircle(
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                  )
                else if (replies.value.isNotEmpty)
                  ...replies.value.asMap().entries.map(
                        (entry) => NestedReplyItem(
                          key: ValueKey(entry.value.id),
                          note: entry.value,
                          setNote: setNote,
                          isTransitioning: isTransitioning,
                          cachedReplies: cachedReplies,
                          depth: depth + 1,
                          isParent: false,
                          isLastChild: entry.key == replies.value.length - 1,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NestedLinePainter extends CustomPainter {
  _NestedLinePainter({
    required this.isLastChild,
    required this.color,
  });

  final bool isLastChild;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    const branchY = 30.0;
    final radius = size.width;

    if (isLastChild) {
      path.moveTo(0, 0);
      path.lineTo(0, branchY - radius);
      path.quadraticBezierTo(0, branchY, radius, branchY);
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);

      path.moveTo(0, branchY - radius);
      path.quadraticBezierTo(0, branchY, radius, branchY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NestedLinePainter oldDelegate) {
    return oldDelegate.isLastChild != isLastChild || oldDelegate.color != color;
  }
}
