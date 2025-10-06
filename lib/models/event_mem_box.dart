import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

/// a memory event box
/// use to hold event received from relay and offer event List to ui
class EventMemBox extends Equatable {
  EventMemBox({this.sortAfterAdd = true});
  final List<Event> _eventList = [];

  final Map<String, Event> _idMap = {};

  final bool sortAfterAdd;

  List<Event> findEvent(String str, {int? limit = 5}) {
    final List<Event> list = [];
    for (final event in _eventList) {
      if (event.content.contains(str)) {
        list.add(event);

        if (limit != null && list.length >= limit) {
          break;
        }
      }
    }
    return list;
  }

  Event? get newestEvent {
    if (_eventList.isEmpty) {
      return null;
    }
    return _eventList.first;
  }

  Event? get oldestEvent {
    if (_eventList.isEmpty) {
      return null;
    }
    return _eventList.last;
  }

  void sort() {
    _eventList.sort((event1, event2) {
      return event2.createdAt - event1.createdAt;
    });
  }

  bool delete(String id) {
    if (_idMap[id] == null) {
      return false;
    }

    _idMap.remove(id);
    _eventList.removeWhere((element) => element.id == id);

    return true;
  }

  bool add(Event event, {bool returnTrueOnNewSources = true}) {
    final oldEvent = _idMap[event.id];

    if (oldEvent != null) {
      if (event.createdAt.compareTo(oldEvent.createdAt) > 0) {
        _idMap[event.id] = event;

        if (returnTrueOnNewSources) {
          return true;
        }
      }

      return false;
    }

    _idMap[event.id] = event;
    _eventList.add(event);
    if (sortAfterAdd) {
      sort();
    }

    return true;
  }

  bool addList(List<Event> list) {
    bool added = false;
    for (final event in list) {
      final oldEvent = _idMap[event.id];
      if (oldEvent == null) {
        _idMap[event.id] = event;
        _eventList.add(event);
        added = true;
      } else {
        if (event.createdAt.compareTo(oldEvent.createdAt) > 0) {
          _idMap[event.id] = event;
        }
      }
    }

    if (added && sortAfterAdd) {
      sort();
    }

    return added;
  }

  bool doesEventExist(String pubkey) {
    final events =
        _eventList.where((element) => element.pubkey == pubkey).toList();

    return events.isNotEmpty;
  }

  void addBox(EventMemBox b) {
    final all = b.all();
    addList(all);
  }

  bool isEmpty() {
    return _eventList.isEmpty;
  }

  int length() {
    return _eventList.length;
  }

  List<Event> all() {
    return _eventList;
  }

  bool containsId(String id) {
    return _idMap.containsKey(id);
  }

  List<Event> listByPubkey(String pubkey) {
    final List<Event> list = [];
    for (final event in _eventList) {
      if (event.pubkey == pubkey) {
        list.add(event);
      }
    }
    return list;
  }

  List<Event> suList(int start, int limit) {
    final length = _eventList.length;
    if (start > length) {
      return [];
    }
    if (start + limit > length) {
      return _eventList.sublist(start, length);
    }
    return _eventList.sublist(start, limit);
  }

  int getIndexById(String id) {
    return _eventList.indexWhere((element) => element.id == id);
  }

  Event? getByIndex(int index) {
    if (_eventList.length < index) {
      return null;
    }

    return _eventList[index];
  }

  Event? getById(String id) {
    return _idMap[id];
  }

  List<Event> getAll() {
    return _eventList;
  }

  void clear() {
    _eventList.clear();
    _idMap.clear();
  }

  @override
  List<Object?> get props => [_eventList, _idMap, sortAfterAdd];
}

class OldestCreatedAtByRelayResult {
  Map<String, int> createdAtMap = {};

  int avCreatedAt = 0;
}
