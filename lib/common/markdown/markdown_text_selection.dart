import 'package:flutter/services.dart';

/// Returns a valid text range for a Markdown selection and its current text.
TextRange normalizeMarkdownSelection(TextSelection selection, int textLength) {
  if (!selection.isValid) {
    return const TextRange(start: 0, end: 0);
  }

  final start = selection.start.clamp(0, textLength);
  final end = selection.end.clamp(start, textLength);

  return TextRange(start: start, end: end);
}
