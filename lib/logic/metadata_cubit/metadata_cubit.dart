// // ignore_for_file: constant_identifier_names, prefer_foreach

// import 'dart:async';

// import 'package:equatable/equatable.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:nostr_core_enhanced/models/models.dart';
// import 'package:nostr_core_enhanced/utils/utils.dart';

// import '../../common/mixins/later_function.dart';
// import '../../models/app_models/diverse_functions.dart';
// import '../../utils/utils.dart';

// part 'metadata_state.dart';

// class MetadataWithNip05 extends Equatable {
//   const MetadataWithNip05(this.metadata, this.isNip05Valid);

//   final Metadata metadata;
//   final bool isNip05Valid;

//   @override
//   List<Object?> get props => [metadata, isNip05Valid];
// }

// class MetadataCubit extends Cubit<MetadataState> with LaterFunction {
//   MetadataCubit()
//       : super(
//           MetadataState(
//             isLoading: false,
//             metadatas: const {},
//             nip05: const {},
//             loadingPubkeys: const {},
//             lastUpdated: Helpers.now,
//           ),
//         ) {
//     laterTimeMS = 300; // Reduced from 500ms for better responsiveness
//     startPeriodicFlush();
//   }

//   final flushMaxTime = 300; // 5 minutes in seconds (300 seconds)
//   static const NIP05_NEEDS_UPDATE_DURATION = Duration(days: 7);
//   static const METADATA_CACHE_DURATION =
//       Duration(minutes: 5); // 5 minutes cacheq

//   final Set<String> pendingMetadataLoads = {};
//   final Set<Metadata> pendingNip05Loads = {};

//   void startPeriodicFlush() {
//     Timer.periodic(const Duration(minutes: 5), (_) {
//       periodicFlush();
//     });
//   }

//   Future<String?> getNip05Pubkey(String nip05) async {
//     final m = await nc.db.getMetadataByNip05(nip05);

//     if (m != null) {
//       return m.pubkey;
//     }

//     return Nip05.getPubkey(nip05);
//   }

//   Future<void> saveMetadata(Metadata metadata) async {
//     await nc.db.saveMetadata(metadata);
//   }

//   Future<void> saveMetadatas(List<Metadata> metadatas) async {
//     await nc.db.saveMetadatas(metadatas);
//   }

//   Future<List<Metadata>> searchCacheMetadatas(String search) async {
//     return nc.db.searchMetadatas(search, 50);
//   }

//   void searchMetadatas(List<String> pubkeys) {
//     requestMetadatas(pubkeys);
//   }

//   Future<Metadata?> getCachedMetadata(String pubkey) async {
//     return nc.db.loadMetadata(pubkey);
//   }

//   // Optimized: Batch database operations
//   Future<Map<String, Metadata>> _batchLoadCachedMetadatas(
//     List<String> pubkeys,
//   ) async {
//     if (pubkeys.isEmpty) {
//       return {};
//     }

//     // Single database call for all pubkeys
//     final metadatas =
//         await nc.db.loadMetadatas(pubkeys); // Assuming bulk method exists
//     final Map<String, Metadata> result = {};

//     for (final metadata in metadatas) {
//       result[metadata.pubkey] = metadata;
//     }

//     return result;
//   }

//   // Optimized: Get metadata without side effects
//   Metadata? getMetadataSync(String pubkey) {
//     return state.metadatas[pubkey]?.key;
//   }

//   Future<Metadata> getInstantMetadata(String pubkey) async {
//     return (await getCachedMetadata(pubkey)) ??
//         (await getFutureMetadata(pubkey)) ??
//         Metadata.empty().copyWith(pubkey: pubkey);
//   }

//   Future<List<Metadata>> fetchMetadata(List<String> pubkeys) async {
//     final relays = useOutbox()
//         ? feedRelaySet!.urls.toList()
//         : currentUserRelayList.reads.toList();

//     final list = await nc.loadMissingMetadatas(
//       pubkeys,
//       relays,
//     );

//     return list;
//   }

//   Future<Metadata> getAvailableMetadata(
//     String pubkey, {
//     bool search = false,
//   }) async {
//     final metadata = search
//         ? (await getFutureMetadata(pubkey))
//         : (await getCachedMetadata(pubkey));

//     return metadata ?? Metadata.empty().copyWith(pubkey: pubkey);
//   }

//   // Optimized: Request metadata load (side effect separated from getter)
//   void requestMetadata(String pubkey) {
//     if (pubkey.isEmpty) {
//       return;
//     }

//     // Don't request if already cached or loading
//     if (state.metadatas.containsKey(pubkey) ||
//         state.loadingPubkeys.contains(pubkey)) {
//       return;
//     }

//     pendingMetadataLoads.add(pubkey);
//     later(processPendingLoads, null);
//   }

//   // Optimized: Batch request multiple metadata
//   void requestMetadatas(List<String> pubkeys) {
//     final toRequest = pubkeys
//         .where((pubkey) =>
//             pubkey.isNotEmpty &&
//             !state.metadatas.containsKey(pubkey) &&
//             !state.loadingPubkeys.contains(pubkey))
//         .toList();

//     if (toRequest.isEmpty) {
//       return;
//     }

//     pendingMetadataLoads.addAll(toRequest);
//     later(processPendingLoads, null);
//   }

//   Future<void> processPendingLoads() async {
//     if (pendingMetadataLoads.isEmpty && pendingNip05Loads.isEmpty) {
//       return;
//     }

//     // Process metadata loads
//     if (pendingMetadataLoads.isNotEmpty) {
//       final pubkeysToLoad = List<String>.from(pendingMetadataLoads);
//       pendingMetadataLoads.clear();

//       // Mark as loading
//       emit(state.copyWith(
//         loadingPubkeys: {...state.loadingPubkeys, ...pubkeysToLoad},
//       ));

//       await _loadMetadatasBatch(pubkeysToLoad);
//     }

//     // Process NIP05 loads
//     if (pendingNip05Loads.isNotEmpty) {
//       final nip05ToLoad = List<Metadata>.from(pendingNip05Loads);
//       pendingNip05Loads.clear();
//       await _loadNip05sBatch(nip05ToLoad);
//     }
//   }

//   Future<Metadata?> getFutureMetadata(
//     String pubkey, {
//     bool? forceSearch,
//   }) async {
//     final metadata = await nc.db.loadMetadata(pubkey);

//     if (metadata != null && forceSearch == null) {
//       return metadata;
//     }

//     final List<String> relays = useOutbox()
//         ? feedRelaySet!.urls.toList()
//         : currentUserRelayList.reads.toList();

//     final loaded = await nc.loadMissingMetadatas(
//       [pubkey],
//       relays,
//       forceSeach: forceSearch,
//     );

//     if (loaded.isNotEmpty) {
//       return loaded.first;
//     }

//     return null;
//   }

//   Future<void> _loadMetadatasBatch(List<String> pubkeys) async {
//     try {
//       // First check cache in batch
//       final cached = await _batchLoadCachedMetadatas(pubkeys);
//       final needsNetwork =
//           pubkeys.where((pk) => !cached.containsKey(pk)).toList();

//       // Update with cached data
//       if (cached.isNotEmpty) {
//         _updateMetadatasInState(cached.values.toList());
//       }

//       // Fetch missing from network
//       if (needsNetwork.isNotEmpty) {
//         final relays = useOutbox()
//             ? feedRelaySet!.urls.toList()
//             : currentUserRelayList.reads.toList();

//         final networkMetadatas = await nc.loadMissingMetadatas(
//           needsNetwork,
//           relays,
//         );

//         if (networkMetadatas.isNotEmpty) {
//           _updateMetadatasInState(networkMetadatas);
//           await nc.db.saveMetadatas(networkMetadatas);
//         }
//       }
//     } finally {
//       // Remove from loading state
//       final newLoadingPubkeys = Set<String>.from(state.loadingPubkeys);
//       newLoadingPubkeys.removeAll(pubkeys);

//       emit(state.copyWith(
//         loadingPubkeys: newLoadingPubkeys,
//         lastUpdated: Helpers.now,
//       ));
//     }
//   }

//   void _updateMetadatasInState(List<Metadata> metadatas) {
//     if (metadatas.isEmpty) {
//       return;
//     }

//     final updatedMetadatas =
//         Map<String, MapEntry<Metadata, int>>.from(state.metadatas);

//     for (final metadata in metadatas) {
//       updatedMetadatas[metadata.pubkey] = MapEntry(metadata, Helpers.now);
//     }

//     // No more size-based eviction - only time-based via periodicFlush
//     emit(state.copyWith(
//       metadatas: updatedMetadatas,
//       lastUpdated: Helpers.now,
//     ));
//   }

//   /// Touch metadata to update its last accessed time
//   void _touchMetadata(String pubkey) {
//     final existingEntry = state.metadatas[pubkey];
//     if (existingEntry != null) {
//       final updatedMetadatas =
//           Map<String, MapEntry<Metadata, int>>.from(state.metadatas);
//       updatedMetadatas[pubkey] = MapEntry(existingEntry.key, Helpers.now);

//       emit(state.copyWith(
//         metadatas: updatedMetadatas,
//         lastUpdated: Helpers.now,
//       ));
//     }
//   }

//   /// Touch NIP05 to update its last accessed time
//   void _touchNip05(String pubkey) {
//     final existingEntry = state.nip05[pubkey];
//     if (existingEntry != null) {
//       final updatedNip05 = Map<String, MapEntry<Nip05, int>>.from(state.nip05);
//       updatedNip05[pubkey] = MapEntry(existingEntry.key, Helpers.now);

//       emit(state.copyWith(
//         nip05: updatedNip05,
//         lastUpdated: Helpers.now,
//       ));
//     }
//   }

//   /// Provider methods that update last accessed time
//   Metadata? getProviderMetadata(String pubkey) {
//     final m = state.metadatas[pubkey];

//     if (m != null) {
//       // Update last accessed time
//       _touchMetadata(pubkey);
//       return m.key;
//     }

//     requestMetadata(pubkey);
//     return null;
//   }

//   Nip05? getProviderNip05(Metadata? metadata) {
//     if (metadata == null) {
//       return null;
//     }

//     final m = state.nip05[metadata.pubkey];

//     if (m != null) {
//       // Update last accessed time
//       _touchNip05(metadata.pubkey);
//       return m.key;
//     }

//     isNip05Valid(metadata);
//     return null;
//   }

//   Future<bool> isNip05Valid(Metadata metadata, {bool search = true}) async {
//     if (StringUtil.isNotBlank(metadata.nip05)) {
//       final nip05 = await nc.db.loadNip05(metadata.pubkey);

//       if (search &&
//           (nip05 == null || nip05.needsUpdate(NIP05_NEEDS_UPDATE_DURATION))) {
//         _loadNip05sBatch([metadata]);
//       }

//       if (nip05 != null) {
//         _updateNip05InState([nip05]);
//       }

//       return nip05?.valid ?? false;
//     }

//     return false;
//   }

//   Future<void> _loadNip05sBatch(List<Metadata> metadatas) async {
//     final toSave = <Nip05>[];

//     for (final metadata in metadatas) {
//       if (StringUtil.isBlank(metadata.nip05)) {
//         continue;
//       }

//       Nip05? nip05 = await nc.db.loadNip05(metadata.pubkey);
//       final valid = await Nip05.check(metadata.nip05, metadata.pubkey);

//       nip05 ??= Nip05(
//         pubkey: metadata.pubkey,
//         nip05: metadata.nip05,
//         valid: valid,
//         updatedAt: Helpers.now,
//       );

//       toSave.add(
//         nip05.copyWith(
//           valid: valid,
//           updatedAt: Helpers.now,
//         ),
//       );
//     }

//     if (toSave.isNotEmpty) {
//       await nc.db.saveNip05s(toSave);
//       _updateNip05InState(toSave);
//     }
//   }

//   Future<List<Metadata>> searchCacheMetadatasFromContactList(
//     String search,
//   ) async {
//     final contactList = contactListCubit.contacts;

//     if (contactList.isEmpty) {
//       return [];
//     }

//     return nc.db.searchRelatedMetadatas(search, contactList, 30);
//   }

//   void _updateNip05InState(List<Nip05> nip05s) {
//     if (nip05s.isEmpty) {
//       return;
//     }

//     final updatedNip05 = Map<String, MapEntry<Nip05, int>>.from(state.nip05);

//     for (final nip05 in nip05s) {
//       updatedNip05[nip05.pubkey] = MapEntry(nip05, Helpers.now);
//     }

//     emit(state.copyWith(
//       nip05: updatedNip05,
//       lastUpdated: Helpers.now,
//     ));
//   }

//   // Optimized: Preload metadata for known user lists
//   Future<void> preloadMetadatas(List<String> pubkeys) async {
//     final toPreload = pubkeys
//         .where((pk) => pk.isNotEmpty && !state.metadatas.containsKey(pk))
//         .toList();

//     if (toPreload.isEmpty) {
//       return;
//     }

//     await _loadMetadatasBatch(toPreload);
//   }

//   /// Time-based cache eviction - removes metadata older than 5 minutes
//   void periodicFlush() {
//     final metadatas =
//         Map<String, MapEntry<Metadata, int>>.from(state.metadatas);
//     final nip05List = Map<String, MapEntry<Nip05, int>>.from(state.nip05);

//     final cutoffTime = Helpers.now - METADATA_CACHE_DURATION.inSeconds;

//     // Remove metadata entries older than 5 minutes
//     final metadatasBefore = metadatas.length;
//     metadatas.removeWhere((key, value) => value.value < cutoffTime);

//     // Remove NIP05 entries older than 5 minutes
//     final nip05Before = nip05List.length;
//     nip05List.removeWhere((key, value) => value.value < cutoffTime);

//     // Debug logging (optional)
//     if (metadatasBefore != metadatas.length ||
//         nip05Before != nip05List.length) {
//       print(
//           'MetadataCache: Flushed ${metadatasBefore - metadatas.length} metadata entries and ${nip05Before - nip05List.length} NIP05 entries');
//     }

//     emit(state.copyWith(
//       metadatas: metadatas,
//       nip05: nip05List,
//       lastUpdated: Helpers.now,
//     ));
//   }

//   Future<void> clear() async {
//     await Future.wait([
//       nc.db.removeAllMetadatas(),
//       nc.db.removeAllNip05s(),
//     ]);

//     emit(state.copyWith(
//       metadatas: {},
//       nip05: {},
//       lastUpdated: Helpers.now,
//     ));
//   }

//   Future<Map<String, Metadata>> getAvailableMetadasMap(
//     List<String> pubkeys,
//   ) async {
//     final Map<String, Metadata> available = {};

//     for (final pubkey in pubkeys) {
//       final m = await getCachedMetadata(pubkey);

//       if (m != null) {
//         available[m.pubkey] = m;
//         // Touch the metadata since it was accessed
//         _touchMetadata(m.pubkey);
//       }
//     }

//     return available;
//   }

//   Future<List<Metadata>> getAllMetadas() async {
//     return nc.db.getAllMetadatas();
//   }
// }

// // extension MetadataCubitExtensions on MetadataCubit {
// //   /// Schedule periodic cache cleanup (call this in your app initialization)
// //   void startPeriodicFlush() {
// //     Timer.periodic(const Duration(minutes: 2), (_) {
// //       periodicFlush();
// //     });
// //   }

// //   /// Get cache statistics for monitoring
// //   Map<String, dynamic> getCacheStats() {
// //     return state.getCacheStats();
// //   }

// //   /// Force evict old entries (useful for memory pressure situations)
// //   void forceEvictOldEntries({Duration? maxAge}) {
// //     final maxAgeSeconds = (maxAge ?? const Duration(minutes: 3)).inSeconds;
// //     final cutoffTime = Helpers.now - maxAgeSeconds;

// //     final metadatas =
// //         Map<String, MapEntry<Metadata, int>>.from(state.metadatas);
// //     final nip05List = Map<String, MapEntry<Nip05, int>>.from(state.nip05);

// //     final metadatasBefore = metadatas.length;
// //     metadatas.removeWhere((key, value) => value.value < cutoffTime);

// //     final nip05Before = nip05List.length;
// //     nip05List.removeWhere((key, value) => value.value < cutoffTime);

// //     if (metadatasBefore != metadatas.length ||
// //         nip05Before != nip05List.length) {
// //       emit(state.copyWith(
// //         metadatas: metadatas,
// //         nip05: nip05List,
// //         lastUpdated: Helpers.now,
// //       ));

// //       print(
// //           'ForceEvicted: ${metadatasBefore - metadatas.length} metadata, ${nip05Before - nip05List.length} NIP05');
// //     }
// //   }

// //   /// Warm up cache with frequently used pubkeys
// //   Future<void> warmUpCache(List<String> importantPubkeys) async {
// //     print(
// //         'Warming up cache with ${importantPubkeys.length} important pubkeys...');
// //     await preloadMetadatas(importantPubkeys);
// //   }

// //   /// Touch multiple metadata entries (useful when displaying a list)
// //   void touchMetadatas(List<String> pubkeys) {
// //     bool hasChanges = false;
// //     final updatedMetadatas =
// //         Map<String, MapEntry<Metadata, int>>.from(state.metadatas);

// //     for (final pubkey in pubkeys) {
// //       final existingEntry = updatedMetadatas[pubkey];
// //       if (existingEntry != null) {
// //         updatedMetadatas[pubkey] = MapEntry(existingEntry.key, Helpers.now);
// //         hasChanges = true;
// //       }
// //     }

// //     if (hasChanges) {
// //       emit(state.copyWith(
// //         metadatas: updatedMetadatas,
// //         lastUpdated: Helpers.now,
// //       ));
// //     }
// //   }
// // }

// ignore_for_file: constant_identifier_names, prefer_foreach

// class MetadataCubit extends Cubit<MetadataState> with LaterFunction {
//   MetadataCubit()
//       : super(
//           const MetadataState(),
//         ) {
//     laterTimeMS = 500;
//   }

//   static const NIP05_NEEDS_UPDATE_DURATION = Duration(days: 7);

//   void _laterMetadataCallback() {
//     if (_needUpdateMetadatas.isNotEmpty) {
//       _loadNeedingUpdateMetadatas();
//     }
//   }

//   void _laterNip05Callback() {
//     if (_needUpdateNip05s.isNotEmpty) {
//       _loadNeedingUpdateNip05s();
//     }
//   }

//   Future<void> saveMetadata(Metadata metadata) async {
//     await nc.db.saveMetadata(metadata);
//     updateMetadatas([metadata]);
//   }

//   Future<void> saveMetadatas(List<Metadata> metadatas) async {
//     await nc.db.saveMetadatas(metadatas);
//     updateMetadatas(metadatas);
//   }

//   final List<String> _needUpdateMetadatas = [];
//   final List<Metadata> _needUpdateNip05s = [];

//   void update(String pubkey) {
//     if (!_needUpdateMetadatas.contains(pubkey) && pubkey.isNotEmpty) {
//       _needUpdateMetadatas.add(pubkey);
//     }

//     later(_laterMetadataCallback, null);
//   }

//   Future<List<Metadata>> fetchMetadata(List<String> pubkeys) async {
//     final relays = useOutbox()
//         ? feedRelaySet!.urls.toList()
//         : currentUserRelayList.reads.toList();

//     final list = await nc.loadMissingMetadatas(
//       pubkeys,
//       relays,
//     );

//     updateMetadatas(list);

//     return list;
//   }

//   void requestMetadata(String pubkey) {
//     if (pubkey.isEmpty) {
//       return;
//     }

//     if (_needUpdateMetadatas.contains(pubkey)) {
//       return;
//     }

//     _needUpdateMetadatas.add(pubkey);
//     later(_laterMetadataCallback, null);
//   }

//   Future<Metadata?> getFutureMetadata(
//     String pubkey, {
//     bool? forceSearch,
//     bool forceTimeout = false,
//   }) async {
//     final metadata = await nc.db.loadMetadata(pubkey);

//     if (metadata != null && forceSearch == null) {
//       return metadata;
//     }

//     final List<String> relays = useOutbox()
//         ? feedRelaySet!.urls.toList()
//         : currentUserRelayList.reads.toList();
//     List<Metadata> loaded = [];

//     final future = nc.loadMissingMetadatas(
//       [pubkey],
//       relays,
//       forceSeach: forceSearch,
//     );

//     if (forceTimeout) {
//       loaded = await future.timeout(
//         const Duration(seconds: 2),
//         onTimeout: () {
//           return <Metadata>[];
//         },
//       );
//     } else {
//       loaded = await future;
//     }

//     if (loaded.isNotEmpty) {
//       await nc.db.saveMetadatas(loaded);
//       updateMetadatas(loaded);

//       return loaded.first;
//     }

//     return null;
//   }

//   Future<Metadata?> getMetadata(String pubkey) async {
//     if (pubkey.isEmpty) {
//       return null;
//     }

//     final metadata = await nc.db.loadMetadata(pubkey);

//     if (metadata != null) {
//       updateMetadatas([metadata]);
//       return metadata;
//     }

//     if (!_needUpdateMetadatas.contains(pubkey) && pubkey.isNotEmpty) {
//       _needUpdateMetadatas.add(pubkey);
//     }

//     later(_laterMetadataCallback, null);

//     return null;
//   }

//   Future<String?> getNip05Pubkey(String nip05) async {
//     final m = await nc.db.getMetadataByNip05(nip05);

//     if (m != null) {
//       return m.pubkey;
//     }

//     return Nip05.getPubkey(nip05);
//   }

//   // Stream<Metadata> watchMetadataWithNip05(
//   //   String pubkey, {
//   //   bool loadNip05 = true,
//   // }) {
//   //   return watchMetadata(pubkey).asyncMap((metadata) async {
//   //     bool isValid = false;

//   //     if (metadata == null) {
//   //       return MetadataWithNip05(Metadata.empty(pubkey: pubkey), isValid);
//   //     }

//   //     if (loadNip05) {
//   //       isValid = await fetchNip05(metadata).timeout(
//   //         const Duration(seconds: 2),
//   //         onTimeout: () => false,
//   //       );
//   //     }

//   //     return MetadataWithNip05(metadata, isValid);
//   //   });
//   // }

//   Stream<Metadata?> watchMetadataWithNip05(String pubkey) {
//     return watchMetadata(pubkey).asyncMap((metadata) async {
//       if (metadata != null) {
//         loadNip05(metadata);
//       }

//       return metadata;
//     });
//   }

//   Stream<Metadata?> watchMetadata(String pubkey) {
//     return nc.db.watchMetadata(pubkey);
//   }

//   Future<Metadata?> getCachedMetadata(String pubkey) async {
//     final metadata = await nc.db.loadMetadata(pubkey);

//     if (metadata != null) {
//       updateMetadatas([metadata]);
//     }

//     return metadata;
//   }

//   Future<Metadata> getAvailableMetadata(String pubkey,
//       {bool search = false}) async {
//     final metadata = search
//         ? (await getMetadata(pubkey))
//         : (await getCachedMetadata(pubkey));

//     return metadata ?? Metadata.empty().copyWith(pubkey: pubkey);
//   }

//   Future<Metadata> getInstantMetadata(String pubkey) async {
//     return (await getCachedMetadata(pubkey)) ??
//         (await getMetadata(pubkey)) ??
//         Metadata.empty().copyWith(pubkey: pubkey);
//   }

//   Future<void> loadNip05(
//     Metadata metadata,
//   ) async {
//     if (StringUtil.isNotBlank(metadata.nip05)) {
//       final nip05 = await nc.db.loadNip05(metadata.pubkey);

//       if (!state.nip05Status.containsKey(metadata.pubkey) &&
//           (nip05 == null || nip05.needsUpdate(NIP05_NEEDS_UPDATE_DURATION))) {
//         if (!_needUpdateNip05s.contains(metadata)) {
//           _needUpdateNip05s.add(metadata);

//           later(_laterNip05Callback, null);
//           updateNip05List({metadata.pubkey: false});
//         }
//       } else {
//         updateNip05List({metadata.pubkey: nip05?.valid ?? false});
//       }
//     } else {
//       updateNip05List({metadata.pubkey: false});
//     }
//   }

//   void updateNip05List(Map<String, bool> list) {
//     final toBeUpdated = Map<String, bool>.from(state.nip05Status);

//     toBeUpdated.addAll(list);

//     emit(state.copyWith(
//       nip05Status: toBeUpdated,
//     ));
//   }

//   Future<bool> isNip05Valid(Metadata metadata, {bool search = true}) async {
//     if (StringUtil.isNotBlank(metadata.nip05)) {
//       final nip05 = await nc.db.loadNip05(metadata.pubkey);

//       if (search &&
//           (nip05 == null || nip05.needsUpdate(NIP05_NEEDS_UPDATE_DURATION))) {
//         if (!_needUpdateNip05s.contains(metadata)) {
//           _needUpdateNip05s.add(metadata);

//           later(_laterNip05Callback, null);
//           return false;
//         }
//       }

//       return nip05?.valid ?? false;
//     }

//     return false;
//   }

//   Future<void> _loadNeedingUpdateMetadatas() async {
//     if (_needUpdateMetadatas.isEmpty) {
//       return;
//     }

//     final relays = useOutbox()
//         ? feedRelaySet!.urls.toList()
//         : currentUserRelayList.reads.toList();

//     final list = await nc.loadMissingMetadatas(
//       _needUpdateMetadatas,
//       relays,
//     );

//     updateMetadatas(list);

//     _needUpdateMetadatas.clear();
//   }

//   Future<bool> fetchNip05(Metadata metadata) async {
//     final cachedNip05 = await nc.db.loadNip05(metadata.pubkey);
//     if (cachedNip05 != null) {
//       return cachedNip05.valid;
//     }

//     final valid = await Nip05.check(metadata.nip05, metadata.pubkey);

//     final nip05 = Nip05(
//       pubkey: metadata.pubkey,
//       nip05: metadata.nip05,
//       valid: valid,
//       updatedAt: Helpers.now,
//     );

//     await nc.db.saveNip05(nip05);

//     return valid;
//   }

//   Future<void> _loadNeedingUpdateNip05s() async {
//     if (_needUpdateNip05s.isEmpty) {
//       return;
//     }

//     final List<Nip05> toSave = [];

//     final List<Metadata> doCheck = List.of(_needUpdateNip05s);

//     for (final metadata in doCheck) {
//       Nip05? nip05 = await nc.db.loadNip05(metadata.pubkey);
//       final valid = await Nip05.check(metadata.nip05, metadata.pubkey);

//       nip05 ??= Nip05(
//         pubkey: metadata.pubkey,
//         nip05: metadata.nip05,
//         valid: valid,
//         updatedAt: Helpers.now,
//       );

//       toSave.add(nip05.copyWith(
//         valid: valid,
//         updatedAt: Helpers.now,
//       ));
//     }

//     await nc.db.saveNip05s(toSave);

//     _needUpdateNip05s.clear();

//     if (toSave.isNotEmpty && !isClosed) {
//       emit(
//         state.copyWith(
//           nip05Pubkeys: {
//             ...state.nip05Pubkeys,
//             ...toSave
//                 .map(
//                   (e) => e.pubkey,
//                 )
//                 .toSet(),
//           },
//         ),
//       );
//     }
//   }

//   Future<List<Metadata>> searchCacheMetadatas(String search) async {
//     return nc.db.searchMetadatas(search, 50);
//   }

//   Future<List<Metadata>> searchCacheMetadatasFromContactList(
//     String search,
//   ) async {
//     final contactList = contactListCubit.contacts;

//     if (contactList.isEmpty) {
//       return [];
//     }

//     return nc.db.searchRelatedMetadatas(search, contactList, 30);
//   }

//   void updateMetadatas(List<Metadata> metadatas) {
//     if (!isClosed) {
//       emit(
//         state.copyWith(
//           metadataPubkeys: {
//             ...state.metadataPubkeys,
//             ...metadatas.map(
//               (e) => e.pubkey,
//             ),
//           },
//         ),
//       );
//     }
//   }

//   Future<void> clear() async {
//     await Future.wait([
//       nc.db.removeAllMetadatas(),
//       nc.db.removeAllNip05s(),
//     ]);
//   }
// }

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

    final updatedCache = Map<String, Metadata>.from(state.metadataCache);
    final updatedPubkeys = Set<String>.from(state.metadataPubkeys);

    final searchNip05 = <Metadata>[];

    for (final metadata in metadatas) {
      updatedCache[metadata.pubkey] = metadata;

      updatedPubkeys.add(metadata.pubkey);
      _accessTimes[metadata.pubkey] = Helpers.now;

      // Auto-load nip05 if present
      if (StringUtil.isNotBlank(metadata.nip05) &&
          !state.nip05Status.containsKey(metadata.pubkey)) {
        searchNip05.add(metadata);
      }
    }

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
      prunedCache[pubkey] = state.metadataCache[pubkey]!;
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
