import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../logic/second_reader_cubit/second_reader_cubit.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/common_thumbnail.dart';
import 'sheet_header.dart';

class SecondReaderActiveView extends StatelessWidget {
  const SecondReaderActiveView({
    super.key,
    required this.content,
    required this.onFixWithAi,
  });
  final String content;
  final void Function(String prefill) onFixWithAi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SecondReaderCubit, SecondReaderState>(
      builder: (ctx, state) {
        final cubit = ctx.read<SecondReaderCubit>();
        final persona = state.activePersona;
        if (persona == null) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SecondReaderSheetHeader(
              title: context.t.second_reader_title,
              trailing: state.reactions.isNotEmpty
                  ? TextButton(
                      onPressed: cubit.clearReactions,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.07),
                        padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 2),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : null,
            ),
            Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
            Flexible(
              child: state.reactions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(kDefaultPadding * 2),
                        child: Text(
                          context.t.second_reader_no_reactions,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.hintColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        kDefaultPadding,
                        kDefaultPadding * 0.75,
                        kDefaultPadding,
                        kDefaultPadding,
                      ),
                      children: [
                        ...state.activeReactions.map(
                          (r) => ReactionCard(
                            reaction: r,
                            onFix: () {
                              cubit.markFixed(r);
                              Navigator.of(context).pop();
                              onFixWithAi(
                                context.t.ask_ai_prefill_fix(
                                  index: r.paragraphIndex + 1,
                                  comment: r.comment,
                                ),
                              );
                            },
                            onIgnore: () => cubit.ignore(r),
                          ),
                        ),
                        if (state.resolvedReactions.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: kDefaultPadding / 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: theme.dividerColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: kDefaultPadding / 2),
                                  child: Text(
                                    context.t.second_reader_resolved(
                                      count: state.resolvedReactions.length,
                                    ),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: theme.dividerColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...state.resolvedReactions.map(
                            (r) => ReactionCard(
                              reaction: r,
                              onFix: () => cubit.markFixed(r),
                              onIgnore: () => cubit.ignore(r),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                kDefaultPadding,
                kDefaultPadding,
                kDefaultPadding / 2,
                MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonThumbnail(
                    image: persona.imageUrl,
                    width: 58,
                    isRound: true,
                    radius: 29,
                  ),
                  const SizedBox(width: kDefaultPadding / 2 + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona.name,
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: kDefaultPadding / 4 - 4),
                        Text(
                          persona.role,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: kDefaultPadding / 4 - 2),
                        Text(
                          persona.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: cubit.switchToPicker,
                    style: TextButton.styleFrom(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding / 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      context.t.second_reader_switch,
                      style: TextStyle(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ReactionCard extends StatelessWidget {
  const ReactionCard({
    super.key,
    required this.reaction,
    required this.onFix,
    required this.onIgnore,
  });

  final PersonaReaction reaction;
  final VoidCallback onFix;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isResolved = reaction.status != ReactionStatus.active;

    final (Color accentColor, Color bgTint) = switch (reaction.severity) {
      ReactionSeverity.critical => (
          Colors.red,
          Colors.red.withValues(alpha: 0.05)
        ),
      ReactionSeverity.warning => (
          Colors.orange,
          Colors.orange.withValues(alpha: 0.05)
        ),
      ReactionSeverity.info => (theme.primaryColor, Colors.transparent),
    };

    final String sentimentEmoji = switch (reaction.sentiment) {
      ReactionSentiment.positive => '👍',
      ReactionSentiment.negative => '👎',
      ReactionSentiment.neutral => '💬',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: isResolved ? theme.cardColor : bgTint,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: accentColor.withValues(alpha: isResolved ? 0.35 : 0.3),
          width: 0.5,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(kDefaultPadding / 2),
                bottomLeft: Radius.circular(kDefaultPadding / 2),
              ),
              child: isResolved
                  ? SizedBox(
                      width: 3,
                      child:
                          CustomPaint(painter: DashPainter(color: accentColor)),
                    )
                  : Container(width: 3, color: accentColor),
            ),
            Expanded(
              child: Opacity(
                opacity: isResolved ? 0.6 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding / 2 + 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                              vertical: kDefaultPadding / 4 - 3,
                            ),
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? theme.hintColor.withValues(alpha: 0.12)
                                  : accentColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(kDefaultPadding / 4),
                            ),
                            child: Text(
                              context.t.second_reader_paragraph(
                                index: reaction.paragraphIndex + 1,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    isResolved ? theme.hintColor : accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(sentimentEmoji,
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      Text(
                        reaction.comment,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.55,
                          color: theme.primaryColorDark,
                        ),
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      if (isResolved)
                        Text(
                          reaction.status == ReactionStatus.fixed
                              ? context.t.second_reader_fixed_with_ai
                              : context.t.second_reader_marked_read,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Row(
                          children: [
                            CardActionButton(
                              label: context.t.second_reader_fix_with_ai,
                              color: theme.primaryColor,
                              onTap: onFix,
                            ),
                            const SizedBox(width: kDefaultPadding / 2),
                            CardActionButton(
                              label: context.t.second_reader_ignore,
                              color: theme.hintColor,
                              onTap: onIgnore,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardActionButton extends StatelessWidget {
  const CardActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2 + 2,
          vertical: kDefaultPadding / 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(kDefaultPadding / 4 + 2),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class DashPainter extends CustomPainter {
  const DashPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const gap = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(1.5, y), Offset(1.5, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(DashPainter old) => old.color != color;
}
