// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import 'flash_news_model.dart';

class PollModel extends Equatable implements BaseEventModel {
  const PollModel({
    required this.id,
    required this.pubkey,
    required this.zapPubkey,
    required this.content,
    required this.valMin,
    required this.valMax,
    required this.threshold,
    required this.createdAt,
    required this.closedAt,
    required this.options,
    required this.event,
  });

  factory PollModel.fromEvent(Event event) {
    int valMin = -1;
    int valMax = -1;
    int threshold = -1;
    DateTime closedAt = DateTime(1950);
    final List<PollOption> options = [];
    String zapPubkey = event.pubkey;

    for (final tag in event.tags) {
      if (tag.length > 1) {
        if (tag.first == 'p') {
          zapPubkey = tag[1];
        } else if (tag.first == 'poll_option' && tag.length > 2) {
          options.add(
            PollOption(index: int.tryParse(tag[1]) ?? 0, content: tag[2]),
          );
        } else if (tag.first == 'value_maximum') {
          valMax = int.tryParse(tag[1]) ?? -1;
        } else if (tag.first == 'value_minimum') {
          valMin = int.tryParse(tag[1]) ?? -1;
        } else if (tag.first == 'consensus_threshold') {
          threshold = int.tryParse(tag[1]) ?? -1;
        } else if (tag.first == 'closed_at') {
          final int? unixTimeStamp = int.tryParse(tag[1]);
          if (unixTimeStamp != null) {
            closedAt =
                DateTime.fromMillisecondsSinceEpoch(unixTimeStamp * 1000);
          }
        }
      }
    }

    return PollModel(
      id: event.id,
      pubkey: event.pubkey,
      zapPubkey: zapPubkey,
      content: event.content,
      valMin: valMin,
      valMax: valMax,
      threshold: threshold,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      closedAt: closedAt,
      options: options,
      event: event,
    );
  }

  @override
  final String id;
  @override
  final String pubkey;
  final String zapPubkey;
  final String content;
  final num valMin;
  final num valMax;
  final num threshold;
  @override
  final DateTime createdAt;
  final DateTime closedAt;
  final List<PollOption> options;
  final Event event;

  @override
  List<Object?> get props => [
        id,
        pubkey,
        zapPubkey,
        content,
        valMin,
        valMax,
        threshold,
        createdAt,
        closedAt,
        options,
      ];

  PollModel copyWith({
    String? id,
    String? pubkey,
    String? zapPubkey,
    String? content,
    num? valMin,
    num? valMax,
    num? threshold,
    DateTime? createdAt,
    DateTime? closedAt,
    List<PollOption>? options,
  }) {
    return PollModel(
      id: id ?? this.id,
      event: event,
      pubkey: pubkey ?? this.pubkey,
      zapPubkey: zapPubkey ?? this.zapPubkey,
      content: content ?? this.content,
      valMin: valMin ?? this.valMin,
      valMax: valMax ?? this.valMax,
      threshold: threshold ?? this.threshold,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      options: options ?? this.options,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'pubkey': pubkey,
      'zapPubkey': zapPubkey,
      'content': content,
      'valMin': valMin,
      'valMax': valMax,
      'threshold': threshold,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'closedAt': closedAt.millisecondsSinceEpoch,
      'options': options.map((x) => x.toMap()).toList(),
      'event': event.toJson(),
    };
  }

  factory PollModel.fromMap(Map<String, dynamic> map) {
    return PollModel(
      id: map['id'] as String,
      pubkey: map['pubkey'] as String,
      zapPubkey: map['zapPubkey'] as String,
      content: map['content'] as String,
      valMin: map['valMin'] as num,
      valMax: map['valMax'] as num,
      threshold: map['threshold'] as num,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      closedAt: DateTime.fromMillisecondsSinceEpoch(map['closedAt'] as int),
      options: List<PollOption>.from(
        (map['options'] as List<dynamic>).map<PollOption>(
          (x) => PollOption.fromMap(x as Map<String, dynamic>),
        ),
      ),
      event: Event.fromJson(map['event'] as Map<String, dynamic>),
    );
  }

  String nEvent() {
    return Nip19.encodeShareableEntity(
      'nevent',
      id,
      [],
      pubkey,
      EventKind.POLL,
    );
  }

  String toJson() => json.encode(toMap());

  factory PollModel.fromJson(String source) =>
      PollModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

class PollOption extends Equatable {
  const PollOption({
    required this.index,
    required this.content,
  });
  final int index;
  final String content;

  @override
  List<Object?> get props => [
        index,
        content,
      ];

  PollOption copyWith({
    int? index,
    String? content,
  }) {
    return PollOption(
      index: index ?? this.index,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'index': index,
      'content': content,
    };
  }

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      index: map['index'] as int,
      content: map['content'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PollOption.fromJson(String source) =>
      PollOption.fromMap(json.decode(source) as Map<String, dynamic>);
}

class PollStat {
  PollStat({
    required this.pubkey,
    required this.zapAmount,
    required this.createdAt,
    required this.index,
  });
  final String pubkey;
  final num zapAmount;
  final DateTime createdAt;
  final int index;
}
