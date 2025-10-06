// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../common/common_regex.dart';
import 'app_models/extended_model.dart';
import 'flash_news_model.dart';

class EventRelation {
  late String id;

  late String pubkey;

  late int kind;

  late Event origin;

  List<String> tagPList = [];

  List<String> tagEList = [];
  List<String> tagAList = [];

  String? rootId;

  String? rRootId;

  String? rootRelayAddr;

  String? replyId;

  String? replyRelayAddr;

  String? subject;

  bool warning = false;

  bool isMention(String pubkey) {
    try {
      final content = origin.content;

      if (content.contains(Nip19.encodePubkey(pubkey))) {
        return true;
      }

      final nProfiles = userRegex.allMatches(content);

      if (nProfiles.isNotEmpty) {
        for (final match in nProfiles) {
          final content =
              Nip19.decodeShareableEntity(match.group(0)!.split(':').last);

          if ((content['special'] ?? content['author']) == pubkey) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  bool isFlashNews() {
    for (final tag in origin.tags) {
      final tagLength = tag.length;

      if (tagLength >= 2 &&
          tag[0] == FN_SEARCH_KEY &&
          tag[1] == FN_SEARCH_VALUE) {
        return true;
      }
    }

    return false;
  }

  bool isUncensoredNote() {
    final ev = ExtendedEvent.fromEv(origin);
    return ev.isUncensoredNote();
  }

  EventRelation.fromEvent(Event event) {
    id = event.id;
    pubkey = event.pubkey;
    kind = event.kind;
    origin = event;

    final Map<String, int> pMap = {};
    final length = event.tags.length;
    for (var i = 0; i < length; i++) {
      final tag = event.tags[i];

      final mentionStr = '#[$i]';

      if (event.content.contains(mentionStr)) {
        continue;
      }

      final tagLength = tag.length;
      if (tagLength > 1) {
        final tagKey = tag[0];
        final value = tag[1];
        if (tagKey == 'p') {
          var nip19Str = 'nostr:${Nip19.encodePubkey(value)}';
          if (event.content.contains(nip19Str)) {
            continue;
          }

          nip19Str = Nip19.encodeShareableEntity(
            'nprofile',
            event.pubkey,
            [],
            null,
            null,
          );

          if (event.content.contains(nip19Str)) {
            continue;
          }

          pMap[value] = 1;
        } else if (tagKey == 'e') {
          tagEList.add(value);

          if (tagLength > 3) {
            final marker = tag[3];
            if (marker == 'reply') {
              replyId = value;
              replyRelayAddr = tag[2];
            } else if (marker == 'root') {
              rootId = value;
              rootRelayAddr = tag[2];
            }
          } else {
            rootId = tag[1];
          }
        } else if (tagKey == 'a') {
          if (tagLength >= 2) {
            rRootId = value.split(':').last;
            tagAList.add(rRootId!);
          }
        } else if (tagKey == 'subject') {
          subject = value;
        } else if (tagKey == 'content-warning') {
          warning = true;
        }
      }
    }

    final tagELength = tagEList.length;
    if (tagELength == 1 && rootId == null) {
      if (rRootId == null) {
        rootId = tagEList[0];
      }
    } else if (tagELength > 1) {
      if (rootId == null && replyId == null) {
        if (rRootId == null) {
          rootId = tagEList.first;
        }
        replyId = tagEList.last;
      } else if (rootId != null && replyId == null) {
        for (var i = tagELength - 1; i > -1; i--) {
          final id = tagEList[i];
          if (id != rootId) {
            replyId = id;
          }
        }
      } else if (rootId == null && replyId != null) {
        for (var i = 0; i < tagELength; i++) {
          final id = tagEList[i];
          if (id != replyId) {
            if (rRootId == null) {
              rootId = id;
            }
          }
        }
      } else {
        if (rRootId == null) {
          rootId ??= tagEList.first;
        }
        replyId ??= tagEList.last;
      }
    }

    if (rootId != null && replyId == rootId && rootRelayAddr == null) {
      rootRelayAddr = replyRelayAddr;
    }

    pMap.remove(event.pubkey);
    tagPList.addAll(pMap.keys);
  }

  MapEntry? getReactionId() {
    MapEntry? id;

    if (tagAList.isNotEmpty) {
      id = MapEntry(tagAList.last, true);
    } else if (tagEList.isNotEmpty) {
      id = MapEntry(tagEList.last, false);
    }

    return id;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'pubkey': pubkey,
      'kind': kind,
      'origin': origin,
      'tagPList': tagPList,
      'tagEList': tagEList,
      'rootId': rootId,
      'rRootId': rRootId,
      'rootRelayAddr': rootRelayAddr,
      'replyId': replyId,
      'replyRelayAddr': replyRelayAddr,
      'subject': subject,
      'warning': warning,
    };
  }
}
