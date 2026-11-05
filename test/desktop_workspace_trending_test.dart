import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/cache/remote_cache_service.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/views/main_view/desktop/workspace_trending_source.dart';

class _Cache extends RemoteCacheService {
  _Cache({required this.sendEose}) : super(cacheUrl: '');

  final bool sendEose;
  final sent = <List<dynamic>>[];

  @override
  void send(String data) {
    final message = jsonDecode(data) as List<dynamic>;
    sent.add(message);
    if (message.first == 'REQ') {
      final id = message[1] as String;
      scheduleMicrotask(() {
        final request = requestsMap[id];
        request?.eventCallBack?.call(Event.partial(
          id: 'note',
          pubkey: 'author',
          content: 'hello',
        ));
        if (sendEose) {
          request?.eoseCallBack?.call(id, OKEvent(id, true, ''));
        }
      });
    }
  }
}

void main() {
  test('trending people are unique, ordered and exclude the account', () {
    final notes = [
      for (final author in ['alice', 'self', 'bob', 'alice'])
        DetailedNoteModel.fromEvent(Event.partial(
          id: author,
          pubkey: author,
          content: 'hello',
        )),
    ];
    expect(desktopTrendingAuthors(notes, 'self'), ['alice', 'bob']);
  });
  for (final sendEose in [true, false]) {
    test('cache retains received notes and closes request with EOSE=$sendEose',
        () async {
      final cache = _Cache(sendEose: sendEose)..connectionStatus = 1;
      final notes = await loadDesktopTrendingCache(
        cache,
        (_) => true,
        timeout: const Duration(milliseconds: 20),
      );
      expect(notes.single.id, 'note');
      expect(cache.requestsMap, isEmpty);
      expect(cache.sent.last.first, 'CLOSE');
      expect(cache.sent.last[1], cache.sent.first[1]);
    });
  }
}
