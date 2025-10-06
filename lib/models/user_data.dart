// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/models/models.dart';

class UserData extends Equatable {
  const UserData({
    required this.metadata,
    required this.nip05,
  });

  final Metadata metadata;
  final Nip05 nip05;

  @override
  List<Object?> get props => [metadata, nip05];

  UserData copyWith({
    Metadata? metadata,
    Nip05? nip05,
  }) {
    return UserData(
      metadata: metadata ?? this.metadata,
      nip05: nip05 ?? this.nip05,
    );
  }
}
