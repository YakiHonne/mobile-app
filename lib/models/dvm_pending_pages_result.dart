import 'dart:convert';

import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../globals.dart';
import 'detailed_note_model.dart';

class DvmPendingPagesResult {
  DvmPendingPagesResult({
    required this.v,
    required this.rev,
    required this.page,
    required this.pending,
  });

  factory DvmPendingPagesResult.fromJson(String str) =>
      DvmPendingPagesResult.fromMap(json.decode(str));

  factory DvmPendingPagesResult.fromMap(Map<String, dynamic> json) =>
      DvmPendingPagesResult(
        v: json['v'] as int? ?? 1,
        rev: json['rev'] as int? ?? 0,
        page: json['page'] as int? ?? 0,
        pending: json['pending'] != null
            ? List<DvmPendingItem>.from(json['pending']
                .map((x) => DvmPendingItem.fromMap(x as Map<String, dynamic>)))
            : [],
      );

  final int v;
  final int rev;
  final int page;
  final List<DvmPendingItem> pending;

  Map<String, dynamic> toMap() => {
        'v': v,
        'rev': rev,
        'page': page,
        'pending': List<dynamic>.from(pending.map((x) => x.toMap())),
      };
}

class DvmPendingItem {
  DvmPendingItem({
    required this.jobType,
    required this.jobId,
    required this.status,
    required this.scheduledAt,
    required this.updatedAt,
    required this.noteId,
    required this.notePreview,
    this.noteBlob,
    required this.relays,
  });

  factory DvmPendingItem.fromMap(Map<String, dynamic> json) => DvmPendingItem(
        jobType: json['jobType'] as String? ?? 'note',
        jobId: json['jobId'] as String? ?? '',
        status: json['status'] as String? ?? '',
        scheduledAt: json['scheduledAt'] as int? ?? 0,
        updatedAt: json['updatedAt'] as int? ?? 0,
        noteId: json['noteId'] as String? ?? '',
        notePreview: DvmNotePreview.fromMap(json['notePreview'] ?? {}),
        noteBlob: json['noteBlob'],
        relays: json['relays'] != null
            ? List<String>.from(json['relays'].map((x) => x))
            : [],
      );

  final String jobType;
  final String jobId;
  final String status;
  final int scheduledAt;
  final int updatedAt;
  final String noteId;
  final DvmNotePreview notePreview;
  final dynamic noteBlob;
  final List<String> relays;

  Map<String, dynamic> toMap() => {
        'jobType': jobType,
        'jobId': jobId,
        'status': status,
        'scheduledAt': scheduledAt,
        'updatedAt': updatedAt,
        'noteId': noteId,
        'notePreview': notePreview.toMap(),
        'noteBlob': noteBlob,
        'relays': List<dynamic>.from(relays.map((x) => x)),
      };

  DetailedNoteModel toDetailedNoteModel() {
    final event = Event.withoutSignature(
      pubkey: currentSigner!.getPublicKey(),
      kind: EventKind.TEXT_NOTE,
      tags: notePreview.tags,
      content: notePreview.content,
      createdAt: scheduledAt,
    );

    event.id = noteId.isNotEmpty ? noteId : event.id;

    return DetailedNoteModel.fromEvent(event);
  }
}

class DvmNotePreview {
  DvmNotePreview({
    required this.content,
    required this.tags,
  });

  factory DvmNotePreview.fromMap(Map<String, dynamic> json) => DvmNotePreview(
        content: json['content'] as String? ?? '',
        tags: json['tags'] != null
            ? List<List<String>>.from(json['tags']
                .map((x) => List<String>.from(x.map((y) => y.toString()))))
            : [],
      );

  final String content;
  final List<List<String>> tags;

  Map<String, dynamic> toMap() => {
        'content': content,
        'tags': List<dynamic>.from(
            tags.map((x) => List<dynamic>.from(x.map((y) => y)))),
      };
}
