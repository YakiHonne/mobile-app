import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'utils.dart';

class VideoUtils {
  static final _thumbnailFileCache = <String, String>{};

  static String? getVideoThumbnailImageFromMem({
    String? videoURL,
    String? cacheKey,
  }) {
    if (videoURL != null) {
      cacheKey ??= _thumbnailSnapshotURL(videoURL);
    }
    if (cacheKey == null) {
      return null;
    }

    final memUrl = _thumbnailFileCache[cacheKey];

    return memUrl;
  }

  static void putVideoThumbnailImageToMem({
    String? videoURL,
    String? cacheKey,
    String? memUrl,
  }) {
    if (videoURL != null) {
      cacheKey ??= _thumbnailSnapshotURL(videoURL);
    }

    if (cacheKey == null) {
      return;
    }

    if (memUrl != null) {
      _thumbnailFileCache[cacheKey] = memUrl;
    } else {
      _thumbnailFileCache.remove(cacheKey);
    }
  }

  static Future<String?> getVideoThumbnailImage({
    required String videoURL,
    required BuildContext context,
    bool onlyFromCache = false,
  }) async {
    if (Platform.isIOS || Platform.isAndroid) {
      return _getMobileVideoThumbnailImage(
          videoURL: videoURL, context: context, onlyFromCache: onlyFromCache);
    }
    try {
      String? memUrl;

      // Memory
      memUrl = getVideoThumbnailImageFromMem(videoURL: videoURL);
      if (memUrl != null) {
        return memUrl;
      }

      final thumbnailURL = _thumbnailSnapshotURL(videoURL);
      final thumbnailImageFile =
          (await imagesCacheManager.getFileFromCache(thumbnailURL))?.file;

      if (thumbnailImageFile != null && thumbnailImageFile.existsSync()) {
        putVideoThumbnailImageToMem(
          videoURL: videoURL,
          memUrl: thumbnailImageFile.path,
        );

        return thumbnailImageFile.path;
      }

      if (onlyFromCache) {
        return null;
      }

      // video_thumbnail has no desktop implementation.
      if (Platform.isLinux) {
        return null;
      }
      String? filePath;

      if (context.mounted) {
        final path = (await getTemporaryDirectory()).path;

        if (Platform.isMacOS || Platform.isWindows) {
          // Windows accepts local paths only; avoid passing remote URLs there.
          if (Platform.isWindows &&
              (Uri.tryParse(videoURL)?.hasScheme ?? false)) {
            return null;
          }
          final destination = '$path/${const Uuid().v1()}.jpeg';
          final created = await FcNativeVideoThumbnail().getVideoThumbnail(
            srcFile: videoURL,
            srcFileUri: Platform.isMacOS &&
                (Uri.tryParse(videoURL)?.hasScheme ?? false),
            destFile: destination,
            width: 1024,
            height: 1024,
            quality: 100,
          );
          filePath = created ? destination : null;
        } else {
          filePath = await VideoThumbnail.thumbnailFile(
            video: videoURL,
            thumbnailPath: path,
            quality: 100,
          );
        }
      }

      if (filePath == null) {
        return null;
      }

      final s = File(filePath);
      await _putFileToCache(thumbnailURL, s);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> _getMobileVideoThumbnailImage({
    required String videoURL,
    required BuildContext context,
    bool onlyFromCache = false,
  }) async {
    try {
      String? memUrl;

      // Memory
      memUrl = getVideoThumbnailImageFromMem(videoURL: videoURL);
      if (memUrl != null) {
        return memUrl;
      }

      final thumbnailURL = _thumbnailSnapshotURL(videoURL);
      final thumbnailImageFile =
          (await imagesCacheManager.getFileFromCache(thumbnailURL))?.file;

      if (onlyFromCache ||
          thumbnailImageFile != null && thumbnailImageFile.existsSync()) {
        putVideoThumbnailImageToMem(
          videoURL: videoURL,
          memUrl: thumbnailImageFile!.path,
        );

        return thumbnailImageFile.path;
      }

      // New Create
      final file = await imagesCacheManager.store.fileSystem.createFile(
        '${const Uuid().v1()}.jpeg',
      );

      file.createSync(recursive: true);
      String? filePath;

      if (context.mounted) {
        final path = (await getTemporaryDirectory()).path;

        filePath = await VideoThumbnail.thumbnailFile(
          video: videoURL,
          thumbnailPath: path,
          quality: 100,
        );
      }

      if (filePath == null) {
        return null;
      }

      final s = File(filePath);
      await _putFileToCache(thumbnailURL, s);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  static Future<File> putFileToCacheWithURL(String url, File file) async {
    if (!url.isRemoteURL) {
      throw Exception('url must be remote url');
    }
    final cacheKey = _thumbnailSnapshotURL(url);
    return _putFileToCache(cacheKey, file);
  }

  static Future<File> putFileToCacheWithFileId(String fileId, File file) async {
    final cacheKey = fileId;
    final bytes = file.readAsBytesSync();
    return imagesCacheManager.putFile(
      cacheKey,
      bytes,
      fileExtension: file.path.getFileExtension(),
    );
  }

  static Future<File> _putFileToCache(String cacheKey, File file) async {
    if (!file.existsSync()) {
      throw Exception('file is not exists');
    }
    // Put on store
    final bytes = file.readAsBytesSync();
    final cacheFile = await imagesCacheManager.putFile(
      cacheKey,
      bytes,
      fileExtension: file.path.getFileExtension(),
    );

    // Replace memory info & Delete origin file
    // final originCacheKey = _thumbnailFileCache.keys.where((key) {
    //   return _thumbnailFileCache[key]?.path == file.path;
    // });
    final updateCacheKey = [
      // ...originCacheKey,
      cacheKey,
    ];
    for (final key in updateCacheKey) {
      putVideoThumbnailImageToMem(cacheKey: key, memUrl: cacheFile.path);
    }
    // file.delete();

    return cacheFile;
  }

  static String _thumbnailSnapshotURL(String videoURL) {
    return '${videoURL}_yakiThumbnailSnapshot';
  }
}
