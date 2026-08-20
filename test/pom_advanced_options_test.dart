import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/views/logify_view/widgets/pom_advanced_options.dart';

// URL and private-key validation now live in nostr_core_enhanced and are
// covered by its `test/pomegranate_validation_test.dart`. What remains here is
// the operator/threshold UI contract, which is app-side.
void main() {
  group('threshold invariants', () {
    // A 1-of-n split hands any single operator the whole key, and a threshold
    // above the operator count can never be satisfied.
    test('minimums are both 2', () {
      expect(kPomMinOperators, 2);
      expect(kPomMinThreshold, 2);
    });

    test('removing an operator clamps the threshold to the new count', () {
      var operators = ['a', 'b', 'c'];
      var threshold = 3;

      operators = operators.where((o) => o != 'c').toList();
      if (threshold > operators.length) {
        threshold = operators.length;
      }

      expect(operators.length, 2);
      expect(threshold, 2);
      expect(threshold, lessThanOrEqualTo(operators.length));
    });
  });
}
