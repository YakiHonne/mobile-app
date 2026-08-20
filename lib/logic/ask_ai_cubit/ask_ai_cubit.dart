import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/http_functions_repository.dart';
import '../subscription_cubit/usage_limit.dart';

part 'ask_ai_state.dart';

class AskAiCubit extends Cubit<AskAiState> {
  AskAiCubit({
    required this.readMarkdown,
    required this.writeMarkdown,
  }) : super(const AskAiState());

  /// Reads the editor's current content as markdown.
  final String Function() readMarkdown;

  /// Replaces the editor's whole content with the given markdown.
  final Future<void> Function(String) writeMarkdown;

  @override
  void emit(AskAiState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> send(String message) async {
    if (message.trim().isEmpty || state.isLoading || isUsageBlocked(kUsageKeyAskAi)) {
      return;
    }

    final currentMarkdown = readMarkdown();
    final userMsg = ChatMessage(role: ChatRole.user, text: message);

    emit(
      state.copyWith(
        isLoading: true,
        messages: [...state.messages, userMsg],
        aiContent: () => null,
        hunks: [],
        error: () => null,
        applied: false,
      ),
    );

    try {
      final result = await HttpFunctionsRepository.articleChatAI(
        message: message,
        article: currentMarkdown,
      );

      final explanation = result?['explanation'] as String?;
      final aiContent = result?['content'] as String?;

      if (aiContent == null || aiContent.isEmpty) {
        // A quota rejection needs no chat bubble: the fresh snapshot trips
        // UsageGate and raises the banner, which would otherwise say it twice.
        await checkUsageLimit(kUsageKeyAskAi);
        emit(state.copyWith(isLoading: false, error: () => 'error'));
        return;
      }

      refreshUsageAfterCall();

      final hunks = _buildParagraphDiff(currentMarkdown, aiContent);
      final hasChanges = hunks.any((h) => h.isChanged);

      final updatedMessages = explanation != null
          ? [...state.messages, ChatMessage(role: ChatRole.ai, text: explanation)]
          : state.messages;

      emit(
        state.copyWith(
          isLoading: false,
          view: hasChanges ? AskAiView.diff : AskAiView.chat,
          messages: updatedMessages,
          aiContent: () => aiContent,
          hunks: hunks,
        ),
      );
    } catch (_) {
      await checkUsageLimit(kUsageKeyAskAi);
      emit(state.copyWith(isLoading: false, error: () => 'error'));
    }
  }

  void showDiff() => emit(state.copyWith(view: AskAiView.diff));
  void showChat() => emit(state.copyWith(view: AskAiView.chat));

  Future<void> toggleHunk(int index, bool accepted) async {
    final updated = [
      for (var i = 0; i < state.hunks.length; i++)
        i == index
            ? state.hunks[i].copyWith(accepted: accepted, decided: true)
            : state.hunks[i],
    ];
    emit(state.copyWith(hunks: updated));
    final allDecided =
        updated.where((h) => h.isChanged).every((h) => h.decided);
    if (allDecided) {
      await applyChanges();
    }
  }

  Future<void> applyChanges() async {
    final paragraphs = <String>[];
    for (final hunk in state.hunks) {
      if (!hunk.isChanged) {
        if (hunk.originalParagraph != null) {
          paragraphs.add(hunk.originalParagraph!);
        }
        continue;
      }
      if (!hunk.accepted) {
        if (hunk.originalParagraph != null) {
          paragraphs.add(hunk.originalParagraph!);
        }
      } else {
        if (hunk.isPureDeletion) {
          // drop it
        } else if (hunk.revisedParagraph != null) {
          paragraphs.add(hunk.revisedParagraph!);
        }
      }
    }

    await writeMarkdown(paragraphs.join('\n\n'));
    emit(state.copyWith(applied: true, view: AskAiView.chat));
  }

  void rejectAll() {
    emit(state.copyWith(applied: true, view: AskAiView.chat));
  }

  void clear() => emit(const AskAiState());

  @visibleForTesting
  List<DiffHunk> buildParagraphDiffForTest(String original, String revised) =>
      _buildParagraphDiff(original, revised);

  // ── Paragraph-level diff ──────────────────────────────────────────────────

  List<DiffHunk> _buildParagraphDiff(String original, String revised) {
    final orig = _splitParagraphs(original);
    final prop = _splitParagraphs(revised);
    final common = _lcs(orig, prop);
    final hunks = <DiffHunk>[];
    var oi = 0, pi = 0;

    // Zips unmatched runs positionally (index k vs index k), matching
    // yaki_pro's diffMarkdownBlocks: predictable pairing beats a similarity
    // heuristic that can misfire and split a reworded paragraph into a
    // stray add+remove.
    void drainSlices(int toOi, int toPi) {
      final removed = orig.sublist(oi, toOi);
      final added = prop.sublist(pi, toPi);
      final maxLen =
          removed.length > added.length ? removed.length : added.length;
      for (var k = 0; k < maxLen; k++) {
        hunks.add(
          DiffHunk(
            originalParagraph: k < removed.length ? removed[k] : null,
            revisedParagraph: k < added.length ? added[k] : null,
          ),
        );
      }
    }

    for (final pair in common) {
      final ai = pair[0], bi = pair[1];
      drainSlices(ai, bi);
      hunks.add(DiffHunk(originalParagraph: orig[ai], revisedParagraph: orig[ai]));
      oi = ai + 1;
      pi = bi + 1;
    }
    drainSlices(orig.length, prop.length);
    return hunks;
  }

  List<List<int>> _lcs(List<String> a, List<String> b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1] + 1
            : (dp[i - 1][j] >= dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1]);
      }
    }
    final pairs = <List<int>>[];
    var i = m, j = n;
    while (i > 0 && j > 0) {
      if (a[i - 1] == b[j - 1]) {
        pairs.add([i - 1, j - 1]);
        i--;
        j--;
      } else if (dp[i - 1][j] >= dp[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }
    return pairs.reversed.toList();
  }

  // Splits markdown into paragraph-level blocks separated by blank lines.
  // Code fences are tracked so a blank line inside a ``` block doesn't
  // shatter it into bad hunks.
  List<String> _splitParagraphs(String text) {
    final lines = text.split('\n');
    final blocks = <String>[];
    var current = <String>[];
    var inFence = false;

    for (final line in lines) {
      if (line.startsWith('```')) {
        inFence = !inFence;
      }
      if (!inFence && line.trim().isEmpty && current.isNotEmpty) {
        blocks.add(current.join('\n'));
        current = [];
      } else {
        current.add(line);
      }
    }
    if (current.isNotEmpty) {
      blocks.add(current.join('\n'));
    }
    return blocks.where((b) => b.trim().isNotEmpty).toList();
  }
}
