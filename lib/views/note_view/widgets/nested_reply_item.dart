import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../logic/notes_events_cubit/notes_events_cubit.dart';
import '../../../logic/spam_filter/nspam_safety_service.dart';
import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/note_stats.dart'; // where DetailedNoteContainer lives
import 'show_potential_spam_replies_button.dart';

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
    this.isPotentialSpam = false,
  });

  final DetailedNoteModel note;
  final bool isParent;
  final Function(DetailedNoteModel note, {bool isRemoving}) setNote;
  final bool isTransitioning;
  final int depth;
  final bool isLastChild;
  final bool isPotentialSpam;
  final Map<String, List<DetailedNoteModel>> cachedReplies;

  @override
  Widget build(BuildContext context) {
    final spamFilter = NSpamSafetyService.instance;
    useListenable(spamFilter);

    final cached = cachedReplies[note.id];
    final replies = useState<List<DetailedNoteModel>>(<DetailedNoteModel>[]);
    final potentialSpamReplies =
        useState<List<DetailedNoteModel>>(<DetailedNoteModel>[]);
    final showPotentialSpamReplies = useState(false);
    final isLoading = useState(cached == null && depth < 2);

    final updateReplies = useCallback(
      () async {
        if (!context.mounted || depth >= 2) {
          isLoading.value = false;
          return;
        }

        isLoading.value = true;
        var rawReplies = cachedReplies[note.id];
        if (rawReplies == null) {
          final events =
              await context.read<NotesEventsCubit>().loadNoteRelatedEvents(
                    id: note.id,
                    type: NoteRelatedEventsType.replies,
                  );
          rawReplies = events.map(DetailedNoteModel.fromEvent).toList();
          cachedReplies[note.id] = rawReplies;
        }

        if (!context.mounted) {
          return;
        }
        final partition = await spamFilter.partitionReplies(rawReplies);
        if (!context.mounted) {
          return;
        }
        replies.value = partition.visibleReplies;
        potentialSpamReplies.value = partition.potentialSpamReplies;
        if (partition.potentialSpamReplies.isEmpty) {
          showPotentialSpamReplies.value = false;
        }
        isLoading.value = false;
      },
      [note.id, depth, spamFilter.revision],
    );

    useEffect(
      () {
        updateReplies();
        return null;
      },
      [note.id, spamFilter.revision],
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
                  isPotentialSpam: isPotentialSpam,
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
                if (replies.value.isNotEmpty &&
                    potentialSpamReplies.value.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: kDefaultPadding,
                      bottom: showPotentialSpamReplies.value
                          ? kDefaultPadding
                          : kDefaultPadding / 4,
                    ),
                    child: const Divider(
                      height: 1,
                      thickness: 0.3,
                    ),
                  ),
                if (potentialSpamReplies.value.isNotEmpty &&
                    !showPotentialSpamReplies.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 4),
                    child: ShowPotentialSpamRepliesButton(
                      count: potentialSpamReplies.value.length,
                      onPressed: () {
                        showPotentialSpamReplies.value = true;
                      },
                    ),
                  ),
                if (showPotentialSpamReplies.value)
                  ...potentialSpamReplies.value.map(
                    (reply) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NestedReplyItem(
                          key: ValueKey(reply.id),
                          note: reply,
                          isPotentialSpam: true,
                          setNote: setNote,
                          isTransitioning: isTransitioning,
                          cachedReplies: cachedReplies,
                          depth: depth + 1,
                          isParent: false,
                        ),
                      ],
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
