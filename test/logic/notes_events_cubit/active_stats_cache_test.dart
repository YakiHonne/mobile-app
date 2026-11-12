import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/logic/notes_events_cubit/active_stats_cache.dart';

void main() {
  test('open note survives feed eviction until all views release it', () {
    final active = ActiveStatsCache()
      ..retain('open')
      ..retain('open');
    final recentFirst = ['newest', 'new', 'open'];

    Set<String> prune() => selectCacheKeys(
          recentFirst,
          2,
          active.protectedKeys,
        );

    expect(prune(), {'newest', 'new', 'open'});
    active.release('open');
    expect(prune(), contains('open'));
    active.release('open');
    expect(prune(), {'newest', 'new'});
  });
}
