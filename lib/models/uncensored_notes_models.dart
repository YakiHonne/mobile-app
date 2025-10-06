// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../utils/utils.dart';
import 'flash_news_model.dart';

const UN_SEARCH_VALUE = 'UNCENSORED NOTE';
const NR_SEARCH_VALUE = 'UNCENSORED NOTE RATING';

List<UncensoredNote> uncensoredNotesFromJson({
  required List notes,
  required flashNewsId,
}) =>
    notes.map((e) => UncensoredNote.fromMap(e, flashNewsId)).toList();

class UncensoredNote {
  final String id;
  final String flashNewsId;
  final String pubKey;
  final String content;
  final String source;
  final DateTime createdAt;
  final bool isAuthentic;
  final bool leading;
  final List<NotesRating> ratings;
  final bool isUnSealed;

  UncensoredNote({
    required this.id,
    required this.flashNewsId,
    required this.pubKey,
    required this.content,
    required this.source,
    required this.createdAt,
    required this.isAuthentic,
    required this.leading,
    required this.ratings,
    required this.isUnSealed,
  });

  factory UncensoredNote.fromEvent(Event event) {
    try {
      String source = '';
      final createdAt =
          DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
      String encryption = '';
      String flashNewsId = '';

      bool leading = false;

      for (final tag in event.tags) {
        if (tag.first == FN_SOURCE && tag.length > 1) {
          source = tag[1];
        } else if (tag.first == FN_ENCRYPTION && tag.length > 1) {
          encryption = tag[1];
        } else if (tag.first == 'e' && tag.length > 1) {
          flashNewsId = tag[1];
        } else if (tag.first == 'type' && tag.length > 1) {
          leading = tag[1] == '+';
        }
      }

      return UncensoredNote(
        id: event.id,
        flashNewsId: flashNewsId,
        pubKey: event.pubkey,
        content: event.content,
        source: source,
        leading: leading,
        createdAt: createdAt,
        isUnSealed: false,
        isAuthentic: checkAuthenticity(encryption, createdAt),
        ratings: [],
      );
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print('Exception: $e');
      }
      if (kDebugMode) {
        print('Stacktrace: $stacktrace');
      }
      rethrow;
    }
  }

  factory UncensoredNote.fromMap(
    Map<String, dynamic> map,
    String flashNewsId,
  ) {
    try {
      final createdAt =
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] * 1000);

      String encryption = '';
      final String uncensoredNoteId = map['id'];
      final bool isUnSealed = map['is_un_sealed'] ?? false;
      String source = '';
      String fnId = flashNewsId;
      final Set<String> reasons = {};
      bool leading = false;
      final tags = map['tags'];

      for (final tag in tags) {
        if (tag.first == FN_ENCRYPTION && tag.length > 1) {
          encryption = tag[1];
        } else if (tag.first == 'cause' && tag.length > 1) {
          reasons.add(tag[1]);
        } else if (tag.first == 'source' && tag.length > 1) {
          source = tag[1];
        } else if (tag.first == 'type' && tag.length > 1) {
          leading = tag[1] == '+';
        } else if (tag.first == 'e' && tag.length > 1 && fnId.isEmpty) {
          fnId = tag[1];
        }
      }

      return UncensoredNote(
        id: uncensoredNoteId,
        leading: leading,
        isUnSealed: isUnSealed,
        flashNewsId: fnId,
        pubKey: map['pubkey'],
        ratings: map['ratings'] != null
            ? notesRatingFromJson(map['ratings'], uncensoredNoteId)
            : [],
        content: map['content'],
        source: source,
        createdAt: createdAt,
        isAuthentic: checkAuthenticity(encryption, createdAt),
      );
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print('Exception: $e');
      }
      if (kDebugMode) {
        print('Stacktrace: $stacktrace');
      }
      rethrow;
    }
  }
}

List<NotesRating> notesRatingFromJson(
  List ratings,
  String uncensoredNoteId,
) =>
    ratings.map((e) => NotesRating.fromMap(e, uncensoredNoteId)).toList();

class NotesRating {
  final String id;
  final String uncensoredNoteId;
  final String pubKey;
  final bool ratingValue;
  final DateTime createdAt;
  final bool isAuthentic;
  final List<String> reasons;

  NotesRating({
    required this.id,
    required this.uncensoredNoteId,
    required this.pubKey,
    required this.ratingValue,
    required this.createdAt,
    required this.isAuthentic,
    required this.reasons,
  });

  factory NotesRating.fromEvent(Event event) {
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
    String encryption = '';
    String uncensoredNoteId = '';
    final Set<String> reasons = {};

    for (final tag in event.tags) {
      if (tag.first == FN_ENCRYPTION && tag.length > 1) {
        encryption = tag[1];
      } else if (tag.first == 'e' && tag.length > 1) {
        uncensoredNoteId = tag[1];
      } else if (tag.first == 'cause' && tag.length > 1) {
        reasons.add(tag[1]);
      }
    }

    return NotesRating(
      id: event.id,
      uncensoredNoteId: uncensoredNoteId,
      pubKey: event.pubkey,
      createdAt: createdAt,
      reasons: reasons.toList(),
      ratingValue: event.content == '+',
      isAuthentic: checkAuthenticity(encryption, createdAt),
    );
  }

  factory NotesRating.fromMap(Map<String, dynamic> map, String noteId) {
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch((map['created_at'] as int) * 1000);
    String encryption = '';
    final Set<String> reasons = {};
    final ratingValue = map['content'] == '+';

    for (final tag in map['tags']) {
      if (tag.first == FN_ENCRYPTION && tag.length > 1) {
        encryption = tag[1];
      } else if (tag.first == 'cause' && tag.length > 1) {
        reasons.add(tag[1]);
      }
    }

    return NotesRating(
      id: map['id'] as String,
      uncensoredNoteId: noteId,
      pubKey: map['pubkey'] as String,
      ratingValue: ratingValue,
      createdAt: createdAt,
      isAuthentic: checkAuthenticity(encryption, createdAt),
      reasons: reasons.toList(),
    );
  }

  NotesRating copyWith({
    String? id,
    String? uncensoredNoteId,
    String? pubKey,
    bool? ratingValue,
    DateTime? createdAt,
    bool? isAuthentic,
    List<String>? reasons,
  }) {
    return NotesRating(
      id: id ?? this.id,
      uncensoredNoteId: uncensoredNoteId ?? this.uncensoredNoteId,
      pubKey: pubKey ?? this.pubKey,
      ratingValue: ratingValue ?? this.ratingValue,
      createdAt: createdAt ?? this.createdAt,
      isAuthentic: isAuthentic ?? this.isAuthentic,
      reasons: reasons ?? this.reasons,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uncensoredNoteId': uncensoredNoteId,
      'pubKey': pubKey,
      'ratingValue': ratingValue,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isAuthentic': isAuthentic,
      'reasons': reasons,
    };
  }
}

List<UnFlashNews> newFNListFromJson(List fns) =>
    fns.map((e) => UnFlashNews.fromMap(e)).toList();

class UnFlashNews {
  final FlashNews flashNews;
  final List<UncensoredNote> uncensoredNotes;
  final bool isSealed;
  SealedNote? sealedNote;

  UnFlashNews({
    required this.flashNews,
    required this.uncensoredNotes,
    required this.isSealed,
    this.sealedNote,
  });

  factory UnFlashNews.fromMap(Map<String, dynamic> event) {
    try {
      bool isSealed = false;
      SealedNote? sealedNote;
      final List<UncensoredNote> uncensoredNotes = [];

      final flashNews = FlashNews.fromMap(
        event['flashnews'] as Map<String, dynamic>,
      );

      final sealed = event['sealed_note'] as Map<String, dynamic>?;

      if (sealed != null && sealed.isNotEmpty) {
        final createdSealedNote = SealedNote.fromMap(sealed);
        if (createdSealedNote.isAuthentic) {
          sealedNote = createdSealedNote;
          isSealed = true;
        }
      }

      final authorPubkey = event['author']?['pubkey'] as String? ?? '';

      if (authorPubkey.isNotEmpty) {
        metadataCubit.requestMetadata(flashNews.pubkey);
      }

      final nmhNotes = event['nmh_notes'] as List?;

      if (nmhNotes != null && nmhNotes.isNotEmpty) {
        for (final item in nmhNotes) {
          uncensoredNotes.add(UncensoredNote.fromMap(item, flashNews.id));
        }
      }

      return UnFlashNews(
        flashNews: flashNews.copyWith(
          pubKey: authorPubkey.isNotEmpty ? authorPubkey : null,
        ),
        isSealed: isSealed,
        sealedNote: sealedNote,
        uncensoredNotes: uncensoredNotes,
      );
    } catch (e, stackTrace) {
      lg.i(stackTrace);
      rethrow;
    }
  }

  factory UnFlashNews.fromMap2(Map<String, dynamic> event) {
    try {
      bool isSealed = false;
      SealedNote? sealedNote;
      final List<UncensoredNote> uncensoredNotes = [];

      final flashNews = FlashNews.fromMap(event);

      final sealed = event['sealed_note'] as Map<String, dynamic>?;

      if (sealed != null && sealed.isNotEmpty) {
        final createdSealedNote = SealedNote.fromMap(sealed);
        if (createdSealedNote.isAuthentic) {
          sealedNote = createdSealedNote;
          isSealed = true;
        }
      }

      final authorPubkey = event['author']?['pubkey'] as String? ?? '';

      if (authorPubkey.isNotEmpty) {
        metadataCubit.requestMetadata(flashNews.pubkey);
      }

      final nmhNotes = event['nmh_notes'] as List?;

      if (nmhNotes != null && nmhNotes.isNotEmpty) {
        for (final item in nmhNotes) {
          uncensoredNotes.add(UncensoredNote.fromMap(item, flashNews.id));
        }
      }

      return UnFlashNews(
        flashNews: flashNews.copyWith(
          pubKey: authorPubkey.isNotEmpty ? authorPubkey : null,
        ),
        isSealed: isSealed,
        sealedNote: sealedNote,
        uncensoredNotes: uncensoredNotes,
      );
    } catch (e, stackTrace) {
      lg.i(stackTrace);
      rethrow;
    }
  }

  factory UnFlashNews.fromJson(String source) =>
      UnFlashNews.fromMap(json.decode(source) as Map<String, dynamic>);
}

class SealedNote {
  final DateTime createdAt;
  final UncensoredNote uncensoredNote;
  final String flashNewsId;
  final String noteAuthor;
  final List<String> raters;
  final bool isAuthentic;
  final bool isHelpful;
  final String id;
  final List<String> reasons;

  SealedNote({
    required this.createdAt,
    required this.uncensoredNote,
    required this.flashNewsId,
    required this.noteAuthor,
    required this.raters,
    required this.reasons,
    required this.isAuthentic,
    required this.isHelpful,
    required this.id,
  });

  factory SealedNote.fromMap(Map<String, dynamic> map) {
    try {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as int) * 1000);

      final id = map['id'] as String;

      String flashNewsId = '';
      String noteAuthor = '';
      String encryption = '';
      final List<String> raters = [];
      final List<String> reasons = [];
      bool isHelpful = false;
      for (final tag in map['tags']) {
        if (tag.first == FN_ENCRYPTION && tag.length > 1) {
          encryption = tag[1];
        } else if (tag.first == 'p' && tag.length > 1) {
          raters.add(tag[1]);
        } else if (tag.first == 'original' && tag.length > 1) {
          flashNewsId = tag[1];
        } else if (tag.first == 'author' && tag.length > 1) {
          noteAuthor = tag[1];
        } else if (tag.first == 'rating' && tag.length > 1) {
          isHelpful = tag[1] == '+';
        } else if (tag.first == 'cause' && tag.length > 1) {
          reasons.add(tag[1]);
        }
      }

      final note = UncensoredNote.fromMap(
        jsonDecode(map['content'] as String),
        flashNewsId,
      );

      return SealedNote(
        id: id,
        reasons: reasons,
        isHelpful: isHelpful,
        uncensoredNote: note,
        flashNewsId: flashNewsId,
        noteAuthor: noteAuthor,
        raters: raters,
        createdAt: createdAt,
        isAuthentic: checkAuthenticity(encryption, createdAt),
      );
    } catch (e, stacktrace) {
      lg.i(stacktrace);
      rethrow;
    }
  }
}

List<RewardModel> rewardFromJson(List rewards) => rewards.map((reward) {
      if (reward['kind'] == 1) {
        return UncensoredNoteReward.fromJson(reward);
      } else if (reward['kind'] == 7) {
        return RatingReward.fromJson(reward);
      } else {
        return SealedReward.fromJson(reward);
      }
    }).toList();

abstract class RewardModel {
  final RewardStatus status;
  RewardModel({
    required this.status,
  });
}

class RatingReward extends RewardModel {
  final UncensoredNote note;
  final NotesRating rating;

  RatingReward({
    required this.note,
    required this.rating,
    required super.status,
  });

  factory RatingReward.fromJson(Map<String, dynamic> map) {
    final uncensoredNote = UncensoredNote.fromMap(map['uncensored_note'], '');
    final ratingNote = NotesRating.fromMap(map, uncensoredNote.id);
    final status = map['status'] == 'not found'
        ? RewardStatus.not_claimed
        : map['status'] == 'in progress'
            ? RewardStatus.in_progress
            : RewardStatus.claimed;

    return RatingReward(
        note: uncensoredNote, status: status, rating: ratingNote);
  }
}

class UncensoredNoteReward extends RewardModel {
  final UncensoredNote note;

  UncensoredNoteReward({
    required this.note,
    required super.status,
  });

  factory UncensoredNoteReward.fromJson(Map<String, dynamic> map) {
    final uncensoredNote = UncensoredNote.fromMap(map, '');
    final status = map['status'] == 'not found'
        ? RewardStatus.not_claimed
        : map['status'] == 'in progress'
            ? RewardStatus.in_progress
            : RewardStatus.claimed;

    return UncensoredNoteReward(
      note: uncensoredNote,
      status: status,
    );
  }
}

class SealedReward extends RewardModel {
  final SealedNote note;
  final bool isAuthor;
  final bool isRater;

  SealedReward({
    required this.note,
    required this.isAuthor,
    required this.isRater,
    required super.status,
  });

  factory SealedReward.fromJson(Map<String, dynamic> map) {
    final sealedNote = SealedNote.fromMap(map);
    final status = map['status'] == 'not found'
        ? RewardStatus.not_claimed
        : map['status'] == 'in progress'
            ? RewardStatus.in_progress
            : RewardStatus.claimed;
    final isAuthor = map['is_author'];
    final isRater = map['is_rater'];

    return SealedReward(
      isAuthor: isAuthor,
      isRater: isRater,
      note: sealedNote,
      status: status,
    );
  }
}
