import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

class MediaHandler {
  MediaHandler._();

  static Future<String?> uploadMediaFileFromData(String data) async {
    final directory = await getTemporaryDirectory();

    final filePath = '${directory.path}/${uuid.v4()}';

    final file = File(filePath);
    final uintFile = decodeBase64(data);

    if (uintFile == null) {
      return null;
    }

    await file.writeAsBytes(uintFile);

    return uploadMedia(file);
  }

  static Future<String?> uploadMedia(File media) async {
    try {
      BotToastUtils.showInformation(gc.t.uploadingImage);

      final cancel = BotToast.showLoading();
      final res = (await mediaServersCubit.uploadMedia(file: media))['url'];
      cancel.call();
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<File?> selectMedia(MediaType mediaType) async {
    try {
      final XFile? media;

      if (mediaType == MediaType.gallery) {
        media = await ImagePicker().pickMedia();
      } else if (mediaType == MediaType.cameraImage) {
        media = await ImagePicker().pickImage(source: ImageSource.camera);
      } else if (mediaType == MediaType.cameraVideo) {
        media = await ImagePicker().pickVideo(source: ImageSource.camera);
      } else if (mediaType == MediaType.image) {
        media = await ImagePicker().pickImage(source: ImageSource.gallery);
      } else {
        media = await ImagePicker().pickVideo(source: ImageSource.gallery);
      }

      if (media != null) {
        return File(media.path);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<List<File>> selectMultiMedia() async {
    try {
      final selectedMedias = <File>[];
      final medias = await ImagePicker().pickMultipleMedia();

      if (medias.isNotEmpty) {
        for (final m in medias) {
          selectedMedias.add(File(m.path));
        }

        return selectedMedias;
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  static Future<String?> selectMediaAndUpload(MediaType mediaType) async {
    final cancel = BotToast.showLoading();

    final media = await selectMedia(mediaType);

    if (media != null) {
      final res = (await mediaServersCubit.uploadMedia(file: media))['url'];
      cancel.call();
      return res;
    } else {
      cancel.call();
      return null;
    }
  }

  static Future<List<String>> selectMultiMediaAndUpload() async {
    final cancel = BotToast.showLoading();

    final medias = await selectMultiMedia();

    if (medias.isEmpty) {
      BotToastUtils.showError(t.errorUploadingMedia);
      cancel.call();
      return [];
    }

    final res = await Future.wait(
      [for (final m in medias) mediaServersCubit.uploadMedia(file: m)],
    );

    final urls = <String>[];
    for (final u in res) {
      if (u.isNotEmpty) {
        urls.add(u['url'] ?? '');
      }
    }

    if (urls.isNotEmpty) {
      cancel.call();
      return urls;
    } else {
      cancel.call();
      BotToastUtils.showError(t.errorUploadingMedia);
      return [];
    }
  }
}

/// Utility class for media operations
class MediaUtils {
  static Future<void> shareImage(String link) async {
    try {
      final response = await Dio().get(
        link,
        options: Options(responseType: ResponseType.bytes),
      );

      final mimeType = _getMimeType(link, response);
      final image = XFile.fromData(
        response.data,
        mimeType: mimeType,
        name: "YakiHonne's image",
      );

      await Share.shareXFiles(
        [image],
        subject: "Share YakiHonne's content with the others",
      );
    } catch (e) {
      BotToastUtils.showError(t.errorSharingMedia);
    }
  }

  static Future<void> copyImageToClipboard(String link) async {
    final ctx = nostrRepository.mainCubit.context;

    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        BotToastUtils.showError(ctx.t.errorCopyImage);
        return;
      }

      final response = await Dio().get(
        link,
        options: Options(responseType: ResponseType.bytes),
      );

      final mimeType = _getMimeType(link, response)?.split('/').last;
      if (mimeType == null) {
        return;
      }

      final item = DataWriterItem();
      final success = _addImageToClipboard(item, mimeType, response.data);

      if (success) {
        await clipboard.write([item]);
        if (ctx.mounted) {
          BotToastUtils.showSuccess(ctx.t.copyImageGallery);
        }
      } else {
        if (ctx.mounted) {
          BotToastUtils.showError(ctx.t.errorCopyImage);
        }
      }
    } catch (e) {
      debugPrint('Error copying image: $e');
      if (ctx.mounted) {
        BotToastUtils.showError(ctx.t.errorCopyImage);
      }
    }
  }

  static String? _getMimeType(String link, Response response) {
    final extension = link.split('.').last.toLowerCase();

    if (isImageExtension(extension)) {
      return extension == 'jpg' ? 'image/jpeg' : 'image/$extension';
    }

    return response.headers['content-type']?.first;
  }

  static bool _addImageToClipboard(
    DataWriterItem item,
    String mimeType,
    dynamic data,
  ) {
    switch (mimeType.toLowerCase()) {
      case 'png':
        item.add(Formats.png.lazy(() => data));
        return true;
      case 'jpg':
      case 'jpeg':
        item.add(Formats.jpeg.lazy(() => data));
        return true;
      case 'gif':
        item.add(Formats.gif.lazy(() => data));
        return true;
      case 'webp':
        item.add(Formats.webp.lazy(() => data));
        return true;
      case 'tiff':
        item.add(Formats.tiff.lazy(() => data));
        return true;
      case 'bmp':
        item.add(Formats.bmp.lazy(() => data));
        return true;
      default:
        return false;
    }
  }
}
