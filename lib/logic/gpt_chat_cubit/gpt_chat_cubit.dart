import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../models/chat_message.dart';
import '../../utils/utils.dart';

part 'gpt_chat_state.dart';

class GptChatCubit extends Cubit<GptChatState> {
  GptChatCubit()
      : super(
          GptChatState(
            chatMessage: nostrRepository.gptMessages,
          ),
        );

  final _openAi = OpenAI.instance.build(
    token: dotenv.env['GPT_KEY'],
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 5),
    ),
    enableLog: true,
  );

  Future<void> getChatResponse(String message) async {
    final m = ChatMessage.fromDirectData(
      message: message,
      user: nostrRepository.currentMetadata,
      isCurrentUser: true,
    );
    if (!isClosed) {
      emit(
        state.copyWith(
          chatMessage: [
            ...state.chatMessage,
            m,
          ],
        ),
      );
    }

    final messagesHistory = state.chatMessage.map((m) {
      if (m.user == nostrRepository.currentMetadata) {
        return Messages(
          role: Role.user,
          content: m.text,
        );
      } else {
        return Messages(role: Role.assistant, content: m.text);
      }
    }).toList();

    final request = ChatCompleteText(
      model: GptTurbo0301ChatModel(),
      messages: messagesHistory
          .map(
            (e) => e.toJson(),
          )
          .toList(),
      maxToken: 200,
    );

    ChatCTResponse? response;

    try {
      response = await _openAi.onChatCompletion(request: request);
    } catch (e) {
      lg.i(e);
    }

    if (response == null) {
      for (final element in response!.choices) {
        if (element.message != null) {
          final newMessages = [
            ...state.chatMessage,
            ChatMessage.fromDirectData(
              user: Metadata.empty().copyWith(pubkey: 'GPT'),
              message: element.message!.content,
              isCurrentUser: false,
            ),
          ];

          nostrRepository.gptMessages = newMessages;
          if (!isClosed) {
            emit(
              state.copyWith(
                chatMessage: newMessages,
              ),
            );
          }
        }
      }
    }
  }

  void clearMessages() {
    if (!isClosed) {
      emit(
        state.copyWith(
          chatMessage: [],
        ),
      );
    }

    nostrRepository.gptMessages = [];
  }
}
