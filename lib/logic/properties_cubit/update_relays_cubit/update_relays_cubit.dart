// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../common/common_regex.dart';
import '../../../repositories/nostr_data_repository.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'update_relays_state.dart';

class UpdateRelaysCubit extends Cubit<UpdateRelaysState> {
  UpdateRelaysCubit({
    required this.nostrRepository,
  }) : super(
          UpdateRelaysState(
            activeRelays:
                nc.currentUserActiveRelays(currentUserRelayList.urls.toList()),
            relays: currentUserRelayList.relays,
            isSameRelays: true,
            onlineRelays: const [],
            pendingRelays: const {},
            toBeDeleted: const {},
            dmRelays: nostrRepository.dmRelays,
            searchRelays: nostrRepository.searchRelays,
            activeSearchRelays: const [],
          ),
        ) {
    _initializeState();
    _updateActiveSearchRelays();
  }

  static const Duration _relayStatusUpdateInterval = Duration(seconds: 3);

  final NostrDataRepository nostrRepository;
  Timer? _statusTimer;
  List<String> _currentRelays = [];
  bool _isSameAsOriginal = true;

  /// Initialize the cubit state and start relay status monitoring
  void _initializeState() {
    _currentRelays = currentUserRelayList.urls.toList();
    _startRelayStatusMonitoring();
  }

  /// Start periodic monitoring of relay status
  void _startRelayStatusMonitoring() {
    _statusTimer?.cancel(); // Ensure no duplicate timers
    _statusTimer = Timer.periodic(
      _relayStatusUpdateInterval,
      _onRelayStatusTimer,
    );
  }

  /// Handle relay status timer tick
  void _onRelayStatusTimer(Timer timer) {
    if (isClosed) {
      timer.cancel();
      return;
    }

    final activeRelays = nc.currentUserActiveRelays({
      ...currentUserRelayList.urls,
      ...nostrRepository.dmRelays,
    }.toList());

    _emitIfNotClosed(
      state.copyWith(
        activeRelays: activeRelays,
      ),
    );
  }

  /// Safely emit state only if cubit is not closed
  void _emitIfNotClosed(UpdateRelaysState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  /// Update relays with improved error handling and state management
  Future<void> updateRelays({
    required Function() onSuccess,
  }) async {
    final cancelLoading = BotToast.showLoading();

    try {
      final updatedRelayMap = _buildUpdatedRelayMap();
      final userRelaySet = await _setNip65Relays(updatedRelayMap);

      if (userRelaySet != null) {
        await _handleSuccessfulUpdate(userRelaySet, onSuccess);
      } else {
        _handleUpdateFailure();
      }
    } catch (e) {
      _handleUpdateError(e);
    } finally {
      cancelLoading.call();
    }
  }

  /// Build the updated relay map by merging current and pending relays
  Map<String, ReadWriteMarker> _buildUpdatedRelayMap() {
    final updatedRelays = <String, ReadWriteMarker>{
      ...state.relays,
      ...state.pendingRelays,
    };

    // Remove relays marked for deletion
    updatedRelays.removeWhere((key, value) => state.toBeDeleted.contains(key));

    return updatedRelays;
  }

  /// Call the NIP-65 relay setting with proper error handling
  Future<UserRelayList?> _setNip65Relays(
    Map<String, ReadWriteMarker> relayMap,
  ) async {
    if (currentSigner == null) {
      throw Exception('Current signer is null');
    }

    return nc.setNip65Relays(
      relayMap,
      [
        ...(state.activeRelays.isEmpty ? [] : currentUserRelayList.writes),
        ...DEFAULT_BOOTSTRAP_RELAYS,
      ],
      currentSigner!,
      (ok, relay, unCompletedRelays) {},
    );
  }

  Future<void> updateDmRelay({
    required String relay,
    required bool isAdding,
    Function()? onSuccess,
  }) async {
    if (state.dmRelays.contains(relay) && isAdding) {
      _showErrorMessage(gc.t.relayInUse);
      return;
    }

    final relays = List<String>.from(state.dmRelays);

    if (isAdding) {
      relays.insert(0, relay);
    } else {
      relays.remove(relay);
    }

    final rTags = relays.map((e) => ['relay', e]).toList();

    final ev = await Event.genEvent(
      kind: EventKind.DM_RELAYS,
      tags: rTags,
      content: '',
      signer: currentSigner,
    );

    if (ev == null) {
      _showErrorMessage(gc.t.errorGeneratingEvent);
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: ev,
      setProgress: true,
    );

    if (isSuccessful) {
      if (isAdding) {
        await nc.connect(relay);
      } else {
        if (!state.activeRelays.contains(relay)) {
          nc.closeConnect([relay]);
        }
      }

      nostrRepository.dmRelays = relays;
      final activeRelays = nc.currentUserActiveRelays(
        <String>{...currentUserRelayList.urls, ...relays}.toList(),
      );

      _emitIfNotClosed(
        state.copyWith(
          dmRelays: relays,
          activeRelays: activeRelays,
        ),
      );

      onSuccess?.call();
    } else {
      _showErrorMessage(t.errorSendingEvent);
    }
  }

  /// Update active search relays
  Future<void> _updateActiveSearchRelays() async {
    final activeSearchRelays = List<String>.from(state.activeSearchRelays);
    final nonCheckedSearchRelays = List<String>.from(state.searchRelays)
      ..removeWhere(
        (element) => activeSearchRelays.contains(element),
      );

    if (nonCheckedSearchRelays.isNotEmpty) {
      final res = await Future.wait(
        nonCheckedSearchRelays.map(
          (r) => nc.checkRelayConnectivity(r),
        ),
      );

      for (int i = 0; i < res.length; i++) {
        if (res[i]) {
          activeSearchRelays.add(nonCheckedSearchRelays[i]);
        }
      }

      if (activeSearchRelays.isNotEmpty) {
        _emitIfNotClosed(
          state.copyWith(
            activeSearchRelays: activeSearchRelays,
          ),
        );
      }
    }
  }

  Future<void> updateSearchRelay({
    required String relay,
    required bool isAdding,
  }) async {
    if (state.searchRelays.contains(relay) && isAdding) {
      _showErrorMessage(gc.t.relayInUse);
      return;
    }

    final relays = List<String>.from(state.searchRelays);

    if (isAdding) {
      relays.insert(0, relay);
    } else {
      relays.remove(relay);
    }

    final rTags = relays.map((e) => ['relay', e]).toList();

    final ev = await Event.genEvent(
      kind: EventKind.SEARCH_RELAYS,
      tags: rTags,
      content: '',
      signer: currentSigner,
    );

    if (ev == null) {
      _showErrorMessage(gc.t.errorGeneratingEvent);
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: ev,
      setProgress: true,
    );

    if (isSuccessful) {
      _emitIfNotClosed(
        state.copyWith(
          searchRelays: relays,
        ),
      );

      nostrRepository.searchRelays = relays;
      _updateActiveSearchRelays();
    } else {
      _showErrorMessage(t.errorSendingEvent);
    }
  }

  /// Handle successful relay update
  Future<void> _handleSuccessfulUpdate(
    UserRelayList userRelaySet,
    Function() onSuccess,
  ) async {
    currentUserRelayList = userRelaySet;
    _currentRelays = userRelaySet.urls.toList();
    _isSameAsOriginal = true;

    // Connect to new relays
    nc.connectNonConnectedRelays(userRelaySet.urls.toSet());

    _emitIfNotClosed(
      state.copyWith(
        relays: userRelaySet.relays,
        isSameRelays: true,
        pendingRelays: {},
        toBeDeleted: {},
      ),
    );

    onSuccess.call();
    _showSuccessMessage();
  }

  /// Handle failed relay update
  void _handleUpdateFailure() {
    _emitIfNotClosed(state.copyWith(isSameRelays: true));
    _showErrorMessage(t.couldNotUpdateRelaysList.capitalizeFirst());
  }

  /// Handle update error
  void _handleUpdateError(Object error) {
    // Optional: Add error logging here
    _showErrorMessage(t.errorUpdatingRelaysList.capitalizeFirst());
  }

  /// Show success message
  void _showSuccessMessage() {
    BotToastUtils.showSuccess(
      t.relaysListUpdated.capitalizeFirst(),
    );
  }

  /// Show error message
  void _showErrorMessage(message) {
    BotToastUtils.showError(message);
  }

  /// Toggle relay deletion status
  void setToBeDeleted(String relay) {
    final currentToBeDeleted = Set<String>.from(state.toBeDeleted);

    if (currentToBeDeleted.contains(relay)) {
      currentToBeDeleted.remove(relay);
    } else {
      if (state.relays.length == (currentToBeDeleted.length + 1)) {
        BotToastUtils.showError(t.useOneRelay);
        return;
      }

      currentToBeDeleted.add(relay);
    }

    final isSameRelays = currentToBeDeleted.isEmpty && _isSameAsOriginal;

    _emitIfNotClosed(
      state.copyWith(
        toBeDeleted: currentToBeDeleted,
        isSameRelays: isSameRelays,
      ),
    );
  }

  /// Add or remove relay with improved validation and state management
  void setRelay(
    String addedRelay, {
    bool? textfield,
    Function()? onSuccess,
  }) {
    final processedRelay = _processRelayUrl(addedRelay, textfield);
    if (processedRelay == null) {
      return;
    }

    if (onSuccess == null) {
      if (_isRelayAlreadyActive(processedRelay)) {
        BotToastUtils.showError(t.relayInUse.capitalizeFirst());
        return;
      }
    } else {
      if (_isRelayActiveInCommon(processedRelay) &&
          _isRelayAlreadyActive(processedRelay)) {
        BotToastUtils.showError(t.relayInUse.capitalizeFirst());
        return;
      }
    }

    if (!_isValidRelayUrl(processedRelay)) {
      BotToastUtils.showError(t.invalidRelayUrl.capitalizeFirst());
      return;
    }

    if (state.relays.containsKey(processedRelay)) {
      _removeRelayFromState(processedRelay, onSuccess);
    } else {
      _addRelayToState(processedRelay, onSuccess);
    }
  }

  /// Process and clean relay URL
  String? _processRelayUrl(String addedRelay, bool? isFromTextField) {
    if (isFromTextField != null && isFromTextField) {
      return addedRelay.removeLastBackSlashes();
    }
    return addedRelay;
  }

  /// Check if relay is already active
  bool _isRelayActiveInCommon(String relay) {
    return state.onlineRelays.contains(relay);
  }

  /// Check if relay is already active
  bool _isRelayAlreadyActive(String relay) {
    return state.activeRelays.contains(relay);
  }

  /// Validate relay URL format
  bool _isValidRelayUrl(String relay) {
    return relay.contains(relayRegExp);
  }

  /// Remove relay from state
  void _removeRelayFromState(String relay, Function()? onSuccess) {
    final updatedRelays = Map<String, ReadWriteMarker>.from(state.relays)
      ..remove(relay);
    final updatedPending =
        Map<String, ReadWriteMarker>.from(state.pendingRelays)..remove(relay);

    final isSame = _checkIfRelaysAreSame(updatedRelays);

    _emitIfNotClosed(
      state.copyWith(
        relays: updatedRelays,
        pendingRelays: updatedPending,
        isSameRelays: isSame,
      ),
    );

    if (!isSame) {
      onSuccess?.call();
    }
  }

  /// Add relay to state
  void _addRelayToState(String relay, Function()? onSuccess) {
    final updatedRelays = {
      relay: ReadWriteMarker.readWrite,
      ...Map<String, ReadWriteMarker>.from(state.relays)
    };

    final updatedPending = {
      relay: ReadWriteMarker.readWrite,
      ...Map<String, ReadWriteMarker>.from(state.pendingRelays),
    };

    final isSame = _checkIfRelaysAreSame(updatedRelays, updatedPending);

    _emitIfNotClosed(
      state.copyWith(
        relays: updatedRelays,
        pendingRelays: updatedPending,
        isSameRelays: isSame,
      ),
    );

    if (!isSame) {
      onSuccess?.call();
    }
  }

  /// Check if current relays match original relays
  bool _checkIfRelaysAreSame(
    Map<String, ReadWriteMarker> relays, [
    Map<String, ReadWriteMarker>? pending,
  ]) {
    final currentRelaysSet = _currentRelays.toSet();
    final relayKeysSet = relays.keys.toSet();

    if (pending != null) {
      return relayKeysSet.containsAll(pending.keys.toSet()) &&
          pending.length == relays.length;
    }

    return relayKeysSet.containsAll(currentRelaysSet) &&
        _currentRelays.length == relays.length;
  }

  /// Update relay read/write marker
  void updateRelayMarker({
    required String relay,
    required ReadWriteMarker rwMarker,
  }) {
    final updatedRelays = Map<String, ReadWriteMarker>.from(state.relays);
    final updatedPending =
        Map<String, ReadWriteMarker>.from(state.pendingRelays);

    if (updatedRelays.containsKey(relay)) {
      updatedRelays[relay] = rwMarker;
    }

    if (updatedPending.containsKey(relay)) {
      updatedPending[relay] = rwMarker;
    }

    final isSame = _checkIfRelaysAreSame(updatedRelays, updatedPending);

    _emitIfNotClosed(
      state.copyWith(
        relays: updatedRelays,
        pendingRelays: updatedPending,
        isSameRelays: isSame,
      ),
    );
  }

  /// Fetch and set online relays with improved error handling
  Future<void> setOnlineRelays({bool isSearch = false}) async {
    _emitIfNotClosed(state.copyWith(onlineRelays: []));

    try {
      List<String> onlineRelays = [];

      if (isSearch) {
        onlineRelays = await nostrRepository.fetchRelays(
          nip: isSearch ? 50 : null,
        );
      } else {
        onlineRelays = await relayInfoCubit.getActiveGlobalRelays();
      }

      _emitIfNotClosed(state.copyWith(onlineRelays: onlineRelays));
    } catch (e) {
      // Log error if needed and set empty list as fallback
      _emitIfNotClosed(state.copyWith(onlineRelays: []));
    }
  }

  @override
  Future<void> close() {
    _statusTimer?.cancel();
    return super.close();
  }
}
