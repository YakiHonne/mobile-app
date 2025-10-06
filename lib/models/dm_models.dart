// ignore_for_file: public_member_api_docs, sort_constructors_first, prefer_foreach
import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../utils/utils.dart';
import 'event_mem_box.dart';

class DMSessionDetail extends Equatable {
  final DMSession dmSession;
  final DMSessionInfo info;
  final DmsType dmsType;

  const DMSessionDetail({
    required this.dmSession,
    required this.info,
    required this.dmsType,
  });

  bool hasNewMessage() {
    return dmSession.newestEvent != null &&
        dmSession.newestEvent!.pubkey == info.peerPubkey &&
        (info.readTime == 0 ||
            info.readTime < dmSession.newestEvent!.createdAt);
  }

  @override
  List<Object?> get props => [dmSession, info, dmsType];

  DMSessionDetail copyWith({
    DMSession? dmSession,
    DMSessionInfo? info,
    DmsType? dmsType,
  }) {
    return DMSessionDetail(
      dmSession: dmSession ?? this.dmSession,
      info: info ?? this.info,
      dmsType: dmsType ?? this.dmsType,
    );
  }

  DMSessionDetail clone() {
    return DMSessionDetail(dmSession: dmSession, info: info, dmsType: dmsType);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dmSession': dmSession.toString(),
      'info': info.toString(),
      'dmsType': dmsType,
    };
  }
}

class DMSession {
  final String pubkey;

  EventMemBox _box = EventMemBox();

  DMSession({required this.pubkey});

  DMSession clone() {
    return DMSession(pubkey: pubkey).._box = _box;
  }

  bool addEvent(Event event) {
    return _box.add(event, returnTrueOnNewSources: false);
  }

  void addEvents(List<Event> events) {
    _box.addList(events);
  }

  Event? get newestEvent {
    return _box.newestEvent;
  }

  int length() {
    return _box.length();
  }

  Event? get(int index) {
    if (_box.length() <= index) {
      return null;
    }

    return _box.getByIndex(index);
  }

  bool doesEventExist(String pubkey) {
    return _box.doesEventExist(pubkey);
  }

  List<Event> getAll() {
    return _box.all();
  }

  Event? getById(String id) {
    return _box.getById(id);
  }

  int lastTime() {
    return _box.newestEvent!.createdAt;
  }
}

// Simple configuration for event processing
class EventQueueConfig {
  final int batchSize;
  final Duration processingDelay;

  const EventQueueConfig({
    this.batchSize = 10,
    this.processingDelay = const Duration(milliseconds: 100),
  });
}

// Simple event queue mixin for DmsCubit
mixin SimpleEventQueue {
  final EventQueueConfig _config = const EventQueueConfig();
  final Queue<Event> _eventQueue = Queue<Event>();
  Timer? _processingTimer;
  bool _isProcessing = false;

  // Add event to queue (replaces direct onEvent calls)
  void queueEvent(Event event) {
    _eventQueue.add(event);
    _scheduleProcessing();
  }

  // Add multiple events to queue (for initial load)
  void queueEvents(List<Event> events) {
    _eventQueue.addAll(events);
    _scheduleProcessing();
  }

  void _scheduleProcessing() {
    // If already processing or timer is active, don't schedule again
    if (_isProcessing || (_processingTimer?.isActive ?? false)) {
      return;
    }

    _processingTimer = Timer(_config.processingDelay, () {
      _processBatch();
    });
  }

  void _processBatch() {
    if (_isProcessing || _eventQueue.isEmpty) {
      return;
    }

    _isProcessing = true;

    try {
      // Take up to batchSize events from queue
      final batch = <Event>[];
      final batchSize = _config.batchSize;

      for (int i = 0; i < batchSize && _eventQueue.isNotEmpty; i++) {
        batch.add(_eventQueue.removeFirst());
      }

      if (batch.isNotEmpty) {
        // Process this batch using existing logic
        _processEventBatch(batch);
      }
    } finally {
      _isProcessing = false;

      // If there are more events, schedule next batch
      if (_eventQueue.isNotEmpty) {
        _scheduleProcessing();
      }
    }
  }

  // Process a batch of events (uses your existing eventLaterHandle logic)
  void _processEventBatch(List<Event> events) {
    // Call your existing batch processing logic
    eventLaterHandle(events);
  }

  // Get queue status for monitoring
  int get queueLength => _eventQueue.length;
  bool get isProcessing => _isProcessing;
  bool get hasQueuedEvents => _eventQueue.isNotEmpty;

  // Clear the queue (for cleanup)
  void clearEventQueue() {
    _processingTimer?.cancel();
    _processingTimer = null;
    _eventQueue.clear();
    _isProcessing = false;
  }

  // Abstract method that implementing class must provide
  void eventLaterHandle(List<Event> events, {bool updateUI = true});
}
