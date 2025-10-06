// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

List<RelaysCollection> relaysCollectionsFromList(List items) => items
    .map(
      (e) => RelaysCollection.fromMap(e),
    )
    .toList();

class RelaysCollection extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> relays;

  const RelaysCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.relays,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        relays,
      ];

  RelaysCollection copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? relays,
  }) {
    return RelaysCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      relays: relays ?? this.relays,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'relays': relays,
    };
  }

  factory RelaysCollection.fromMap(Map<String, dynamic> map) {
    return RelaysCollection(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      relays: List<String>.from(map['relays'] as List),
    );
  }

  String toJson() => json.encode(toMap());

  factory RelaysCollection.fromJson(String source) =>
      RelaysCollection.fromMap(json.decode(source) as Map<String, dynamic>);
}
