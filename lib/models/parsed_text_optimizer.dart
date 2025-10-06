import '../common/common_regex.dart';

/// Text preprocessor for feed optimization
class FeedTextOptimizer {
  static const int _defaultMaxLines = 10;
  static const int _maxWords = 150;

  /// Optimize text content for feed display
  static FeedOptimizationResult optimizeForFeed(
    String originalText, {
    int? maxLines = _defaultMaxLines,
    int? maxWords = _maxWords,
  }) {
    if (originalText.trim().isEmpty) {
      return FeedOptimizationResult(
        optimizedText: originalText,
        wasTruncated: false,
      );
    }

    final processor = _FeedTextProcessor(
      originalText: originalText.trim(),
      maxLines: maxLines ?? _defaultMaxLines,
      maxWords: maxWords ?? _maxWords,
    );

    return processor.process();
  }
}

class _FeedTextProcessor {
  _FeedTextProcessor({
    required this.originalText,
    required this.maxLines,
    required this.maxWords,
  });

  final String originalText;
  final int maxLines;
  final int maxWords;

  FeedOptimizationResult process() {
    // Step 1: Truncate to max words if needed
    String processedText = originalText;
    bool wasTruncated = false;

    final words = wordsRegExp.allMatches(originalText);
    if (words.length > maxWords) {
      final endIndex = words.elementAt(maxWords).start;
      processedText = originalText.substring(0, endIndex).trim();
      wasTruncated = true;
    }

    // Step 2: Check if the truncated text has components
    final hasComponents = _hasAnyComponents(processedText);

    if (!hasComponents) {
      // Pure text - return as-is
      return FeedOptimizationResult(
        optimizedText: processedText,
        wasTruncated: wasTruncated,
      );
    }

    // Step 3: Has components - apply line-based truncation
    final lineBasedResult = _applyLineTruncation(processedText);

    return FeedOptimizationResult(
      optimizedText: lineBasedResult,
      wasTruncated: wasTruncated || (lineBasedResult != processedText),
    );
  }

  /// Check if text contains any components (URLs, notes, invoices, etc.)
  bool _hasAnyComponents(String text) {
    return urlRegExp.hasMatch(text) ||
        nostrSchemeRegex.hasMatch(text) ||
        invoiceRegex.hasMatch(text);
  }

  /// Apply simple line-based truncation for content with components
  String _applyLineTruncation(String text) {
    final lines = text.split('\n');
    if (lines.length <= maxLines) {
      return text;
    }

    // Simple approach: take first N lines
    final truncatedLines = lines.take(maxLines).toList();
    return truncatedLines.join('\n');
  }
}

class FeedOptimizationResult {
  const FeedOptimizationResult({
    required this.optimizedText,
    required this.wasTruncated,
  });

  final String optimizedText;
  final bool wasTruncated;
}
