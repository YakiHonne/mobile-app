import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/common/media_handler/desktop_file_save.dart';

class FakeFileSelector extends FileSelectorPlatform {
  FileSaveLocation? location;
  String? suggestedName;

  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async {
    suggestedName = options.suggestedName;
    return location;
  }
}

void main() {
  test('writes to the selected path and leaves cancellation untouched', () async {
    final original = FileSelectorPlatform.instance;
    final selector = FakeFileSelector();
    FileSelectorPlatform.instance = selector;
    final directory = await Directory.systemTemp.createTemp('yaki save ');
    addTearDown(() async {
      FileSelectorPlatform.instance = original;
      await directory.delete(recursive: true);
    });

    final target = File('${directory.path}/selected image.png');
    final bytes = Uint8List.fromList([1, 2, 3]);
    expect(await saveDesktopFileBytes(suggestedName: 'image.png', bytes: bytes),
        isFalse);
    expect(target.existsSync(), isFalse);
    selector.location = FileSaveLocation(target.path);
    expect(await saveDesktopFileBytes(suggestedName: 'image.png', bytes: bytes),
        isTrue);
    expect(selector.suggestedName, 'image.png');
    expect(await target.readAsBytes(), bytes);
    selector.location = FileSaveLocation(directory.path);
    await expectLater(
      saveDesktopFileBytes(suggestedName: 'image.png', bytes: bytes),
      throwsA(isA<FileSystemException>()),
    );
  });
}
