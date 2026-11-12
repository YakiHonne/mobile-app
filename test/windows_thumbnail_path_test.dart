import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/utils/video_utils.dart';

void main() {
  test('Windows thumbnail source distinguishes paths from URLs', () {
    expect(isWindowsThumbnailPath(r'C:\My Videos\clip.mp4'), isTrue);
    expect(isWindowsThumbnailPath('C:/My Videos/clip.mp4'), isTrue);
    expect(isWindowsThumbnailPath(r'\\server\media\clip.mp4'), isTrue);
    expect(isWindowsThumbnailPath('https://example.com/clip.mp4'), isFalse);
    expect(isWindowsThumbnailPath('file:///C:/clip.mp4'), isFalse);
  });
}
