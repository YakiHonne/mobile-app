import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/models/event_stats.dart';
import 'package:yakihonne/logic/notes_events_cubit/notes_events_cubit.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';

void main() {
  test('open reply stats survive eviction and can be evicted after release',
      () async {
    nostrRepository = NostrDataRepository();
    final cubit = NotesEventsCubit()..retainStats('open');
    cubit.updateEventStats({
      for (var i = 0; i < 100; i++) 'feed-$i': EventStats.empty('feed-$i'),
      'open': const EventStats(
        eventId: 'open',
        reactions: {},
        replies: {'reply': 'author'},
        quotes: {},
        reposts: {},
        zaps: {},
        newestCreatedAt: 0,
      ),
    });
    expect(cubit.state.eventsStats['open']?.replies, {'reply': 'author'});

    cubit.releaseStats('open');
    for (final id in cubit.state.eventsStats.keys.where((id) => id != 'open')) {
      cubit.alreadySearchedContentIds.add(id);
      cubit.getContentStats(id);
    }
    cubit.pruneCache();
    expect(cubit.state.eventsStats, isNot(contains('open')));
    await cubit.close();
  });
}
