import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'utils.dart';

class VideoUtils {
  static final Map<String, File> _thumbnailFileCache = <String, File>{};

  static File? getVideoThumbnailImageFromMem({
    String? videoURL,
    String? cacheKey,
  }) {
    if (videoURL != null) {
      cacheKey ??= _thumbnailSnapshotURL(videoURL);
    }
    if (cacheKey == null) {
      return null;
    }

    final file = _thumbnailFileCache[cacheKey];
    if (file != null && !file.existsSync()) {
      return null;
    }

    return file;
  }

  static void putVideoThumbnailImageToMem({
    String? videoURL,
    String? cacheKey,
    File? file,
  }) {
    if (videoURL != null) {
      cacheKey ??= _thumbnailSnapshotURL(videoURL);
    }
    if (cacheKey == null) {
      return;
    }

    if (file != null && file.existsSync()) {
      _thumbnailFileCache[cacheKey] = file;
    } else {
      _thumbnailFileCache.remove(cacheKey);
    }
  }

  static Future<File?> getVideoThumbnailImage({
    required String videoURL,
    required BuildContext context,
    bool onlyFromCache = false,
  }) async {
    try {
      File? thumbnailImageFile;

      // Memory
      thumbnailImageFile = getVideoThumbnailImageFromMem(videoURL: videoURL);
      if (thumbnailImageFile != null) {
        return thumbnailImageFile;
      }

      final thumbnailURL = _thumbnailSnapshotURL(videoURL);
      thumbnailImageFile =
          (await imagesCacheManager.getFileFromCache(thumbnailURL))?.file;

      if (onlyFromCache ||
          thumbnailImageFile != null && thumbnailImageFile.existsSync()) {
        putVideoThumbnailImageToMem(
            videoURL: videoURL, file: thumbnailImageFile);
        return thumbnailImageFile;
      }

      // New Create
      final file = await imagesCacheManager.store.fileSystem.createFile(
        '${const Uuid().v1()}.jpeg',
      );

      file.createSync(recursive: true);
      bool filePath = false;

      if (context.mounted) {
        filePath = await FcNativeVideoThumbnail().getVideoThumbnail(
          srcFile: videoURL,
          destFile: file.path,
          width: (MediaQuery.of(context).size.width *
                  MediaQuery.of(context).devicePixelRatio)
              .toInt(),
          height: 100,
          format: 'jpeg',
          quality: 100,
        );
      }

      if (!filePath) {
        return null;
      }

      thumbnailImageFile = File(file.path);
      final cacheFile = await _putFileToCache(thumbnailURL, thumbnailImageFile);
      return cacheFile;
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
      putVideoThumbnailImageToMem(cacheKey: key, file: cacheFile);
    }
    // file.delete();

    return cacheFile;
  }

  static String _thumbnailSnapshotURL(String videoURL) {
    return '${videoURL}_yakiThumbnailSnapshot';
  }
}
