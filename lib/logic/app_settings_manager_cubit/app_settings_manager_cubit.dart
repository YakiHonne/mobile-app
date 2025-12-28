// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/common_regex.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/app_view_config.dart';
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
    selectedDiscoverSource: MapEntry('', ''),
    discoverSources: [],
    notesCommunity: {},
    notesSources: [],
    selectedNotesSource: MapEntry('', ''),
    mediaFilters: {},
    selectedMediaFilter: '',
    mediaSources: [],
    mediaCommunity: {},
    selectedMediaSource: MapEntry('', ''),
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
    loadSelectedLocalSource();
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
    final mf = appSharedSettings.filters.getMediaMappedContent();
    final ds = appSharedSettings.contentSources.discoverSources;
    final ns = appSharedSettings.contentSources.notesSources;
    final ms = appSharedSettings.contentSources.mediaSources;

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

    final smf = nostrRepository.filterStatus.mediaFilter
        ? mf.isNotEmpty
            ? mf.entries.first.key
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
        mediaFilters: mf,
        selectedMediaFilter: smf,
        mediaSources: ms.getFeedsByOrder(),
        mediaCommunity: ms.communityFeed.getMappedContent(),
        selectedMediaSource: ms.getFirstMediaSource(),
      ),
    );
  }

  AppSharedSettings getAppSharedSettingsCopy() {
    return appSharedSettings.deepCopy();
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

    final isConnected = await nc.checkRelayConnectivity(r);

    completer.complete(isConnected);
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

    final ase = await NostrFunctionsRepository.getEventById(
      eventId: yakiAppSettingsTag,
      isIdentifier: true,
      author: currentSigner!.getPublicKey(),
      kinds: [EventKind.APP_CUSTOM],
    );

    if (ase != null) {
      final as = AppSharedSettings.fromEvent(ase);

      if (as.toJson() != appSharedSettings.toJson()) {
        appSharedSettings = as;
        loadCurrentAppSettings(appSharedSettings);
        saveAppSettingsInCache();
      }
    }
  }

  Future<void> setAndSave() async {
    await setAppSettings();

    saveAppSettingsInCache();
  }

  Future<bool> setAppSettings() async {
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

  void saveAppSettingsInCache() {
    nc.db.saveUserAppSettings(appSharedSettings);
  }

  // ==================================================
  // SOURCES MANAGEMENT
  // ==================================================

  void setSource({
    required MapEntry<String, dynamic> source,
    required ViewDataTypes viewType,
  }) {
    _safeEmit(state.copyWith(
      selectedDiscoverSource:
          viewType == ViewDataTypes.articles ? source : null,
      selectedNotesSource: viewType == ViewDataTypes.notes ? source : null,
      selectedMediaSource: viewType == ViewDataTypes.media ? source : null,
    ));

    setSourceLocally(viewType: viewType);
  }

  void loadSelectedLocalSource() {
    nostrRepository.loadAppViewConfig();
    final config = nostrRepository.currentAppViewConfig;

    if (config == null) {
      return;
    }

    _safeEmit(
      state.copyWith(
        selectedDiscoverSource: config.selectedArticlesSource,
        selectedNotesSource: config.selectedLeadingSource,
        selectedMediaSource: config.selectedMediaSource,
      ),
    );
  }

  void setSourceLocally({
    required ViewDataTypes viewType,
  }) {
    final currentConfig = nostrRepository.currentAppViewConfig!;
    AppViewConfig? newConfig;

    if (viewType == ViewDataTypes.articles) {
      final source = getDiscoverSelectedSource();
      newConfig = currentConfig.copyWith(
        selectedArticlesSourceType: source.key,
        selectedArticlesSource: source.value,
      );
    } else if (viewType == ViewDataTypes.notes) {
      final source = getNotesSelectedSource();
      newConfig = currentConfig.copyWith(
        selectedLeadingSourceType: source.key,
        selectedLeadingSource: source.value,
      );
    } else if (viewType == ViewDataTypes.media) {
      final source = getMediaSelectedSource();
      newConfig = currentConfig.copyWith(
        selectedMediaSourceType: source.key,
        selectedMediaSource: source.value,
      );
    }

    if (newConfig != null) {
      nostrRepository.setAppViewConfig(newConfig);
    }
  }

  Future<void> updateSources({
    required AppSharedSettings settings,
  }) async {
    appSharedSettings = settings;
    await setAndSave();

    final ds = appSharedSettings.contentSources.discoverSources;
    final ns = appSharedSettings.contentSources.notesSources;
    final ms = appSharedSettings.contentSources.mediaSources;

    _safeEmit(
      state.copyWith(
        discoverCommunity: ds.communityFeed.getMappedContent(),
        selectedDiscoverSource: ds.getCurrentSelectedDiscoverSource(
          state.selectedDiscoverSource is MapEntry<String, String>
              ? state.selectedDiscoverSource as MapEntry<String, String>
              : const MapEntry('', ''),
        ),
        discoverSources: ds.getFeedsByOrder(),
        notesCommunity: ns.communityFeed.getMappedContent(),
        selectedNotesSource: ns.getCurrentSelectedNoteSource(
          state.selectedNotesSource is MapEntry<String, String>
              ? state.selectedNotesSource as MapEntry<String, String>
              : const MapEntry('', ''),
        ),
        notesSources: ns.getFeedsByOrder(),
        mediaCommunity: ms.communityFeed.getMappedContent(),
        selectedMediaSource: ms.getCurrentSelectedMediaSource(
          state.selectedMediaSource is MapEntry<String, String>
              ? state.selectedMediaSource as MapEntry<String, String>
              : const MapEntry('', ''),
        ),
        mediaSources: ms.getFeedsByOrder(),
      ),
    );

    BotToastUtils.showSuccess(gc.t.feedSetUpdate);
  }

  MapEntry<AppContentSource, MapEntry<String, dynamic>>
      getDiscoverSelectedSource() {
    final selectedSource = state.selectedDiscoverSource;
    final sources = appSharedSettings.contentSources.discoverSources;

    final communityContent = sources.communityFeed.getMappedContent();

    if (communityContent.values
        .map(
          (e) => e.name,
        )
        .contains(selectedSource.value)) {
      return MapEntry(AppContentSource.community, selectedSource);
    }

    if (selectedSource.value is String) {
      return MapEntry(AppContentSource.relay, selectedSource);
    } else {
      return MapEntry(AppContentSource.relaySet, selectedSource);
    }
  }

  MapEntry<AppContentSource, MapEntry<String, dynamic>>
      getMediaSelectedSource() {
    final selectedSource = state.selectedMediaSource;
    final sources = appSharedSettings.contentSources.mediaSources;

    final communityContent = sources.communityFeed.getMappedContent();

    if (communityContent.values
        .map(
          (e) => e.name,
        )
        .contains(selectedSource.value)) {
      return MapEntry(AppContentSource.community, selectedSource);
    }

    if (selectedSource.value is String) {
      return MapEntry(AppContentSource.relay, selectedSource);
    } else {
      return MapEntry(AppContentSource.relaySet, selectedSource);
    }
  }

  MapEntry<AppContentSource, MapEntry<String, dynamic>>
      getNotesSelectedSource() {
    final selectedSource = state.selectedNotesSource;
    final sources = appSharedSettings.contentSources.notesSources;

    final communityContent = sources.communityFeed.getMappedContent();

    if (communityContent.values
        .map(
          (e) => e.name,
        )
        .contains(selectedSource.value)) {
      return MapEntry(AppContentSource.community, selectedSource);
    }

    if (selectedSource.value is String) {
      return MapEntry(AppContentSource.relay, selectedSource);
    } else {
      return MapEntry(AppContentSource.relaySet, selectedSource);
    }
  }

  // ==================================================
  // FILTER MANAGEMENT
  // ==================================================

  void setFilter({required String id, required ViewDataTypes viewType}) {
    nostrRepository.setFilterStatus(
      viewType: viewType,
      status: id.isNotEmpty,
    );

    _safeEmit(state.copyWith(
      selectedDiscoverFilter: viewType == ViewDataTypes.articles ? id : null,
      selectedNotesFilter: viewType == ViewDataTypes.notes ? id : null,
      selectedMediaFilter: viewType == ViewDataTypes.media ? id : null,
    ));
  }

  void deleteFilter({required String id, required ViewDataTypes viewType}) {
    if (viewType == ViewDataTypes.articles) {
      _deleteDiscoverFilter(id);
    } else if (viewType == ViewDataTypes.media) {
      _deleteMediaFilter(id);
    } else {
      _deleteNotesFilter(id);
    }

    BotToastUtils.showSuccess(gc.t.filterDeleted);
    setAndSave();
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
      viewType: ViewDataTypes.articles,
      status: newSelected.isNotEmpty,
    );

    _safeEmit(state.copyWith(
      discoverFilters: filters,
      selectedDiscoverFilter: newSelected,
    ));
  }

  void _deleteMediaFilter(String id) {
    appSharedSettings.filters.mediaFilters.removeWhere(
      (filter) => filter.id == id,
    );

    final filters = Map<String, MediaFilter>.from(state.mediaFilters)
      ..removeWhere((key, value) => key == id);

    final newSelected = state.selectedMediaFilter == id
        ? filters.isEmpty
            ? ''
            : filters.keys.first
        : state.selectedMediaFilter;

    nostrRepository.setFilterStatus(
      viewType: ViewDataTypes.media,
      status: newSelected.isNotEmpty,
    );

    _safeEmit(state.copyWith(
      mediaFilters: filters,
      selectedMediaFilter: newSelected,
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
      viewType: ViewDataTypes.notes,
      status: newSelected.isNotEmpty,
    );

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
    await setAndSave();

    final updatedFilters =
        Map<String, DiscoverFilter>.from(state.discoverFilters);
    updatedFilters[filter.id] = filter;

    nostrRepository.setFilterStatus(
      viewType: ViewDataTypes.articles,
      status: true,
    );

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

    nostrRepository.setFilterStatus(
      viewType: ViewDataTypes.articles,
      status: true,
    );

    _safeEmit(state.copyWith(
      selectedDiscoverFilter: filter.id,
      discoverFilters: updatedFilters,
    ));

    setAndSave();
    BotToastUtils.showSuccess(gc.t.filterUpdated);
  }

  // ==================================================
  // MEDIA FILTER METHODS
  // ==================================================

  MediaFilter getSelectedMediaFilter() {
    return state.mediaFilters[state.selectedMediaFilter] ??
        MediaFilter.defaultFilter();
  }

  Future<void> addMediaFilter({required MediaFilter filter}) async {
    appSharedSettings.filters.mediaFilters.add(filter);
    await setAndSave();

    final updatedFilters = Map<String, MediaFilter>.from(state.mediaFilters);
    updatedFilters[filter.id] = filter;

    nostrRepository.setFilterStatus(
      viewType: ViewDataTypes.media,
      status: true,
    );

    _safeEmit(state.copyWith(
      selectedMediaFilter: filter.id,
      mediaFilters: updatedFilters,
    ));

    BotToastUtils.showSuccess(gc.t.filterAdded);
  }

  Future<void> updateMediaFilter({required MediaFilter filter}) async {
    final index = appSharedSettings.filters.mediaFilters.indexWhere(
      (element) => element.id == filter.id,
    );

    if (index != -1) {
      appSharedSettings.filters.mediaFilters[index] = filter;
    }

    final updatedFilters = Map<String, MediaFilter>.from(state.mediaFilters);
    updatedFilters[filter.id] = filter;

    nostrRepository.setFilterStatus(
      viewType: ViewDataTypes.media,
      status: true,
    );

    _safeEmit(state.copyWith(
      selectedMediaFilter: filter.id,
      mediaFilters: updatedFilters,
    ));

    setAndSave();
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

    nostrRepository.setFilterStatus(
      viewType: ViewDataTypes.notes,
      status: true,
    );

    _safeEmit(state.copyWith(
      selectedNotesFilter: filter.id,
      notesFilters: updatedFilters,
    ));

    setAndSave();
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

    nostrRepository.setFilterStatus(
      viewType: ViewDataTypes.notes,
      status: true,
    );

    _safeEmit(state.copyWith(
      selectedNotesFilter: filter.id,
      notesFilters: updatedFilters,
    ));

    setAndSave();
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
