import 'dart:convert';

import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

String topicsToJson(List<Topic> topics) => json.encode(topics);

List<Topic> topicsFromJson(String topics) =>
    json.decode(topics).map((e) => Topic.fromMap(e)).toList();

List<Topic> topicsFromMaps(List<dynamic> topics) =>
    topics.map((e) => Topic.fromMap(e)).toList();

List<String> topicsFromEvent(Event event) {
  final Set<String> topics = {};

  if (event.kind == EventKind.APP_CUSTOM) {
    for (final tag in event.tags) {
      if (tag[0] == 't' && tag.length > 1) {
        topics.add(tag[1]);
      }
    }
  }

  return topics.toList();
}

List<String> interestsFromEvent(Event event) {
  final Set<String> topics = {};

  if (event.kind == EventKind.INTEREST_SET) {
    for (final tag in event.tags) {
      if (tag[0] == 't' && tag.length > 1) {
        topics.add(tag[1]);
      }
    }
  }

  return topics.toList();
}

class Topic {
  Topic({
    required this.topic,
    required this.icon,
    required this.subTopics,
  });

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      topic: map['main_tag'] as String,
      icon: map['icon'] as String,
      subTopics: List<String>.from(map['sub_tags'] as List),
    );
  }

  factory Topic.fromJson(String source) =>
      Topic.fromMap(json.decode(source) as Map<String, dynamic>);
  final String topic;
  final String icon;
  final List<String> subTopics;

  Topic copyWith({
    String? topic,
    String? icon,
    List<String>? subTopics,
  }) {
    return Topic(
      topic: topic ?? this.topic,
      icon: icon ?? this.icon,
      subTopics: subTopics ?? this.subTopics,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'topic': topic,
      'icon': icon,
      'subTopics': subTopics,
    };
  }

  String toJson() => json.encode(toMap());
}
