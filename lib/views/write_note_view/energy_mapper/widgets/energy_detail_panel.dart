import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../logic/energy_mapper_cubit/energy_mapper_cubit.dart';
import '../../../../utils/utils.dart';
import 'energy_helpers.dart';

class EnergyDetailPanel extends StatelessWidget {
  const EnergyDetailPanel({
    super.key,
    required this.selectedIndex,
    required this.sentences,
  });

  final int? selectedIndex;
  final List<SentenceEnergy> sentences;

  @override
  Widget build(BuildContext context) {
    final sentence = selectedIndex != null ? sentences[selectedIndex!] : null;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: sentence == null ? _DetailHint() : _DetailCard(sentence: sentence),
    );
  }
}

class _DetailHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.pointer, size: 15, color: theme.hintColor),
          const SizedBox(width: kDefaultPadding / 4),
          Text(
            context.t.energy_mapper_tap_hint,
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.sentence});
  final SentenceEnergy sentence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = energyColor(sentence.score);
    final label = sentence.label.isNotEmpty
        ? sentence.label
        : energyLabel(context, sentence.score);

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                  vertical: kDefaultPadding / 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sentence.score.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kDefaultPadding / 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                'S${sentence.index + 1}',
                style: TextStyle(
                  color: theme.hintColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
            child: Text(
              sentence.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55,
                color: theme.primaryColorDark,
              ),
            ),
          ),
          if (sentence.reasons.isNotEmpty) ...[
            const SizedBox(height: kDefaultPadding / 2),
            ...sentence.reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: kDefaultPadding / 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: kDefaultPadding / 4 - 2,
                      ),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: kDefaultPadding / 2),
                    Expanded(
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.hintColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
