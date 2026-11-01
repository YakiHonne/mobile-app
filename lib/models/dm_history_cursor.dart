class DmHistoryCursor {
  const DmHistoryCursor({
    required this.until,
    required this.intervalIndex,
    required this.liveSince,
  });

  static const intervals = <Duration>[
    Duration(days: 7),
    Duration(days: 14),
    Duration(days: 30),
    Duration(days: 90),
    Duration(days: 180),
  ];

  final int until;
  final int intervalIndex;
  final int liveSince;

  bool get isComplete => intervalIndex >= intervals.length;

  int get since {
    if (isComplete) {
      throw StateError('A completed history cursor has no query range.');
    }

    return until - intervals[intervalIndex].inSeconds;
  }

  DmHistoryCursor advance({required bool pageHasEvents}) {
    if (isComplete) {
      return this;
    }

    final nextIntervalIndex = intervalIndex < intervals.length - 1
        ? intervalIndex + 1
        : intervalIndex + (pageHasEvents ? 0 : 1);

    return DmHistoryCursor(
      until: since - 1,
      intervalIndex: nextIntervalIndex,
      liveSince: liveSince,
    );
  }
}
