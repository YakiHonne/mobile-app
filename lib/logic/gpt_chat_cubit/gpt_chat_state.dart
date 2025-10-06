// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'gpt_chat_cubit.dart';

class GptChatState extends Equatable {
  final List<ChatMessage> chatMessage;

  const GptChatState({
    required this.chatMessage,
  });

  @override
  List<Object> get props => [chatMessage];

  GptChatState copyWith({
    List<ChatMessage>? chatMessage,
  }) {
    return GptChatState(
      chatMessage: chatMessage ?? this.chatMessage,
    );
  }
}
