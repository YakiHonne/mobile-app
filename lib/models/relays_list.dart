// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class Relays extends Equatable {
  final List<String> relays;
  final String pubKey;

  const Relays({
    required this.relays,
    required this.pubKey,
  });

  @override
  List<Object?> get props => [relays, pubKey];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'relays': relays,
      'pubkey': pubKey,
    };
  }

  factory Relays.fromMap(Map<String, dynamic> map) {
    return Relays(
      relays: map['relays'],
      pubKey: map['pubkey'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Relays.fromJson(String source) =>
      Relays.fromMap(json.decode(source) as Map<String, dynamic>);
}
