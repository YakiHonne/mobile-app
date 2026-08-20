import 'package:flutter/material.dart';

import '../../../../logic/energy_mapper_cubit/energy_mapper_cubit.dart';
import '../../../../utils/utils.dart';
import 'energy_helpers.dart';

class EnergyChipRow extends StatelessWidget {
  const EnergyChipRow({
    super.key,
    required this.sentences,
    required this.selectedIndex,
    required this.scrollController,
    required this.onSelect,
    required this.onDeselect,
  });

  final List<SentenceEnergy> sentences;
  final int? selectedIndex;
  final ScrollController scrollController;
  final void Function(int) onSelect;
  final void Function(int) onDeselect;

  static const double chipWidth = 44.0;
  static const double chipGap = 8.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding / 4,
        ),
        itemCount: sentences.length,
        itemBuilder: (_, i) {
          final sentence = sentences[i];
          final color = energyColor(sentence.score);
          final isActive = selectedIndex == i;

          return Padding(
            padding: EdgeInsets.only(
              right: i < sentences.length - 1 ? chipGap : 0,
            ),
            child: GestureDetector(
              onTap: () => isActive ? onDeselect(i) : onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: chipWidth,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withValues(alpha: 0.18)
                      : color.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isActive
                        ? color.withValues(alpha: 0.8)
                        : color.withValues(alpha: 0.3),
                    width: isActive ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                ),
                child: Text(
                  'S${i + 1}',
                  style: TextStyle(
                    color: isActive ? color : color.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
