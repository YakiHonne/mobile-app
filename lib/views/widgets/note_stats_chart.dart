import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/event_stats.dart';

import '../../logic/notes_events_cubit/notes_events_cubit.dart';
import '../../utils/utils.dart';
import 'app_icon.dart';
import 'fluid_blur_container.dart';

const _bucketCount = 8;

class _StatSeries {
  const _StatSeries(this.key, this.color, this.label);

  final String key;
  final Color color;
  final String Function(BuildContext) label;
}

class _Bucket {
  _Bucket(this.start);

  final int start;
  final Map<String, int> counts = {};
}

final _series = <_StatSeries>[
  _StatSeries('reactions', kRed, (c) => c.t.reactions),
  _StatSeries('reposts', kGreen, (c) => c.t.reposts),
  _StatSeries('quotes', const Color(0xFF8b5cf6), (c) => c.t.quotes),
  _StatSeries('replies', kNavyBlue, (c) => c.t.replies),
  _StatSeries('zaps', const Color(0xFFee7700), (c) => c.t.zaps),
];

Future<List<_Bucket>> _loadBuckets(EventStats? stats) async {
  if (stats == null) {
    return const [];
  }

  final idsBySeries = <String, List<String>>{
    'reactions': stats.reactions.keys.toList(),
    'replies': stats.replies.keys.toList(),
    'reposts': stats.reposts.keys.toList(),
    'quotes': stats.quotes.keys.toList(),
    'zaps': stats.zaps.values.expand((z) => z.keys).toList(),
  };

  final points = <MapEntry<int, String>>[];

  for (final s in _series) {
    final events = await Future.wait(
      (idsBySeries[s.key] ?? const <String>[])
          .map((id) => nc.db.loadEventById(id, false)),
    );

    for (final ev in events) {
      if (ev != null) {
        points.add(MapEntry(ev.createdAt, s.key));
      }
    }
  }

  if (points.isEmpty) {
    return const [];
  }

  final min = points.map((p) => p.key).reduce((a, b) => a < b ? a : b);
  final max = points.map((p) => p.key).reduce((a, b) => a > b ? a : b);
  final step = (max - min == 0 ? 1 : max - min) / _bucketCount;

  final buckets = List.generate(
    _bucketCount,
    (i) => _Bucket(min + (i * step).round()),
  );

  for (final p in points) {
    var idx = ((p.key - min) / step).floor();
    if (idx < 0) {
      idx = 0;
    }
    if (idx >= _bucketCount) {
      idx = _bucketCount - 1;
    }

    buckets[idx].counts.update(p.value, (v) => v + 1, ifAbsent: () => 1);
  }

  return buckets;
}

String _formatBucketDate(int seconds) {
  final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  return '${date.day}/${date.month}';
}

// Engagement-over-time chart mirroring the web app's EventStats bar chart:
// counts of reactions/replies/reposts/quotes/zaps bucketed across the
// note's lifetime, side by side per bucket.
class NoteStatsChart extends HookWidget {
  const NoteStatsChart({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final stats = context.select<NotesEventsCubit, EventStats?>(
      (cubit) => cubit.state.eventsStats[id],
    );
    final snapshot = useFuture(useMemoized(() => _loadBuckets(stats), [stats]));
    final buckets = snapshot.data;
    final isExpanded = useState(false);

    if (buckets == null || buckets.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxCount =
        buckets.expand((b) => b.counts.values).fold(0, (a, b) => a > b ? a : b);

    if (maxCount == 0) {
      return const SizedBox.shrink();
    }

    return FluidBlurContainer(
      borderRadius: kDefaultPadding,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => isExpanded.value = !isExpanded.value,
            child: Row(
              children: [
                AppIcon(
                  FeatureIcons.unStats,
                  size: 14,
                  color: Theme.of(context).highlightColor,
                ),
                const SizedBox(width: kDefaultPadding / 3),
                Expanded(
                  child: Text(
                    context.t.engagementChart.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded.value ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: AppIcon(
                    FeatureIcons.arrowDown,
                    size: 14,
                    color: Theme.of(context).highlightColor,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: !isExpanded.value
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: kDefaultPadding / 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legend(context),
                        const SizedBox(height: kDefaultPadding / 2),
                        SizedBox(
                          height: 140,
                          child: BarChart(
                            _chartData(context, buckets, maxCount),
                            swapAnimationDuration:
                                const Duration(milliseconds: 250),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: kDefaultPadding / 2,
      runSpacing: kDefaultPadding / 4,
      children: _series
          .map(
            (s) => Row(
              mainAxisSize: MainAxisSize.min,
              spacing: kDefaultPadding / 6,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  s.label(context).capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  BarChartData _chartData(
    BuildContext context,
    List<_Bucket> buckets,
    int maxCount,
  ) {
    return BarChartData(
      maxY: maxCount + (maxCount / 5),
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Theme.of(context).primaryColorLight,
          tooltipRoundedRadius: kDefaultPadding / 2,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding / 4,
          ),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final s = _series[rodIndex];

            return BarTooltipItem(
              '${s.label(context).capitalizeFirst()}: ${rod.toY.toInt()}',
              Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                    fontWeight: FontWeight.w600,
                  ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
        leftTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i != 0 && i != buckets.length - 1) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatBucketDate(buckets[i].start),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).highlightColor,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barGroups: List.generate(
        buckets.length,
        (i) => BarChartGroupData(
          x: i,
          barsSpace: 2,
          barRods: _series
              .map(
                (s) => BarChartRodData(
                  toY: (buckets[i].counts[s.key] ?? 0).toDouble(),
                  color: s.color,
                  width: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
