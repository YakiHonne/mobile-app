import 'package:nostr_core_enhanced/nostr/nostr.dart';

/// Ad dropped from rotation once it has been shown this many times.
const int maxPaidAdSeenCount = 5;

List<Event> buildAdRotation(List<Event> pool, Map<String, int> seenCounts) {
  final indexed = <(Event, int, int)>[
    for (var i = 0; i < pool.length; i++)
      (pool[i], i, seenCounts[pool[i].id] ?? 0),
  ]..removeWhere((e) => e.$3 >= maxPaidAdSeenCount);
  indexed.sort((a, b) {
    final bySeen = a.$3.compareTo(b.$3);
    return bySeen != 0 ? bySeen : a.$2.compareTo(b.$2);
  });
  return [for (final e in indexed) e.$1];
}

class PaidNotesAdCache {
  List<Event> pool = const [];
  List<Event> rotation = const [];
  Map<String, int> seenCounts = {};
  final Map<int, Event?> _assignedByIndex = {};

  /// Whether a rebuilt rotation could serve at least one ad.
  bool get hasServableAds => buildAdRotation(pool, seenCounts).isNotEmpty;

  List<Event> setPool(List<Event> notes, Map<String, int> counts) {
    seenCounts = Map.of(counts);
    pool = notes;
    rotation = buildAdRotation(notes, seenCounts);
    _assignedByIndex.clear();
    return rotation;
  }

  void clearAssignments() => _assignedByIndex.clear();

  Event? forIndex(int index, {void Function()? onConsumed}) {
    if (_assignedByIndex.containsKey(index)) {
      return _assignedByIndex[index];
    }

    if (rotation.isEmpty) {
      rotation = buildAdRotation(pool, seenCounts);
    }
    if (rotation.isEmpty) {
      _assignedByIndex[index] = null;
      return null;
    }

    final note = rotation.removeAt(0);
    seenCounts[note.id] = (seenCounts[note.id] ?? 0) + 1;
    _assignedByIndex[index] = note;
    onConsumed?.call();
    return note;
  }
}
