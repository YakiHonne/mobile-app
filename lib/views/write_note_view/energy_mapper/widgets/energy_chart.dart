import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../logic/energy_mapper_cubit/energy_mapper_cubit.dart';
import '../../../../utils/utils.dart';
import 'energy_helpers.dart';

class EnergyLineChart extends StatelessWidget {
  const EnergyLineChart({
    super.key,
    required this.sentences,
    required this.selectedIndex,
    required this.onSelectSentence,
  });

  final List<SentenceEnergy> sentences;
  final int? selectedIndex;
  final void Function(int index) onSelectSentence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = sentences
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score))
        .toList();
    final avgScore =
        sentences.fold(0.0, (s, x) => s + x.score) / sentences.length;
    final lineColor = energyColor(avgScore);

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: SizedBox(
        height: 130,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            clipData: const FlClipData.all(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(),
              rightTitles: AxisTitles(),
              bottomTitles: AxisTitles(),
              leftTitles: AxisTitles(),
            ),
            lineTouchData: LineTouchData(
              touchCallback: (event, response) {
                if (event is FlTapUpEvent) {
                  final idx = response?.lineBarSpots?.firstOrNull?.spotIndex;
                  if (idx != null) {
                    onSelectSentence(idx);
                  }
                }
              },
              getTouchedSpotIndicator: (_, indicators) => indicators.map((i) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: theme.dividerColor,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    getDotPainter: (spot, _, p1, p2) => FlDotCirclePainter(
                      radius: 6,
                      color: energyColor(spot.y),
                      strokeWidth: 2,
                      strokeColor: theme.scaffoldBackgroundColor,
                    ),
                  ),
                );
              }).toList(),
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.transparent,
                getTooltipItems: (spots) => spots.map((_) => null).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.4,
                color: lineColor,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  getDotPainter: (spot, p1, p2, index) {
                    final isSelected = selectedIndex == index;
                    final c = energyColor(spot.y);
                    return FlDotCirclePainter(
                      radius: isSelected ? 6 : 4,
                      color: isSelected ? c : c.withValues(alpha: 0.7),
                      strokeWidth: isSelected ? 2.5 : 1.5,
                      strokeColor: theme.scaffoldBackgroundColor,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: lineColor.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
