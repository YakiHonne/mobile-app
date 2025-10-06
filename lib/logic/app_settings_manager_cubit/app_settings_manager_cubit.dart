// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';
import 'package:nostr_core_enhanced/models/dvm_model.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/common_regex.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'app_settings_manager_state.dart';

// ==================================================
// APP SETTINGS MANAGER CUBIT
// ==================================================

class AppSettingsManagerCubit extends Cubit<AppSettingsManagerState> {
  AppSettingsManagerCubit() : super(_initialState);

  // ==================================================
  // CONSTANTS & INITIAL STATE
  // ==================================================

  static const AppSettingsManagerState _initialState = AppSettingsManagerState(
    discoverFilters: {},
    notesFilters: {},
    selectedDiscoverFilter: '',
    selectedNotesFilter: '',
    discoverCommunity: {},
    discoverDvms: {},
    selectedDiscoverSource: MapEntry('', ''),
    discoverSources: [],
    notesCommunity: {},
    notesDvms: {},
    notesSources: [],
    selectedNotesSource: MapEntry('', ''),
    favoriteRelays: [],
  );

  // ==================================================
  // PROPERTIES
  // ==================================================

  late AppSharedSettings appSharedSettings;
  Timer? _connectivityTimer;

  // ==================================================
  // SAFE EMIT FUNCTION
  // ==================================================

  /// Safe emit function that checks if cubit is closed before emitting
  void _safeEmit(AppSettingsManagerState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  @override
  Future<void> close() {
    _connectivityTimer?.cancel();
    return super.close();
  }

  // ==================================================
  // INITIALIZATION & RESET
  // ==================================================

  Future<void> reset() async {
    _safeEmit(_initialState);
  }

  Future<void> loadAppSharedSettings() async {
    if (canSign()) {
      await _loadSignedUserSettings();
      syncAppSettings();
    } else {
      await _loadDefaultSettings();
    }
  }

  Future<void> _loadSignedUserSettings() async {
    final settings = await nc.db.loadUserAppSettings(
      currentSigner!.getPublicKey(),
    );

    if (settings == null) {
      appSharedSettings = AppSharedSettings.defaultEmptySettings(
        pubkey: currentSigner!.getPublicKey(),
      );
    } else {
      appSharedSettings = settings;
    }

    loadCurrentAppSettings(appSharedSettings);
    saveAppSettingsInCache();
  }

  Future<void> _loadDefaultSettings() async {
    appSharedSettings = AppSharedSettings.defaultEmptySettings();
    loadCurrentAppSettings(appSharedSettings);
  }

  // ==================================================
  // SETTINGS LOADING & STATE MANAGEMENT
  // ==================================================

  void loadCurrentAppSettings(AppSharedSettings settings) {
    appSharedSettings = settings;
    final df = appSharedSettings.filters.getDiscoverMappedContent();
    final nf = appSharedSettings.filters.getNotesMappedContent();
    final ds = appSharedSettings.contentSources.discoverSources;
    final ns = appSharedSettings.contentSources.notesSources;

    final sdf = nostrRepository.filterStatus.discoverFilter
        ? df.isNotEmpty
            ? df.entries.first.key
            : ''
        : '';

    final snf = nostrRepository.filterStatus.leadingFilter
        ? nf.isNotEmpty
            ? nf.entries.first.key
            : ''
        : '';

    _safeEmit(
      state.copyWith(
        discoverFilters: df,
        selectedDiscoverFilter: sdf,
        discoverCommunity: ds.communityFeed.getMappedContent(),
        selectedDiscoverSource: ds.getFirstDiscoverSource(),
        discoverSources: ds.getFeedsByOrder(),
        notesFilters: nf,
        selectedNotesFilter: snf,
        notesCommunity: ns.communityFeed.getMappedContent(),
        selectedNotesSource: ns.getFirstNotesSource(),
        notesSources: ns.getFeedsByOrder(),
      ),
    );

    setFavoriteRelaysConnection();
  }

  AppSharedSettings getAppSharedSettingsCopy() {
    final copy = appSharedSettings.deepCopy();

    return copy;
  }

  // ==================================================
  // RELAY CONNECTIVITY & MANAGEMENT
  // ==================================================

  Future<bool> checkRelayConnectivity(String relay) async {
    final completer = Completer<bool>();

    _connectivityTimer?.cancel();
    _connectivityTimer = Timer(
      const Duration(milliseconds: 500),
      () => _performConnectivityCheck(relay, completer),
    );

    return completer.future;
  }

  Future<void> _performConnectivityCheck(
    String relay,
    Completer<bool> completer,
  ) async {
    final r = getProperRelayUrl(relay);

    final relayAvailable = nc.relays().contains(r);

    if (relayAvailable && nc.connectStatus[r] == 1) {
      completer.complete(true);
      return;
    }

    await nc.connect(r);
    lg.i(nc.connectStatus);
    final isConnected = nc.relays().contains(r) && nc.connectStatus[r] == 1;
    if (!relayAvailable) {
      nc.closeConnect([r]);
    }

    completer.complete(isConnected);
  }

  Future<void> setFavoriteRelaysConnection() async {
    final relays = state.favoriteRelays;

    await nc.connectNonConnectedRelays(relays.toSet());
  }

  // ==================================================
  // SYNCHRONIZATION & PERSISTENCE
  // ==================================================
  String? getNoteSourceRelay() {
    final snc = appSettingsManagerCubit.state.selectedNotesSource.key;

    if (relayRegExp.hasMatch(snc)) {
      return snc;
    }

    return null;
  }

  Future<void> syncAppSettings({bool override = false}) async {
    await Future.delayed(const Duration(seconds: 2));

    final ev = await Future.wait(
      [
        NostrFunctionsRepository.getEventById(
          eventId: yakiAppSettingsTag,
          isIdentifier: true,
          author: currentSigner!.getPublicKey(),
          kinds: [EventKind.APP_CUSTOM],
        ),
        NostrFunctionsRepository.getEventById(
          isIdentifier: false,
          author: currentSigner!.getPublicKey(),
          kinds: [EventKind.FAVORITE_RELAYS],
        ),
      ],
    );

    final ase = ev[0];
    final fr = ev[1];

    if (ase != null) {
      final as = AppSharedSettings.fromEvent(ase);

      if (as.toJson() != appSharedSettings.toJson()) {
        appSharedSettings = as;
        loadCurrentAppSettings(appSharedSettings);
        saveAppSettingsInCache();
      }
    }

    if (fr != null) {
      await Future.delayed(const Duration(milliseconds: 500)).then(
        (_) {
          setFavoriteRelayFromEvent(fr);
        },
      );
    }
  }

  Future<void> setAndSave(bool isDiscover) async {
    await Future.wait([
      setAppSettings(isDiscover),
      setFavoriteRelays(),
    ]);

    saveAppSettingsInCache();
  }

  Future<bool> setAppSettings(bool isDiscover) async {
    final event = await Event.genEvent(
      kind: EventKind.APP_CUSTOM,
      tags: [
        ['d', yakiAppSettingsTag],
        getClientTag(),
      ],
      content: appSharedSettings.eventContent(),
      signer: currentSigner,
    );

    if (event == null) {
      return false;
    }

    return NostrFunctionsRepository.sendEvent(
      event: event,
      setProgress: false,
    );
  }

  Future<bool> setFavoriteRelays() async {
    final event = await Event.genEvent(
      kind: EventKind.FAVORITE_RELAYS,
      tags: [
        for (final relay in state.favoriteRelays) ['relay', relay],
      ],
      content: '',
      signer: currentSigner,
    );

    if (event == null) {
      return false;
    }

    nc.db.saveEvent(event);

    return NostrFunctionsRepository.sendEvent(
      event: event,
      setProgress: false,
    );
  }

  void saveAppSettingsInCache() {
    nc.db.saveUserAppSettings(appSharedSettings);
  }

  // ==================================================
  // FAVORITE RELAYS MANAGEMENT
  // ==================================================

  void setFavoriteRelayFromEvent(Event event) {
    final relays = event.tags
        .where(
          (r) => r.length > 1 && r.first == 'relay',
        )
        .toList();

    if (relays.isNotEmpty) {
      final cleanRelays = <String>[];

      for (final r in relays) {
        final cr = Relay.clean(r[1]);
        if (cr != null) {
          cleanRelays.add(cr);
        }
      }

      nc.connectRelays(cleanRelays);

      _safeEmit(
        state.copyWith(
          favoriteRelays: cleanRelays,
        ),
      );
    }
  }

  void updateFavoriteRelays(String relay) {
    final relays = List<String>.from(state.favoriteRelays);

    _safeEmit(state.copyWith(
      favoriteRelays: relays.contains(relay)
          ? (relays..remove(relay))
          : (relays..add(relay)),
    ));
  }

  Future<void> setAndUpdateFavoriteRelay(String relay) async {
    final cancel = BotToast.showLoading();

    updateFavoriteRelays(relay);
    final isSuccessful = await setFavoriteRelays();

    if (isSuccessful) {
      BotToastUtils.showSuccess(t.relaysListUpdated);
    } else {
      BotToastUtils.showSuccess(t.errorUpdatingRelaysList);
    }

    cancel.call();
  }

  void setUpdatedFavoriteRelays(List<String> relays) {
    _safeEmit(state.copyWith(favoriteRelays: relays));
  }

  // ==================================================
  // SOURCES MANAGEMENT
  // ==================================================

  void setSource({
    required MapEntry<String, String> source,
    required bool isDiscover,
  }) {
    _safeEmit(state.copyWith(
      selectedDiscoverSource: isDiscover ? source : null,
      selectedNotesSource: !isDiscover ? source : null,
    ));
  }

  Future<void> updateSources({
    required AppSharedSettings settings,
    required bool isDiscover,
    required List<String> favoriteRelays,
  }) async {
    appSharedSettings = settings;
    setUpdatedFavoriteRelays(favoriteRelays);
    await setAndSave(isDiscover);

    final ds = appSharedSettings.contentSources.discoverSources;
    final ns = appSharedSettings.contentSources.notesSources;

    _safeEmit(
      state.copyWith(
        discoverCommunity: ds.communityFeed.getMappedContent(),
        selectedDiscoverSource: ds.getCurrentSelectedDiscoverSource(
          state.selectedDiscoverSource,
        ),
        discoverSources: ds.getFeedsByOrder(),
        notesCommunity: ns.communityFeed.getMappedContent(),
        selectedNotesSource: ns.getCurrentSelectedNoteSource(
          state.selectedNotesSource,
        ),
        notesSources: ns.getFeedsByOrder(),
      ),
    );

    setFavoriteRelaysConnection();

    BotToastUtils.showSuccess(gc.t.feedSetUpdate);
  }

  MapEntry<AppContentSource, MapEntry<String, String>>
      getDiscoverSelectedSource() {
    final selectedSource = state.selectedDiscoverSource;
    final sources = appSharedSettings.contentSources.discoverSources;

    final communityContent = sources.communityFeed.getMappedContent();

    if (communityContent.keys.contains(selectedSource.key)) {
      return MapEntry(AppContentSource.community, selectedSource);
    }

    return MapEntry(AppContentSource.algo, selectedSource);
  }

  MapEntry<AppContentSource, MapEntry<String, String>>
      getNotesSelectedSource() {
    final selectedSource = state.selectedNotesSource;
    final sources = appSharedSettings.contentSources.notesSources;

    final communityContent = sources.communityFeed.getMappedContent();

    if (communityContent.keys.contains(selectedSource.key)) {
      return MapEntry(AppContentSource.community, selectedSource);
    }

    return MapEntry(AppContentSource.algo, selectedSource);
  }

  // ==================================================
  // FILTER MANAGEMENT
  // ==================================================

  void setFilter({required String id, required bool isDiscover}) {
    nostrRepository.setFilterStatus(
      isLeading: !isDiscover,
      status: id.isNotEmpty,
    );

    _safeEmit(state.copyWith(
      selectedDiscoverFilter: isDiscover ? id : null,
      selectedNotesFilter: !isDiscover ? id : null,
    ));
  }

  void deleteFilter({required String id, required bool isDiscover}) {
    if (isDiscover) {
      _deleteDiscoverFilter(id);
    } else {
      _deleteNotesFilter(id);
    }

    BotToastUtils.showSuccess(gc.t.filterDeleted);
    setAndSave(isDiscover);
  }

  void _deleteDiscoverFilter(String id) {
    appSharedSettings.filters.discoverFilters.removeWhere(
      (filter) => filter.id == id,
    );

    final filters = Map<String, DiscoverFilter>.from(state.discoverFilters)
      ..removeWhere((key, value) => key == id);

    final newSelected = state.selectedDiscoverFilter == id
        ? filters.isEmpty
            ? ''
            : filters.keys.first
        : state.selectedDiscoverFilter;

    nostrRepository.setFilterStatus(
        isLeading: false, status: newSelected.isNotEmpty);

    _safeEmit(state.copyWith(
      discoverFilters: filters,
      selectedDiscoverFilter: newSelected,
    ));
  }

  void _deleteNotesFilter(String id) {
    appSharedSettings.filters.notesFilters.removeWhere(
      (filter) => filter.id == id,
    );

    final filters = Map<String, NotesFilter>.from(state.notesFilters)
      ..removeWhere((key, value) => key == id);

    final newSelected = state.selectedNotesFilter == id
        ? filters.isEmpty
            ? ''
            : filters.keys.first
        : state.selectedNotesFilter;

    nostrRepository.setFilterStatus(
        isLeading: true, status: newSelected.isNotEmpty);

    _safeEmit(state.copyWith(
      notesFilters: filters,
      selectedNotesFilter: newSelected,
    ));
  }

  // ==================================================
  // DISCOVER FILTER METHODS
  // ==================================================

  DiscoverFilter getSelectedDiscoverFilter() {
    return state.discoverFilters[state.selectedDiscoverFilter] ??
        DiscoverFilter.defaultFilter();
  }

  Future<void> addDiscoverFilter({required DiscoverFilter filter}) async {
    appSharedSettings.filters.discoverFilters.add(filter);
    await setAndSave(true);

    final updatedFilters =
        Map<String, DiscoverFilter>.from(state.discoverFilters);
    updatedFilters[filter.id] = filter;

    nostrRepository.setFilterStatus(isLeading: false, status: true);

    _safeEmit(state.copyWith(
      selectedDiscoverFilter: filter.id,
      discoverFilters: updatedFilters,
    ));

    BotToastUtils.showSuccess(gc.t.filterAdded);
  }

  Future<void> updateDiscoverFilter({required DiscoverFilter filter}) async {
    final index = appSharedSettings.filters.discoverFilters.indexWhere(
      (element) => element.id == filter.id,
    );

    if (index != -1) {
      appSharedSettings.filters.discoverFilters[index] = filter;
    }

    final updatedFilters =
        Map<String, DiscoverFilter>.from(state.discoverFilters);
    updatedFilters[filter.id] = filter;

    nostrRepository.setFilterStatus(isLeading: false, status: true);

    _safeEmit(state.copyWith(
      selectedDiscoverFilter: filter.id,
      discoverFilters: updatedFilters,
    ));

    setAndSave(true);
    BotToastUtils.showSuccess(gc.t.filterUpdated);
  }

  // ==================================================
  // NOTES FILTER METHODS
  // ==================================================

  NotesFilter getSelectedNotesFilter() {
    return state.notesFilters[state.selectedNotesFilter] ??
        NotesFilter.defaultFilter();
  }

  Future<void> addNotesFilter({required NotesFilter filter}) async {
    appSharedSettings.filters.notesFilters.add(filter);

    final updatedFilters = Map<String, NotesFilter>.from(state.notesFilters);
    updatedFilters[filter.id] = filter;

    nostrRepository.setFilterStatus(isLeading: true, status: true);

    _safeEmit(state.copyWith(
      selectedNotesFilter: filter.id,
      notesFilters: updatedFilters,
    ));

    setAndSave(false);
    BotToastUtils.showSuccess(gc.t.filterAdded);
  }

  Future<void> updateNotesFilter({required NotesFilter filter}) async {
    final index = appSharedSettings.filters.notesFilters.indexWhere(
      (element) => element.id == filter.id,
    );

    if (index != -1) {
      appSharedSettings.filters.notesFilters[index] = filter;
    }

    final updatedFilters = Map<String, NotesFilter>.from(state.notesFilters);
    updatedFilters[filter.id] = filter;

    nostrRepository.setFilterStatus(isLeading: true, status: true);

    _safeEmit(state.copyWith(
      selectedNotesFilter: filter.id,
      notesFilters: updatedFilters,
    ));

    setAndSave(false);
    BotToastUtils.showSuccess(gc.t.filterUpdated);
  }

  Future<bool> republishEvent({
    required Event event,
    required Set<String> relays,
  }) async {
    if (relays.isEmpty) {
      BotToastUtils.showError(t.useRelayRepublish);
      return false;
    }

    final newRelays = event.seenOn.toSet();
    newRelays.addAll(relays);

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event.copyWith(
        seenOn: newRelays.toList(),
      ),
      setProgress: true,
      relays: relays.toList(),
      relyOnUnsentEvents: false,
    );

    if (isSuccessful) {
      BotToastUtils.showSuccess(t.republishSucces);
      return true;
    } else {
      BotToastUtils.showError(t.errorRepublishEvent);
      return false;
    }
  }
}
