// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:uuid/uuid.dart';

class ChatMessage extends Equatable {
  final String id;
  final String text;
  final Metadata user;
  final DateTime createdAt;
  final ChatMessage? replyTo;
  final bool isCurrentUser;

  const ChatMessage({
    required this.text,
    required this.id,
    required this.user,
    required this.createdAt,
    required this.isCurrentUser,
    this.replyTo,
  });

  factory ChatMessage.fromDirectData({
    required String message,
    required Metadata user,
    required bool isCurrentUser,
  }) {
    return ChatMessage(
      id: const Uuid().v4(),
      text: message,
      createdAt: DateTime.now(),
      isCurrentUser: isCurrentUser,
      user: user,
    );
  }

  @override
  List<Object?> get props => [
        id,
        text,
        user,
        createdAt,
        isCurrentUser,
      ];
}
