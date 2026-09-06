import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/logic/ask_ai_cubit/ask_ai_cubit.dart';

void main() {
  test('pairs a reworded paragraph instead of splitting add+remove', () {
    final cubit = AskAiCubit(
      readMarkdown: () => '',
      writeMarkdown: (_) async {},
    );

    const original = 'Intro paragraph.\n\nThe quick brown fox jumps over '
        'the lazy dog today.\n\nOutro paragraph.';
    const revised = 'Intro paragraph.\n\nThe quick brown fox leaps over '
        'a lazy dog now.\n\nOutro paragraph.';

    final hunks = cubit.buildParagraphDiffForTest(original, revised);
    final changed = hunks.where((h) => h.isChanged).toList();

    expect(changed.length, 1);
    expect(changed.single.originalParagraph, isNotNull);
    expect(changed.single.revisedParagraph, isNotNull);
  });

  test('equal-length unmatched runs zip positionally into changed hunks', () {
    final cubit = AskAiCubit(
      readMarkdown: () => '',
      writeMarkdown: (_) async {},
    );

    const original = 'Keep this.\n\nRemove this paragraph entirely.';
    const revised = 'Keep this.\n\nCompletely unrelated new paragraph '
        'about something else.';

    final hunks = cubit.buildParagraphDiffForTest(original, revised);
    final changed = hunks.where((h) => h.isChanged).toList();

    expect(changed.length, 1);
    expect(changed.single.originalParagraph, isNotNull);
    expect(changed.single.revisedParagraph, isNotNull);
  });

  test('extra added paragraph beyond removed count stays a pure addition',
      () {
    final cubit = AskAiCubit(
      readMarkdown: () => '',
      writeMarkdown: (_) async {},
    );

    const original = 'Keep this.';
    const revised = 'Keep this.\n\nBrand new unrelated paragraph.';

    final hunks = cubit.buildParagraphDiffForTest(original, revised);
    final changed = hunks.where((h) => h.isChanged).toList();

    expect(changed.length, 1);
    expect(changed.single.isPureAddition, isTrue);
  });

  test('code fence with a blank line inside stays one block', () {
    final cubit = AskAiCubit(
      readMarkdown: () => '',
      writeMarkdown: (_) async {},
    );

    const original = 'Intro.\n\n```\nline1\n\nline2\n```\n\nOutro.';
    const revised = 'Intro.\n\n```\nline1\n\nline2 changed\n```\n\nOutro.';

    final hunks = cubit.buildParagraphDiffForTest(original, revised);
    final changed = hunks.where((h) => h.isChanged).toList();

    expect(changed.length, 1);
    expect(changed.single.originalParagraph, contains('```\nline1\n\nline2\n```'));
  });
}
