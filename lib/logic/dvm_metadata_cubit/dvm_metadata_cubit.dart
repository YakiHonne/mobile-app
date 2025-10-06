import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/dvm_model.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'dvm_metadata_state.dart';

class DvmMetadataCubit extends Cubit<DvmMetadataState> {
  DvmMetadataCubit()
      : super(
          const DvmMetadataState(
            dvmsMetadata: {},
            refresh: false,
          ),
        );

  void init() {
    loadCachedDvms();
    syncNewDvms();
  }

  Future<void> loadCachedDvms() async {
    final evs = await nc.db.loadEvents(
      f: Filter(
        kinds: [EventKind.APPLICATION_INFO],
        k: [EventKind.DVM_CONTENT_FEED.toString()],
      ),
    );

    evs.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    final events = evs.where((ev) => canUseDvm(ev)).toList();

    emit(
      state.copyWith(
        dvmsMetadata: {
          ...state.dvmsMetadata,
          ...{
            for (final ev in events) ev.pubkey: DvmMetadata.fromEvent(ev),
          },
        },
      ),
    );
  }

  Future<void> syncNewDvms() async {
    int? since;

    final ev =
        state.dvmsMetadata.isNotEmpty ? state.dvmsMetadata.values.first : null;

    if (ev != null) {
      final event = await nc.db.loadEvent(
        pubkey: ev.pubkey,
        kTag: EventKind.DVM_CONTENT_FEED.toString(),
        kind: EventKind.APPLICATION_INFO,
      );

      if (event != null) {
        since = event.createdAt + 1;
      }
    }

    final events = await fetchEvents(
      kinds: [EventKind.APPLICATION_INFO],
      kTags: [EventKind.DVM_CONTENT_FEED.toString()],
      since: since,
    );

    saveEvents(events);
  }

  Future<void> getDvmsMetadas({required List<String> pubkeys}) async {
    final evs = await nc.db.loadEvents(
      f: Filter(
        kinds: [EventKind.APPLICATION_INFO],
        k: [EventKind.DVM_CONTENT_FEED.toString()],
        authors: pubkeys,
      ),
    );

    final remainingPubkeys = pubkeys.toSet().difference(
          evs.map((e) => e.pubkey).toSet(),
        );

    saveEvents(evs);

    if (remainingPubkeys.isNotEmpty) {
      final events = await fetchEvents(
        pubkeys: pubkeys,
        kinds: [EventKind.APPLICATION_INFO],
      );

      saveEvents(events);
    }
  }

  Future<List<Event>> fetchEvents({
    List<String>? pubkeys,
    List<int>? kinds,
    List<String>? kTags,
    int? since,
  }) async {
    final events = await NostrFunctionsRepository.getEventsAsync(
      pubkeys: pubkeys,
      kinds: kinds,
      kTags: kTags,
      since: since,
    );

    return events.where((ev) => canUseDvm(ev)).toList();
  }

  Future<void> saveEvents(List<Event> events) async {
    await nc.db.saveEvents(events);

    emit(
      state.copyWith(
        dvmsMetadata: {
          ...state.dvmsMetadata,
          ...{
            for (final ev in events) ev.pubkey: DvmMetadata.fromEvent(ev),
          },
        },
      ),
    );
  }

  bool canUseDvm(Event ev) {
    try {
      if (ev.content.isNotEmpty) {
        final content = jsonDecode(ev.content);
        return content['amount'] == 'free';
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
