// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../utils/utils.dart';
import '../flash_news_model.dart';
import '../uncensored_notes_models.dart';

class ExtendedEvent extends Event {
  ExtendedEvent({
    required super.id,
    required super.content,
    required super.createdAt,
    required super.kind,
    required super.pubkey,
    required super.sig,
    required super.tags,
    super.currentUser,
    super.lastUpdated,
    super.seenOn,
    super.subscriptionId,
  });

  factory ExtendedEvent.fromEv(Event ev) {
    return ExtendedEvent(
      id: ev.id,
      pubkey: ev.pubkey,
      createdAt: ev.createdAt,
      kind: ev.kind,
      tags: ev.tags,
      content: ev.content,
      sig: ev.sig,
    );
  }

  @override
  DateTime getPublishedAt() {
    DateTime publishedAt =
        DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);

    for (final tag in tags) {
      if (tag.first == 'published_at' && tag.length >= 2) {
        publishedAt = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(tag[1]) ?? createdAt * 1000,
        );
      }
    }

    return publishedAt;
  }

  @override
  String? getEventParent() {
    String? selectedTag;

    for (final tag in tags) {
      if (isQuote()) {
        if (tag.first == 'q' && tag.length > 1) {
          selectedTag = tag[1];
        }
      } else {
        if (tag.first == 'e' && tag.length > 1) {
          selectedTag = tag[1];
        }
      }
    }

    return selectedTag;
  }

  @override
  bool isQuote() {
    if (kind == EventKind.TEXT_NOTE) {
      for (final tag in tags) {
        if (tag.first == 'q' && tag.length >= 2) {
          return true;
        }
      }

      return false;
    } else {
      return false;
    }
  }

  bool isUserTagged() {
    bool isTagged = false;

    for (final tag in tags) {
      if (tag.first == 'p' &&
          tag.length >= 2 &&
          tag[1] == currentSigner?.getPublicKey()) {
        isTagged = true;
      }
    }

    return isTagged;
  }

  bool isFlashNews() {
    final createdAtDate = DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
    );

    String encryption = '';
    bool isFlashNews = false;

    for (final tag in tags) {
      final tagLength = tag.length;

      if (tagLength >= 2 &&
          tag[0] == FN_SEARCH_KEY &&
          tag[1] == FN_SEARCH_VALUE) {
        isFlashNews = true;
      }

      if (tag.first == FN_ENCRYPTION && tag.length > 1) {
        encryption = tag[1];
      }
    }

    if (!isFlashNews || encryption.isEmpty) {
      return false;
    }

    return checkAuthenticity(encryption, createdAtDate);
  }

  @override
  bool isUncensoredNote() {
    final createdAtDate = DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
    );

    String encryption = '';
    bool isUncensoredNote = false;

    for (final tag in tags) {
      final tagLength = tag.length;

      if (tagLength >= 2 &&
          tag[0] == FN_SEARCH_KEY &&
          tag[1] == UN_SEARCH_VALUE) {
        isUncensoredNote = true;
      }

      if (tag.first == FN_ENCRYPTION && tag.length > 1) {
        encryption = tag[1];
      }
    }

    if (!isUncensoredNote || encryption.isEmpty) {
      return false;
    }

    return checkAuthenticity(encryption, createdAtDate);
  }

  bool isSealedNote() {
    bool isSealed = false;

    for (final tag in tags) {
      final tagLength = tag.length;

      if (tagLength >= 2 &&
          tag[0] == FN_SEARCH_KEY &&
          tag[1] == 'SEALED UNCENSORED NOTE') {
        isSealed = true;
      }
    }

    return pubkey == yakihonneHex && isSealed;
  }

  bool isSimpleNote() {
    return !isUncensoredNote() && !isSealedNote() && !isFlashNews();
  }

  bool isReply({String? noteId}) {
    bool hasETag = false;

    for (final tag in tags) {
      if ((tag.first == 'e' && tag.length > 1) ||
          (tag.first == 'a' && tag.length > 1)) {
        hasETag = true;
      }
    }

    return isSimpleNote() && hasETag;
  }

  @override
  bool isUnRate() {
    bool hasEncryption = false;

    for (final tag in tags) {
      if (tag.first == FN_ENCRYPTION && tag.length > 1) {
        hasEncryption = true;
      }
    }

    return hasEncryption && kind == EventKind.REACTION;
  }

  bool isTopicEvent() {
    bool isTopicTag = false;

    for (final tag in tags) {
      if (tag.first == 'd' && tag.length > 1 && tag[1] == yakihonneTopicTag) {
        isTopicTag = true;
      }
    }

    return isTopicTag && kind == EventKind.APP_CUSTOM;
  }

  bool isFollowingYakihonne() {
    if (kind == EventKind.CONTACT_LIST) {
      bool isFollowingYakihonne = false;

      for (final tag in tags) {
        if (tag.first == 'p' && tag.length > 1 && tag[1] == yakihonneHex) {
          isFollowingYakihonne = true;
        }
      }

      return isFollowingYakihonne;
    } else {
      return false;
    }
  }

  bool isVideo() =>
      kind == EventKind.VIDEO_HORIZONTAL || kind == EventKind.VIDEO_VERTICAL;

  bool isCuration() =>
      kind == EventKind.CURATION_ARTICLES || kind == EventKind.CURATION_VIDEOS;

  bool isLongForm() => kind == EventKind.LONG_FORM;

  bool isLongFormDraft() => kind == EventKind.LONG_FORM_DRAFT;

  bool isRelaysList() => kind == EventKind.RELAY_LIST_METADATA;
}

class ExtendedMetadata extends Metadata {
  const ExtendedMetadata({
    required super.pubkey,
    required super.name,
    required super.displayName,
    required super.picture,
    required super.banner,
    required super.website,
    required super.about,
    required super.nip05,
    required super.lud16,
    required super.lud06,
    required super.createdAt,
    required super.isDeleted,
  });

  static bool canBeZapped(Metadata metadata) {
    String? lnurl = metadata.lud06;

    if (StringUtil.isBlank(lnurl) || !lnurl.toLowerCase().startsWith('lnurl')) {
      if (StringUtil.isNotBlank(metadata.lud16)) {
        lnurl = Zap.getLnurlFromLud16(metadata.lud16);
      } else {
        lnurl = '';
      }
    }

    if (StringUtil.isBlank(lnurl)) {
      return false;
    } else {
      return true;
    }
  }
}
