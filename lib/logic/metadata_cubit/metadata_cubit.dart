// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/mixins/later_function.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../utils/utils.dart';

part 'metadata_state.dart';

class MetadataCubit extends Cubit<MetadataState> with LaterFunction {
  MetadataCubit()
      : super(
          const MetadataState(),
        ) {
    laterTimeMS = 500;
  }

  static const NIP05_NEEDS_UPDATE_DURATION = Duration(days: 7);
  static const METADATA_BATCH_SIZE = 50;
  static const NIP05_BATCH_SIZE = 20;

  final Set<String> _needUpdateMetadatas = {};
  final Set<String> _needUpdateNip05s = {};
  final Set<String> _pendingMetadatas = {};
  final Set<String> _pendingNip05s = {};
  final Map<String, int> _accessTimes = {};
  final Map<String, Metadata> _pendingCacheUpdates = {};
  Timer? _metadataEmitTimer;

  void _laterMetadataCallback() {
    if (_needUpdateMetadatas.isNotEmpty) {
      _loadNeedingUpdateMetadatas();
    }
  }

  void _laterNip05Callback() {
    if (_needUpdateNip05s.isNotEmpty) {
      _loadNeedingUpdateNip05s();
    }
  }

  Future<void> saveMetadata(Metadata metadata) async {
    await nc.db.saveMetadata(metadata);

    _updateMetadatasInState([metadata]);
  }

  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    await nc.db.saveMetadatas(metadatas);
    _updateMetadatasInState(metadatas);
  }

  void requestMetadata(String pubkey) {
    if (pubkey.isEmpty) {
      return;
    }

    final m = state.metadataCache[pubkey];
    _accessTimes[pubkey] = Helpers.now;

    if (m != null) {
      return;
    }

    _pendingMetadatas.add(pubkey);
    later(_laterRequestMetadata, null);
  }

  Future<void> _laterRequestMetadata() async {
    if (_pendingMetadatas.isEmpty) {
      return;
    }

    final batch = _pendingMetadatas.toList();
    _pendingMetadatas.clear();

    // print('BATCH: $batch');

    final metadatas = await nc.db.loadMetadatas(batch);
    if (metadatas.isNotEmpty) {
      _updateMetadatasInState(metadatas);
    }

    final remaining =
        batch.toSet().difference(metadatas.map((m) => m.pubkey).toSet());
    // print('REMAINING: $remaining');

    if (remaining.isNotEmpty) {
      _needUpdateMetadatas.addAll(remaining);
      later(_laterMetadataCallback, null);
    }
  }

  Future<void> loadNip05(List<Metadata> metadatas) async {
    final filtered = filteredMetadataForNip05Search(metadatas);

    if (filtered.isEmpty) {
      return;
    }

    final nip05s = await nc.db.loadNip05s(
      filtered
          .map(
            (e) => e.pubkey,
          )
          .toList(),
    );

    final toBeUpdated = <String, bool>{};

    for (final m in metadatas) {
      final nip05 = nip05s[m.pubkey];

      if (nip05 == null || nip05.needsUpdate(NIP05_NEEDS_UPDATE_DURATION)) {
        if (!_pendingNip05s.contains(m.pubkey)) {
          _needUpdateNip05s.add(m.pubkey);
          toBeUpdated[m.pubkey] = false;
        }
      } else {
        toBeUpdated[m.pubkey] = nip05.valid;
      }
    }

    _updateNip05Status(toBeUpdated);
    later(_laterNip05Callback, null);
  }

  List<Metadata> filteredMetadataForNip05Search(List<Metadata> metadatas) {
    metadatas.removeWhere((m) => state.nip05Status.containsKey(m.pubkey));

    if (metadatas.isEmpty) {
      return [];
    }

    final emptyNip05 = <String, bool>{};

    metadatas.removeWhere((m) {
      if (StringUtil.isBlank(m.nip05)) {
        emptyNip05[m.pubkey] = false;
        return true; // remove it
      }
      return false; // keep it
    });

    if (emptyNip05.isNotEmpty) {
      _updateNip05Status(emptyNip05);
    }

    if (metadatas.isEmpty) {
      return [];
    }

    return metadatas;
  }

  Future<List<Metadata>> fetchMetadata(List<String> pubkeys) async {
    final relays = useOutbox()
        ? feedRelaySet!.urls.toList()
        : currentUserRelayList.reads.toList();

    final list = await nc.loadMissingMetadatas(
      pubkeys,
      relays,
    );

    _updateMetadatasInState(list);

    return list;
  }

  Future<Metadata?> getFutureMetadata(
    String pubkey, {
    bool? forceSearch,
    bool forceTimeout = false,
  }) async {
    // Check cache first
    if (forceSearch == null && state.metadataCache.containsKey(pubkey)) {
      return state.metadataCache[pubkey];
    }

    final metadata = await nc.db.loadMetadata(pubkey);

    if (metadata != null && forceSearch == null) {
      _updateMetadatasInState([metadata]);
      return metadata;
    }

    final List<String> relays = useOutbox()
        ? feedRelaySet!.urls.toList()
        : currentUserRelayList.reads.toList();
    List<Metadata> loaded = [];

    final future = nc.loadMissingMetadatas(
      [pubkey],
      relays,
      forceSeach: forceSearch,
    );

    if (forceTimeout) {
      loaded = await future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          return <Metadata>[];
        },
      );
    } else {
      loaded = await future;
    }

    if (loaded.isNotEmpty) {
      await nc.db.saveMetadatas(loaded);
      _updateMetadatasInState(loaded);

      return loaded.first;
    }

    return null;
  }

  Future<Metadata?> getMetadata(String pubkey) async {
    // Return from cache if available
    if (state.metadataCache.containsKey(pubkey)) {
      return state.metadataCache[pubkey];
    }

    // Try database
    final metadata = await nc.db.loadMetadata(pubkey);

    if (metadata != null) {
      _updateMetadatasInState([metadata]);
      return metadata;
    }

    // Queue for fetching from relays
    if (!_pendingMetadatas.contains(pubkey)) {
      _needUpdateMetadatas.add(pubkey);
      later(_laterMetadataCallback, null);
    }

    return null;
  }

  Future<String?> getNip05Pubkey(String nip05) async {
    final m = await nc.db.getMetadataByNip05(nip05);

    if (m != null) {
      return m.pubkey;
    }

    return Nip05.getPubkey(nip05);
  }

  Future<Metadata?> getCachedMetadata(String pubkey) async {
    // Check in-memory cache first
    if (state.metadataCache.containsKey(pubkey)) {
      return state.metadataCache[pubkey];
    }

    // Fall back to database
    final metadata = await nc.db.loadMetadata(pubkey);

    if (metadata != null) {
      _updateMetadatasInState([metadata]);
    }

    return metadata;
  }

  // Synchronous cache access (for optimal performance)
  Metadata? getCachedMetadataSync(String pubkey) {
    return state.metadataCache[pubkey];
  }

  Future<Metadata> getAvailableMetadata(String pubkey,
      {bool search = false}) async {
    final metadata = search
        ? (await getMetadata(pubkey))
        : (await getCachedMetadata(pubkey));

    return metadata ?? Metadata.empty().copyWith(pubkey: pubkey);
  }

  Metadata? getMemoryMetadata(String pubkey) {
    return state.metadataCache[pubkey];
  }

  Future<Metadata> getInstantMetadata(String pubkey) async {
    return (await getCachedMetadata(pubkey)) ??
        (await getMetadata(pubkey)) ??
        Metadata.empty().copyWith(pubkey: pubkey);
  }

  void _updateNip05Status(Map<String, bool> updates) {
    if (isClosed) {
      return;
    }

    final updatedStatus = Map<String, bool>.from(state.nip05Status);
    updatedStatus.addAll(updates);

    emit(state.copyWith(nip05Status: updatedStatus));
  }

  Future<bool> isNip05Valid(Metadata metadata, {bool search = true}) async {
    if (StringUtil.isBlank(metadata.nip05)) {
      return false;
    }

    // Check cache first
    if (state.nip05Status.containsKey(metadata.pubkey)) {
      return state.nip05Status[metadata.pubkey] ?? false;
    }

    final nip05 = await nc.db.loadNip05(metadata.pubkey);

    if (search &&
        (nip05 == null || nip05.needsUpdate(NIP05_NEEDS_UPDATE_DURATION))) {
      if (!_pendingNip05s.contains(metadata.pubkey)) {
        _needUpdateNip05s.add(metadata.pubkey);
        later(_laterNip05Callback, null);
      }
      return false;
    }

    final valid = nip05?.valid ?? false;
    _updateNip05Status({metadata.pubkey: valid});
    return valid;
  }

  Future<void> _loadNeedingUpdateMetadatas() async {
    if (_needUpdateMetadatas.isEmpty) {
      return;
    }

    final batch = _needUpdateMetadatas.toList();
    _needUpdateMetadatas.clear();

    final relays = useOutbox()
        ? feedRelaySet!.urls.toList()
        : currentUserRelayList.reads.toList();

    // print('relays: $relays');
    final list = await nc.loadMissingMetadatas(
      batch,
      relays,
      forceSeach: true,
    );
    // print('list: ${list.length}');

    _updateMetadatasInState(list);
  }

  Future<void> _loadNeedingUpdateNip05s() async {
    if (_needUpdateNip05s.isEmpty) {
      return;
    }

    // Take a batch and mark as pending
    final batch = _needUpdateNip05s.take(NIP05_BATCH_SIZE).toList();
    _needUpdateNip05s.removeAll(batch);
    _pendingNip05s.addAll(batch);

    try {
      final List<Nip05> toSave = [];
      final Map<String, bool> statusUpdates = {};

      // Load metadata for the batch
      final metadatas = await nc.db.loadMetadatas(batch);
      final metadataMap = {for (final m in metadatas) m.pubkey: m};

      for (final pubkey in batch) {
        final metadata = metadataMap[pubkey];
        if (metadata == null || StringUtil.isBlank(metadata.nip05)) {
          statusUpdates[pubkey] = false;
          continue;
        }

        Nip05? nip05 = await nc.db.loadNip05(pubkey);
        final valid = await Nip05.check(metadata.nip05, pubkey);

        nip05 ??= Nip05(
          pubkey: pubkey,
          nip05: metadata.nip05,
          valid: valid,
          updatedAt: Helpers.now,
        );

        toSave.add(nip05.copyWith(
          valid: valid,
          updatedAt: Helpers.now,
        ));

        statusUpdates[pubkey] = valid;
      }

      if (toSave.isNotEmpty) {
        await nc.db.saveNip05s(toSave);
      }

      if (!isClosed && statusUpdates.isNotEmpty) {
        _updateNip05Status(statusUpdates);

        emit(state.copyWith(
          nip05Pubkeys: {
            ...state.nip05Pubkeys,
            ...batch.toSet(),
          },
        ));
      }
    } finally {
      _pendingNip05s.removeAll(batch);
    }
  }

  Future<List<Metadata>> searchCacheMetadatas(String search) async {
    return nc.db.searchMetadatas(search, 50);
  }

  Future<List<Metadata>> searchCacheMetadatasFromContactList(
    String search,
  ) async {
    final contactList = contactListCubit.contacts;

    if (contactList.isEmpty) {
      return [];
    }

    return nc.db.searchRelatedMetadatas(search, contactList, 30);
  }

  void _updateMetadatasInState(List<Metadata> metadatas) {
    if (isClosed || metadatas.isEmpty) {
      return;
    }

    for (final metadata in metadatas) {
      _pendingCacheUpdates[metadata.pubkey] = metadata;
      _accessTimes[metadata.pubkey] = Helpers.now;
    }

    _metadataEmitTimer ??= Timer(
      const Duration(milliseconds: 50),
      _flushMetadataEmit,
    );
  }

  void _flushMetadataEmit() {
    _metadataEmitTimer = null;
    if (isClosed || _pendingCacheUpdates.isEmpty) {
      return;
    }

    final updatedCache = Map<String, Metadata>.from(state.metadataCache)
      ..addAll(_pendingCacheUpdates);
    final updatedPubkeys = Set<String>.from(state.metadataPubkeys)
      ..addAll(_pendingCacheUpdates.keys);

    final searchNip05 = _pendingCacheUpdates.values
        .where(
          (m) =>
              StringUtil.isNotBlank(m.nip05) &&
              !state.nip05Status.containsKey(m.pubkey),
        )
        .toList();

    _pendingCacheUpdates.clear();

    emit(state.copyWith(
      metadataCache: updatedCache,
      metadataPubkeys: updatedPubkeys,
    ));

    if (updatedCache.length > 800) {
      pruneCache();
    }

    if (searchNip05.isNotEmpty) {
      loadNip05(searchNip05);
    }
  }

  // Bulk load metadata from database (for initialization or cache warming)
  Future<void> warmCache(List<String> pubkeys) async {
    final missingPubkeys =
        pubkeys.where((p) => !state.metadataCache.containsKey(p)).toList();

    if (missingPubkeys.isEmpty) {
      return;
    }

    final metadatas = await nc.db.loadMetadatas(missingPubkeys);
    _updateMetadatasInState(metadatas);
  }

  // Clear old entries from cache to prevent memory bloat
  void pruneCache({int maxEntries = 500}) {
    if (state.metadataCache.length <= maxEntries) {
      return;
    }

    // Sort by last access time (most recent first)
    final sortedPubkeys = state.metadataCache.keys.toList()
      ..sort((a, b) {
        final timeA = _accessTimes[a] ?? 0;
        final timeB = _accessTimes[b] ?? 0;
        return timeB.compareTo(timeA); // Most recent first
      });

    // Keep only the most recently accessed entries
    final keysToKeep = sortedPubkeys.take(maxEntries).toSet();
    final prunedCache = {
      for (final key in keysToKeep) key: state.metadataCache[key]!
    };

    if (canSign()) {
      final pubkey = currentSigner!.getPublicKey();

      keysToKeep.add(pubkey);
      if (state.metadataCache[pubkey] != null) {
        prunedCache[pubkey] = state.metadataCache[pubkey]!;
      }
    }

    // Clean up access times for removed entries
    _accessTimes.removeWhere((key, _) => !keysToKeep.contains(key));

    lg.i(
        '🧹 Pruned cache from ${state.metadataCache.length} to $maxEntries entries');

    emit(state.copyWith(metadataCache: prunedCache));
  }

  Future<void> clear() async {
    await Future.wait([
      nc.db.removeAllMetadatas(),
      nc.db.removeAllNip05s(),
    ]);

    emit(const MetadataState());
  }

  @override
  Future<void> close() {
    _needUpdateMetadatas.clear();
    _needUpdateNip05s.clear();
    _pendingMetadatas.clear();
    _pendingNip05s.clear();
    return super.close();
  }
}
