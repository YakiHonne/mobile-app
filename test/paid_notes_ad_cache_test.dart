import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:yakihonne/logic/leading_cubit/paid_notes_ad_cache.dart';

Event ad(String id) => Event.partial(id: id, content: id);

void main() {
  final pool = [ad('a'), ad('b'), ad('c'), ad('d'), ad('e')];
  List<String> ids(List<Event> es) => es.map((e) => e.id).toList();

  test('rotation excludes capped ads, least-seen first, ties by pool order', () {
    final r = buildAdRotation(pool, {'a': 5, 'c': 2, 'd': 1});
    expect(ids(r), ['b', 'e', 'd', 'c']);
  });

  test('slots consume the queue one ad at a time and stay stable on re-read',
      () {
    final cache = PaidNotesAdCache()..setPool(pool, {});
    expect(cache.forIndex(7)!.id, 'a');
    expect(cache.forIndex(14)!.id, 'b');
    // re-reading an assigned slot does not advance the queue
    expect(cache.forIndex(7)!.id, 'a');
    expect(cache.seenCounts, {'a': 1, 'b': 1});
  });

  test('refresh (clearAssignments) continues the queue, no restart', () {
    final cache = PaidNotesAdCache()..setPool(pool, {});
    cache.forIndex(7);
    cache.forIndex(14); // consumed a, b
    cache.clearAssignments();
    expect(cache.forIndex(7)!.id, 'c'); // continues, not back to 'a'
  });

  test('queue rebuilds from pool when drained, cycling least-seen first', () {
    final cache = PaidNotesAdCache()..setPool(pool, {});
    for (var i = 0; i < 5; i++) {
      cache.forIndex(i);
    }
    cache.clearAssignments();
    // all seen once now; rebuild serves them again in pool order
    expect(cache.forIndex(0)!.id, 'a');
    expect(cache.seenCounts['a'], 2);
  });

  test('all ads capped -> no more ads, hasServableAds false', () {
    final cache = PaidNotesAdCache()
      ..setPool(pool, {for (final e in pool) e.id: 5});
    expect(cache.hasServableAds, isFalse);
    expect(cache.forIndex(7), isNull);
  });
}
