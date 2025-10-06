// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

class AiChatMessage extends Equatable {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isCurrentUser;

  const AiChatMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isCurrentUser,
  });

  @override
  List<Object?> get props => [
        id,
        content,
        createdAt,
        isCurrentUser,
      ];

  AiChatMessage copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    bool? isCurrentUser,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
