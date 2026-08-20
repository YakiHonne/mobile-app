part of 'ask_ai_cubit.dart';

class DiffHunk {
  const DiffHunk({
    required this.originalParagraph,
    required this.revisedParagraph,
    this.accepted = true,
    this.decided = false,
  });

  final String? originalParagraph;
  final String? revisedParagraph;
  final bool accepted;
  final bool decided;

  DiffHunk copyWith({bool? accepted, bool? decided}) => DiffHunk(
        originalParagraph: originalParagraph,
        revisedParagraph: revisedParagraph,
        accepted: accepted ?? this.accepted,
        decided: decided ?? this.decided,
      );

  bool get isChanged =>
      originalParagraph != revisedParagraph &&
      !(originalParagraph == null && revisedParagraph == null);

  bool get isPureAddition => originalParagraph == null;
  bool get isPureDeletion => revisedParagraph == null;
}

enum ChatRole { user, ai }

class ChatMessage {
  const ChatMessage({required this.role, required this.text});
  final ChatRole role;
  final String text;
}

enum AskAiView { chat, diff }

class AskAiState {
  const AskAiState({
    this.view = AskAiView.chat,
    this.isLoading = false,
    this.messages = const [],
    this.aiContent,
    this.hunks = const [],
    this.error,
    this.applied = false,
  });

  final AskAiView view;
  final bool isLoading;
  final List<ChatMessage> messages;
  final String? aiContent;
  final List<DiffHunk> hunks;
  final String? error;
  final bool applied;

  int get changedHunkCount => hunks.where((h) => h.isChanged).length;
  bool get allDecided =>
      hunks.where((h) => h.isChanged).every((h) => h.decided);

  AskAiState copyWith({
    AskAiView? view,
    bool? isLoading,
    List<ChatMessage>? messages,
    String? Function()? aiContent,
    List<DiffHunk>? hunks,
    String? Function()? error,
    bool? applied,
  }) {
    return AskAiState(
      view: view ?? this.view,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      aiContent: aiContent != null ? aiContent() : this.aiContent,
      hunks: hunks ?? this.hunks,
      error: error != null ? error() : this.error,
      applied: applied ?? this.applied,
    );
  }
}
