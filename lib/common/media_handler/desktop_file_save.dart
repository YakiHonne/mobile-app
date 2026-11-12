import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

/// Saves bytes at a user-selected location; returns false when cancelled.
Future<bool> saveDesktopFileBytes({
  required String suggestedName,
  required Uint8List bytes,
}) async {
  final location = await FileSelectorPlatform.instance.getSaveLocation(
    options: SaveDialogOptions(suggestedName: suggestedName),
  );
  if (location == null) {
    return false;
  }
  await File(location.path).writeAsBytes(bytes);
  return true;
}
