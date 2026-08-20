// import 'package:flutter_test/flutter_test.dart';
// import 'package:yakihonne/common/pomegranate/pomegranate_config.dart';

// // The retired operators must stay reachable for recovery but must never be
// // offered for new accounts. Getting this backwards is silent either way: a new
// // account sharded to a dead operator, or an old account that cannot be
// // recovered at all.
// void main() {
//   test('new accounts are never offered the retired operators', () {
//     for (final legacy in kPomLegacyOperatorUrls) {
//       expect(kPomOperatorUrls, isNot(contains(legacy)));
//       expect(kPomDefaultOperatorUrls, isNot(contains(legacy)));
//     }
//   });

//   test('recovery searches the current operators plus the retired ones', () {
//     expect(kPomRecoveryOperatorUrls, containsAll(kPomOperatorUrls));
//     expect(kPomRecoveryOperatorUrls, containsAll(kPomLegacyOperatorUrls));

//     // Pre-persistence accounts are 3-of-5; recovery needs every one of those
//     // five to be offered, so the union must not shrink below that.
//     expect(kPomRecoveryOperatorUrls.length, greaterThanOrEqualTo(5));
//     expect(kPomRecoveryOperatorUrls.toSet(), hasLength(kPomRecoveryOperatorUrls.length));
//   });

//   test('the default set is registrable: threshold fits the operator count', () {
//     expect(kPomDefaultThreshold, lessThanOrEqualTo(kPomDefaultOperatorUrls.length));
//     // A 1-of-n split would hand any single operator the whole key.
//     expect(kPomDefaultThreshold, greaterThanOrEqualTo(2));
//   });
// }
