import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'nspam_feature_extractor.dart';

/// Evaluates the exported LightGBM trees without a native runtime dependency.
///
/// This is adapted from Wisp's MIT-licensed Kotlin evaluator.
class LightGbmSpamModel {
  LightGbmSpamModel._({
    required List<_LightGbmTree> trees,
    required Float32List calibrationX,
    required Float32List calibrationY,
  })  : _trees = trees,
        _calibrationX = calibrationX,
        _calibrationY = calibrationY;

  factory LightGbmSpamModel.parse(String modelText, String calibrationText) {
    final trees = <_LightGbmTree>[];
    Map<String, String>? section;

    void finishTree() {
      final current = section;
      if (current == null) {
        return;
      }
      trees.add(_LightGbmTree.fromFields(current));
      section = null;
    }

    for (final rawLine in const LineSplitter().convert(modelText)) {
      final line = rawLine.trim();
      if (line.startsWith('Tree=')) {
        finishTree();
        section = <String, String>{};
        continue;
      }
      if (line == 'end of trees') {
        finishTree();
        break;
      }

      final current = section;
      if (current == null) {
        continue;
      }
      final separator = line.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      final key = line.substring(0, separator);
      if (_treeFields.contains(key)) {
        current[key] = line.substring(separator + 1);
      }
    }

    if (trees.isEmpty) {
      throw const FormatException('The bundled nspam model contains no trees.');
    }

    final calibration = jsonDecode(calibrationText) as Map<String, dynamic>;
    return LightGbmSpamModel._(
      trees: trees,
      calibrationX: _floatList(calibration['calib_x']),
      calibrationY: _floatList(calibration['calib_y']),
    );
  }

  final List<_LightGbmTree> _trees;
  final Float32List _calibrationX;
  final Float32List _calibrationY;

  double score(List<NSpamNoteInput> notes) {
    if (notes.isEmpty) {
      return 0;
    }
    final cappedNotes = notes.length > 10
        ? (List<NSpamNoteInput>.of(notes)
              ..sort(
                  (left, right) => right.createdAt.compareTo(left.createdAt)))
            .take(10)
            .toList()
        : notes;
    final features = NSpamFeatureExtractor.extractFeatures(cappedNotes);
    final margin = rawMargin(features);
    final rawProbability = _sigmoid(margin);
    return _calibrate(rawProbability);
  }

  double rawMargin(Float32List features) {
    var sum = 0.0;
    for (final tree in _trees) {
      var node = 0;
      while (node >= 0) {
        final featureIndex = tree.splitFeature[node];
        final featureValue =
            featureIndex < features.length ? features[featureIndex] : 0.0;
        node = featureValue <= tree.threshold[node]
            ? tree.leftChild[node]
            : tree.rightChild[node];
      }
      sum += tree.leafValue[-node - 1];
    }
    return sum;
  }

  double _calibrate(double rawProbability) {
    if (_calibrationX.isEmpty || _calibrationY.isEmpty) {
      return rawProbability;
    }
    if (rawProbability <= _calibrationX.first) {
      return _calibrationY.first;
    }
    if (rawProbability >= _calibrationX.last) {
      return _calibrationY.last;
    }
    for (var index = 0; index < _calibrationX.length - 1; index++) {
      final lower = _calibrationX[index];
      final upper = _calibrationX[index + 1];
      if (rawProbability >= lower && rawProbability < upper) {
        final portion = (rawProbability - lower) / (upper - lower);
        return _calibrationY[index] +
            portion * (_calibrationY[index + 1] - _calibrationY[index]);
      }
    }
    return _calibrationY.last;
  }

  static const Set<String> _treeFields = <String>{
    'split_feature',
    'threshold',
    'left_child',
    'right_child',
    'leaf_value',
  };

  static double _sigmoid(double value) {
    if (value >= 0) {
      final exponential = math.exp(-value);
      return 1 / (1 + exponential);
    }
    final exponential = math.exp(value);
    return exponential / (1 + exponential);
  }

  static Float32List _floatList(Object? values) {
    if (values is! List<dynamic>) {
      throw const FormatException('Missing nspam calibration data.');
    }
    return Float32List.fromList(
      values.map((value) => (value as num).toDouble()).toList(),
    );
  }
}

class _LightGbmTree {
  _LightGbmTree({
    required this.splitFeature,
    required this.threshold,
    required this.leftChild,
    required this.rightChild,
    required this.leafValue,
  });

  factory _LightGbmTree.fromFields(Map<String, String> fields) {
    return _LightGbmTree(
      splitFeature: _intList(fields['split_feature']),
      threshold: _floatList(fields['threshold']),
      leftChild: _intList(fields['left_child']),
      rightChild: _intList(fields['right_child']),
      leafValue: _floatList(fields['leaf_value']),
    );
  }

  final Int32List splitFeature;
  final Float32List threshold;
  final Int32List leftChild;
  final Int32List rightChild;
  final Float32List leafValue;

  static Int32List _intList(String? value) {
    if (value == null) {
      throw const FormatException('Missing LightGBM tree integer data.');
    }
    final numbers = value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(int.parse)
        .toList();
    return Int32List.fromList(numbers);
  }

  static Float32List _floatList(String? value) {
    if (value == null) {
      throw const FormatException('Missing LightGBM tree float data.');
    }
    final numbers = value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(double.parse)
        .toList();
    return Float32List.fromList(numbers);
  }
}
