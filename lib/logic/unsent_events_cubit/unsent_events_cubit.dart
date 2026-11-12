import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'unsent_events_state.dart';

class UnsentEventsCubit extends Cubit<UnsentEventsState> {
  UnsentEventsCubit({
    Future<bool> Function(Event event, List<String>? relays)? sendEvent,
  })  : _sendEvent = sendEvent ?? _sendPendingEvent,
        super(const UnsentEventsState());

  final Future<bool> Function(Event event, List<String>? relays) _sendEvent;

  static Future<bool> _sendPendingEvent(Event event, List<String>? relays) =>
      NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: false,
        relays: relays,
        relyOnUnsentEvents: false,
      );

  StreamSubscription<bool>? connectivityStream;
  bool isProcessing = false;
  bool hasConnection = connectivityService
      .isConnected; // Fixed typo: hasConnectiom -> hasConnection
  Timer? _processingTimer;

  Future<void> init() async {
    await loadUnsentEvents();
    subscribeToConnectivityStream();
    hasConnection = connectivityService.isConnected;
    processUnsentEvents();
  }

  void subscribeToConnectivityStream() {
    connectivityStream = connectivityService.onConnectivityChanged.listen(
      (bool hasConnection) {
        this.hasConnection = hasConnection;

        if (hasConnection) {
          // Process existing unsent events when connection is restored
          processUnsentEvents(checkRelays: true);
        }
      },
    );
  }

  Future<void> loadUnsentEvents() async {
    final ids = (await localDatabaseRepository.getUnsentEvents()).toSet();
    final pubkeys = await localDatabaseRepository.getUnsentEventsPubkeys();

    final events = await nc.db.loadEvents(
      f: Filter(
        ids: ids.toList(),
      ),
    );

    _emitNewState(
      events: {for (final e in events) e.id: e},
      pubkeys: pubkeys,
    );
  }

  Future<void> processUnsentEvents({bool checkRelays = false}) async {
    if (checkRelays) {
      await nc.forceReconnect();
    }
    if (isProcessing || !hasConnection || state.events.isEmpty) {
      return;
    }
    isProcessing = true;
    try {
      final eventsSnapshot = List.of(state.events.values);
      for (final event in eventsSnapshot) {
        if (!hasConnection) {
          break;
        }
        List<String> relays = [];
        final pubkey = state.pubkeys[event.id];
        if (pubkey != null) {
          final configured = await broadcastRelays(pubkey, showMessage: false);
          relays = configured.isNotEmpty ? configured : event.seenOn;
        }
        try {
          if (await _sendEvent(event, relays.isEmpty ? null : relays)) {
            removeUnsentEvent(event.id);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to send event ${event.id}: $e');
          }
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing unsent events: $e');
      }
    } finally {
      isProcessing = false;
    }
  }

  void addUnsentEvent(Event event, {String? pubkey}) {
    final events = Map<String, Event>.from(state.events);
    events[event.id] = event;
    final pubkeys = Map<String, String>.from(state.pubkeys);
    if (pubkey != null) {
      pubkeys[event.id] = pubkey;
    }

    _emitNewState(
      events: events,
      pubkeys: pubkeys,
    );
    updateUnsentEvents();

    // Trigger processing immediately if we have connection
    if (hasConnection && !isProcessing) {
      // Use a small delay to batch multiple rapid additions
      _processingTimer?.cancel();
      _processingTimer = Timer(const Duration(milliseconds: 100), () {
        processUnsentEvents();
      });
    }
  }

  void removeUnsentEvent(String eventId) {
    final events = Map<String, Event>.from(state.events);
    events.remove(eventId);

    _emitNewState(events: events);
    updateUnsentEvents();
  }

  void clearUnsentEvents() {
    _emitNewState(events: {});
    updateUnsentEvents();
  }

  // Manual retry method for UI triggers
  Future<void> retryProcessing() async {
    if (hasConnection) {
      await processUnsentEvents();
    }
  }

  // Get count of unsent events for UI display
  int get unsentEventsCount => state.events.length;

  // Check if there are any unsent events
  bool get hasUnsentEvents => state.events.isNotEmpty;

  void _emitNewState({
    Map<String, Event>? events,
    Map<String, String>? pubkeys,
  }) {
    if (!isClosed) {
      emit(state.copyWith(
        events: events,
        pubkeys: pubkeys,
      ));
    }
  }

  void updateUnsentEvents() {
    localDatabaseRepository.setUnsentEvents(state.events.keys.toList());
    localDatabaseRepository.setUnsentEventsPubkeys(state.pubkeys);
  }

  @override
  Future<void> close() async {
    await connectivityStream?.cancel();
    _processingTimer?.cancel();
    return super.close();
  }
}
