import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// One locally cached Nostr kind-1 note passed to the nspam model.
class NSpamNoteInput {
  const NSpamNoteInput({
    required this.content,
    required this.tags,
    required this.createdAt,
  });

  final String content;
  final List<List<String>> tags;
  final int createdAt;
}

/// Builds the feature vector expected by Wisp's bundled nspam LightGBM model.
///
/// The implementation is a Dart port of Wisp's MIT-licensed nspam feature
/// extractor. See `assets/nspam/LICENSE` and `assets/nspam/README.md`.
class NSpamFeatureExtractor {
  static const int charFeatureCount = 131072;
  static const int wordFeatureCount = 131072;
  static const int structuralFeatureCount = 17;
  static const int groupFeatureCount = 6;
  static const int featureCount = charFeatureCount +
      wordFeatureCount +
      structuralFeatureCount +
      groupFeatureCount;

  static const Set<int> _invisibleCodePoints = <int>{
    0x180e,
    0x200b,
    0x200c,
    0x200d,
    0x200e,
    0x200f,
    0x202a,
    0x202b,
    0x202c,
    0x202d,
    0x202e,
    0x2060,
    0x2061,
    0x2062,
    0x2063,
    0x2064,
    0x2066,
    0x2067,
    0x2068,
    0x2069,
    0xfeff,
  };

  static final RegExp _wordPattern =
      RegExp(r'[\p{L}\p{N}_]{2,}', unicode: true);
  static final RegExp _whitespacePattern = RegExp(r'\s+', unicode: true);
  static final RegExp _urlPattern =
      RegExp(r'https?://([^\s/]+)', caseSensitive: false, unicode: true);
  static final RegExp _mentionPattern = RegExp(
    r'\b(?:nostr:)?(?:npub1|note1|nprofile1|nevent1|naddr1)[0-9a-z]+',
    caseSensitive: false,
    unicode: true,
  );
  static final RegExp _hashtagPattern = RegExp(r'#\w+', unicode: true);
  static final RegExp _nonWhitespacePattern = RegExp(r'\S+', unicode: true);

  /// Unicode 17.0 ranges for Emoji_Presentation ∪ Extended_Pictographic.
  /// Dart RegExp supports general categories but not these binary properties.
  static const List<(int, int)> _emojiCodePointRanges = <(int, int)>[
    (0x00a9, 0x00a9),
    (0x00ae, 0x00ae),
    (0x203c, 0x203c),
    (0x2049, 0x2049),
    (0x2122, 0x2122),
    (0x2139, 0x2139),
    (0x2194, 0x2199),
    (0x21a9, 0x21aa),
    (0x231a, 0x231b),
    (0x2328, 0x2328),
    (0x23cf, 0x23cf),
    (0x23e9, 0x23f3),
    (0x23f8, 0x23fa),
    (0x24c2, 0x24c2),
    (0x25aa, 0x25ab),
    (0x25b6, 0x25b6),
    (0x25c0, 0x25c0),
    (0x25fb, 0x25fe),
    (0x2600, 0x2604),
    (0x260e, 0x260e),
    (0x2611, 0x2611),
    (0x2614, 0x2615),
    (0x2618, 0x2618),
    (0x261d, 0x261d),
    (0x2620, 0x2620),
    (0x2622, 0x2623),
    (0x2626, 0x2626),
    (0x262a, 0x262a),
    (0x262e, 0x262f),
    (0x2638, 0x263a),
    (0x2640, 0x2640),
    (0x2642, 0x2642),
    (0x2648, 0x2653),
    (0x265f, 0x2660),
    (0x2663, 0x2663),
    (0x2665, 0x2666),
    (0x2668, 0x2668),
    (0x267b, 0x267b),
    (0x267e, 0x267f),
    (0x2692, 0x2697),
    (0x2699, 0x2699),
    (0x269b, 0x269c),
    (0x26a0, 0x26a1),
    (0x26a7, 0x26a7),
    (0x26aa, 0x26ab),
    (0x26b0, 0x26b1),
    (0x26bd, 0x26be),
    (0x26c4, 0x26c5),
    (0x26c8, 0x26c8),
    (0x26ce, 0x26cf),
    (0x26d1, 0x26d1),
    (0x26d3, 0x26d4),
    (0x26e9, 0x26ea),
    (0x26f0, 0x26f5),
    (0x26f7, 0x26fa),
    (0x26fd, 0x26fd),
    (0x2702, 0x2702),
    (0x2705, 0x2705),
    (0x2708, 0x270d),
    (0x270f, 0x270f),
    (0x2712, 0x2712),
    (0x2714, 0x2714),
    (0x2716, 0x2716),
    (0x271d, 0x271d),
    (0x2721, 0x2721),
    (0x2728, 0x2728),
    (0x2733, 0x2734),
    (0x2744, 0x2744),
    (0x2747, 0x2747),
    (0x274c, 0x274c),
    (0x274e, 0x274e),
    (0x2753, 0x2755),
    (0x2757, 0x2757),
    (0x2763, 0x2764),
    (0x2795, 0x2797),
    (0x27a1, 0x27a1),
    (0x27b0, 0x27b0),
    (0x27bf, 0x27bf),
    (0x2934, 0x2935),
    (0x2b05, 0x2b07),
    (0x2b1b, 0x2b1c),
    (0x2b50, 0x2b50),
    (0x2b55, 0x2b55),
    (0x3030, 0x3030),
    (0x303d, 0x303d),
    (0x3297, 0x3297),
    (0x3299, 0x3299),
    (0x1f004, 0x1f004),
    (0x1f02c, 0x1f02f),
    (0x1f094, 0x1f09f),
    (0x1f0af, 0x1f0b0),
    (0x1f0c0, 0x1f0c0),
    (0x1f0cf, 0x1f0d0),
    (0x1f0f6, 0x1f0ff),
    (0x1f170, 0x1f171),
    (0x1f17e, 0x1f17f),
    (0x1f18e, 0x1f18e),
    (0x1f191, 0x1f19a),
    (0x1f1ae, 0x1f1ff),
    (0x1f201, 0x1f20f),
    (0x1f21a, 0x1f21a),
    (0x1f22f, 0x1f22f),
    (0x1f232, 0x1f23a),
    (0x1f23c, 0x1f23f),
    (0x1f249, 0x1f25f),
    (0x1f266, 0x1f321),
    (0x1f324, 0x1f393),
    (0x1f396, 0x1f397),
    (0x1f399, 0x1f39b),
    (0x1f39e, 0x1f3f0),
    (0x1f3f3, 0x1f3f5),
    (0x1f3f7, 0x1f4fd),
    (0x1f4ff, 0x1f53d),
    (0x1f549, 0x1f54e),
    (0x1f550, 0x1f567),
    (0x1f56f, 0x1f570),
    (0x1f573, 0x1f57a),
    (0x1f587, 0x1f587),
    (0x1f58a, 0x1f58d),
    (0x1f590, 0x1f590),
    (0x1f595, 0x1f596),
    (0x1f5a4, 0x1f5a5),
    (0x1f5a8, 0x1f5a8),
    (0x1f5b1, 0x1f5b2),
    (0x1f5bc, 0x1f5bc),
    (0x1f5c2, 0x1f5c4),
    (0x1f5d1, 0x1f5d3),
    (0x1f5dc, 0x1f5de),
    (0x1f5e1, 0x1f5e1),
    (0x1f5e3, 0x1f5e3),
    (0x1f5e8, 0x1f5e8),
    (0x1f5ef, 0x1f5ef),
    (0x1f5f3, 0x1f5f3),
    (0x1f5fa, 0x1f64f),
    (0x1f680, 0x1f6c5),
    (0x1f6cb, 0x1f6d2),
    (0x1f6d5, 0x1f6e5),
    (0x1f6e9, 0x1f6e9),
    (0x1f6eb, 0x1f6f0),
    (0x1f6f3, 0x1f6ff),
    (0x1f7da, 0x1f7ff),
    (0x1f80c, 0x1f80f),
    (0x1f848, 0x1f84f),
    (0x1f85a, 0x1f85f),
    (0x1f888, 0x1f88f),
    (0x1f8ae, 0x1f8af),
    (0x1f8bc, 0x1f8bf),
    (0x1f8c2, 0x1f8cf),
    (0x1f8d9, 0x1f8ff),
    (0x1f90c, 0x1f93a),
    (0x1f93c, 0x1f945),
    (0x1f947, 0x1f9ff),
    (0x1fa58, 0x1fa5f),
    (0x1fa6e, 0x1faff),
    (0x1fc00, 0x1fffd),
  ];
  static final RegExp _digitPattern = RegExp(r'\p{N}', unicode: true);
  static final RegExp _punctuationPattern = RegExp(r'\p{P}', unicode: true);
  static final RegExp _tokenizePattern = RegExp(
    r'\p{L}[\p{L}\p{M}\p{N}_]*|\p{N}+|https?://\S+|[#@][\w]+',
    caseSensitive: false,
    unicode: true,
  );

  static Float32List extractFeatures(List<NSpamNoteInput> notes) {
    final features = Float32List(featureCount);
    if (notes.isEmpty) {
      return features;
    }

    final prepared = notes.map((note) => _preprocess(note.content)).toList();
    _hashCharNgrams(prepared.map((item) => item.rawText).join(' '), features);
    _hashWordNgrams(prepared.map((item) => item.text).join(' '), features);

    final structuralSums = Float32List(structuralFeatureCount);
    final bodyKeys = <String>[];
    final rawTexts = <String>[];
    final charLengths = <double>[];

    for (final note in notes) {
      final raw = note.content;
      rawTexts.add(raw);
      bodyKeys.add(_bodyKey(raw));
      charLengths.add(raw.length.toDouble());

      final structural = _extractStructural(raw, note.tags);
      for (var index = 0; index < structural.length; index++) {
        structuralSums[index] += structural[index];
      }
    }

    const structuralOffset = charFeatureCount + wordFeatureCount;
    for (var index = 0; index < structuralFeatureCount; index++) {
      features[structuralOffset + index] = structuralSums[index] / notes.length;
    }

    const groupOffset = structuralOffset + structuralFeatureCount;
    features[groupOffset] = notes.length.toDouble();
    if (notes.length > 1) {
      final timestamps = notes.map((note) => note.createdAt).toList();
      features[groupOffset + 1] =
          (timestamps.reduce(math.max) - timestamps.reduce(math.min)) / 3600;
    }
    features[groupOffset + 2] =
        bodyKeys.where((key) => key.isNotEmpty).toSet().length.toDouble();

    if (notes.length > 1) {
      features[groupOffset + 3] = _populationStdDev(charLengths);

      final tokenLists = rawTexts
          .map((raw) => _tokenizePattern
              .allMatches(raw.toLowerCase())
              .map((match) => match.group(0)!)
              .toList())
          .toList();
      final firstTokens = tokenLists
          .map((tokens) => tokens.isEmpty ? null : tokens.first)
          .whereType<String>()
          .toList();
      if (firstTokens.isNotEmpty) {
        final counts = <String, int>{};
        for (final token in firstTokens) {
          counts.update(token, (count) => count + 1, ifAbsent: () => 1);
        }
        features[groupOffset + 4] =
            counts.values.reduce(math.max) / notes.length;
      }

      final tokenSets = tokenLists.map((tokens) => tokens.toSet()).toList();
      var jaccardSum = 0.0;
      var jaccardCount = 0;
      for (var leftIndex = 0; leftIndex < tokenSets.length; leftIndex++) {
        for (var rightIndex = leftIndex + 1;
            rightIndex < tokenSets.length;
            rightIndex++) {
          final left = tokenSets[leftIndex];
          final right = tokenSets[rightIndex];
          final unionCount = left.union(right).length;
          if (unionCount > 0) {
            jaccardSum += left.intersection(right).length / unionCount;
          }
          jaccardCount++;
        }
      }
      if (jaccardCount > 0) {
        features[groupOffset + 5] = jaccardSum / jaccardCount;
      }
    }

    return features;
  }

  static _PreparedText _preprocess(String input) {
    final nfkc = _normalizeCompatibility(input);
    var stripped = String.fromCharCodes(
      nfkc.runes.where((rune) => !_invisibleCodePoints.contains(rune)),
    );
    stripped = stripped.replaceAllMapped(
      RegExp(r'https?://([^\s/]+)(/\S*)?', caseSensitive: false, unicode: true),
      (match) => 'http://${match.group(1)!.toLowerCase()}',
    );
    stripped =
        stripped.toLowerCase().replaceAll(_whitespacePattern, ' ').trim();
    return _PreparedText(text: stripped, rawText: nfkc);
  }

  static String _normalizeCompatibility(String input) {
    return unorm.nfkc(input);
  }

  static String _bodyKey(String raw) {
    final stripped = String.fromCharCodes(
      raw.runes.where((rune) => !_invisibleCodePoints.contains(rune)),
    ).trim().toLowerCase();
    return String.fromCharCodes(stripped.runes.take(200));
  }

  static Float32List _extractStructural(String raw, List<List<String>> tags) {
    final urls = _urlPattern.allMatches(raw).toList();
    final uniqueDomains =
        urls.map((match) => match.group(1)!.toLowerCase()).toSet().length;
    var tagP = 0;
    var tagE = 0;
    var tagT = 0;
    var tagOther = 0;
    for (final tag in tags) {
      if (tag.isEmpty) {
        continue;
      }
      switch (tag.first) {
        case 'p':
          tagP++;
        case 'e':
          tagE++;
        case 't':
          tagT++;
        default:
          tagOther++;
      }
    }

    var alphabeticCount = 0;
    var uppercaseCount = 0;
    for (final rune in raw.runes) {
      final character = String.fromCharCode(rune);
      final lowercase = character.toLowerCase();
      final uppercase = character.toUpperCase();
      if (lowercase != uppercase) {
        alphabeticCount++;
        if (character == uppercase) {
          uppercaseCount++;
        }
      }
    }

    final emojiCount = raw.runes.where(_isEmojiCodePoint).length;
    final digitCount = _digitPattern.allMatches(raw).length;
    final punctuationCount = _punctuationPattern.allMatches(raw).length;
    final zeroWidthCount =
        raw.runes.where(_invisibleCodePoints.contains).length;
    final rawLength = raw.length;

    return Float32List.fromList(<double>[
      rawLength.toDouble(),
      _nonWhitespacePattern.allMatches(raw).length.toDouble(),
      urls.length.toDouble(),
      uniqueDomains.toDouble(),
      _mentionPattern.allMatches(raw).length.toDouble(),
      _hashtagPattern.allMatches(raw).length.toDouble(),
      tagP.toDouble(),
      tagE.toDouble(),
      tagT.toDouble(),
      tagOther.toDouble(),
      emojiCount.toDouble(),
      _ratio(emojiCount, rawLength),
      zeroWidthCount.toDouble(),
      _ratio(uppercaseCount, alphabeticCount),
      _ratio(digitCount, rawLength),
      _ratio(punctuationCount, rawLength),
      0,
    ]);
  }

  static double _ratio(int numerator, int denominator) {
    return denominator == 0 ? 0 : numerator / denominator;
  }

  static bool _isEmojiCodePoint(int codePoint) {
    var lower = 0;
    var upper = _emojiCodePointRanges.length;
    while (lower < upper) {
      final middle = (lower + upper) ~/ 2;
      final range = _emojiCodePointRanges[middle];
      if (codePoint < range.$1) {
        upper = middle;
      } else if (codePoint > range.$2) {
        lower = middle + 1;
      } else {
        return true;
      }
    }
    return false;
  }

  static void _hashWordNgrams(String text, Float32List features) {
    final tokens =
        _wordPattern.allMatches(text).map((match) => match.group(0)!).toList();
    for (final token in tokens) {
      _hashInto(token, features, charFeatureCount, wordFeatureCount);
    }
    for (var index = 0; index < tokens.length - 1; index++) {
      _hashInto(
        '${tokens[index]} ${tokens[index + 1]}',
        features,
        charFeatureCount,
        wordFeatureCount,
      );
    }
  }

  static void _hashCharNgrams(String text, Float32List features) {
    final normalized = text.replaceAll(_whitespacePattern, ' ');
    for (final word in normalized.split(' ')) {
      if (word.isEmpty) {
        continue;
      }
      final padded = ' $word ';
      for (var size = 3; size <= 5; size++) {
        for (var start = 0; start <= padded.length - size; start++) {
          _hashInto(
            padded.substring(start, start + size),
            features,
            0,
            charFeatureCount,
          );
        }
      }
    }
  }

  static void _hashInto(
    String token,
    Float32List features,
    int offset,
    int featureBucketCount,
  ) {
    final hash = _murmurHash3(utf8.encode(token));
    final index = hash.abs() % featureBucketCount;
    features[offset + index] += hash >= 0 ? 1 : -1;
  }

  static int _murmurHash3(List<int> bytes) {
    const mask = 0xffffffff;
    const c1 = 0xcc9e2d51;
    const c2 = 0x1b873593;
    const fmix1 = 0x85ebca6b;
    const fmix2 = 0xc2b2ae35;
    var hash = 0;
    final blockCount = bytes.length ~/ 4;

    int rotateLeft(int value, int count) {
      return ((value << count) | (value >>> (32 - count))) & mask;
    }

    for (var block = 0; block < blockCount; block++) {
      final offset = block * 4;
      var key = bytes[offset] |
          (bytes[offset + 1] << 8) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 3] << 24);
      key = (key * c1) & mask;
      key = rotateLeft(key, 15);
      key = (key * c2) & mask;
      hash = (hash ^ key) & mask;
      hash = rotateLeft(hash, 13);
      hash = (hash * 5 + 0xe6546b64) & mask;
    }

    final tailOffset = blockCount * 4;
    var tail = 0;
    final remaining = bytes.length & 3;
    if (remaining == 3) {
      tail ^= bytes[tailOffset + 2] << 16;
    }
    if (remaining >= 2) {
      tail ^= bytes[tailOffset + 1] << 8;
    }
    if (remaining >= 1) {
      tail ^= bytes[tailOffset];
      tail = (tail * c1) & mask;
      tail = rotateLeft(tail, 15);
      tail = (tail * c2) & mask;
      hash = (hash ^ tail) & mask;
    }

    hash = (hash ^ bytes.length) & mask;
    hash = (hash ^ (hash >>> 16)) & mask;
    hash = (hash * fmix1) & mask;
    hash = (hash ^ (hash >>> 13)) & mask;
    hash = (hash * fmix2) & mask;
    hash = (hash ^ (hash >>> 16)) & mask;
    return hash >= 0x80000000 ? hash - 0x100000000 : hash;
  }

  static double _populationStdDev(List<double> values) {
    if (values.length <= 1) {
      return 0;
    }
    final mean = values.reduce((left, right) => left + right) / values.length;
    final variance = values
            .map((value) => (value - mean) * (value - mean))
            .reduce((left, right) => left + right) /
        values.length;
    return math.sqrt(variance);
  }
}

class _PreparedText {
  const _PreparedText({
    required this.text,
    required this.rawText,
  });

  final String text;
  final String rawText;
}
