import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/views/widgets/media_components/picture_view.dart';

void main() {
  testWidgets('description measurement follows local width and text scale',
      (tester) async {
    const text =
        'A picture description with enough words to wrap across lines.';
    const style = TextStyle(fontSize: 16);
    bool exceeds(double width, double scale) =>
        pictureDescriptionExceedsTwoLines(
          content: text,
          style: style,
          width: width,
          textScaler: TextScaler.linear(scale),
        );

    expect(exceeds(1000, 1), isFalse);
    expect(exceeds(140, 1), isTrue);
    expect(exceeds(650, 1), isFalse);
    expect(exceeds(650, 2), isTrue);
    expect(exceeds(1000, 1), isFalse);
  });

  testWidgets('measurement handles RTL text and narrow constraints',
      (tester) async {
    const text = 'هذه صورة تحتوي على وصف طويل لاختبار التفاف النص داخل اللوحة';
    bool exceeds(double width) => pictureDescriptionExceedsTwoLines(
          content: text,
          style: const TextStyle(fontSize: 16),
          width: width,
          textScaler: TextScaler.noScaling,
        );
    expect(exceeds(1000), isFalse);
    expect(exceeds(100), isTrue);
    expect(exceeds(0), isTrue);
  });
}
