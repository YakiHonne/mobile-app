import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/models/dm_history_cursor.dart';

void main() {
  group('DmHistoryCursor', () {
    test('widens populated pages without gaps and preserves the live watermark',
        () {
      const cursor = DmHistoryCursor(
        until: 2000000000,
        intervalIndex: 0,
        liveSince: 1999000000,
      );

      final afterEvents = cursor.advance(pageHasEvents: true);
      expect(afterEvents.intervalIndex, 1);
      expect(afterEvents.until, cursor.since - 1);
      expect(afterEvents.since,
          afterEvents.until - const Duration(days: 14).inSeconds);
      expect(afterEvents.liveSince, cursor.liveSince);

      final afterEmpty = cursor.advance(pageHasEvents: false);
      expect(afterEmpty.intervalIndex, 1);
      expect(afterEmpty.until, cursor.since - 1);
      expect(afterEmpty.since,
          afterEmpty.until - const Duration(days: 14).inSeconds);
    });

    test('finishes after an empty page in the widest interval', () {
      const cursor = DmHistoryCursor(
        until: 2000000000,
        intervalIndex: 4,
        liveSince: 1999000000,
      );

      final complete = cursor.advance(pageHasEvents: false);

      expect(complete.isComplete, isTrue);
      expect(complete.liveSince, cursor.liveSince);
    });

    test('keeps using the widest interval while populated', () {
      const cursor = DmHistoryCursor(
        until: 2000000000,
        intervalIndex: 4,
        liveSince: 1999000000,
      );

      final next = cursor.advance(pageHasEvents: true);

      expect(next.isComplete, isFalse);
      expect(next.intervalIndex, 4);
      expect(next.until, cursor.since - 1);
    });
  });
}
