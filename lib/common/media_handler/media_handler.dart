// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

  static Future<Map<String, String>> uploadMediaWithData(
    File media, {
    String? message,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      return await mediaServersCubit.uploadMedia(
        file: media,
        onSendProgress: onSendProgress,
      );
    } catch (_) {
      return {};
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

  static Future<void> saveNetworkImage(String url) async {
    final response = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final ctx = nostrRepository.mainCubit.context;
    dynamic res;

    // Detect GIF based on extension or content type
    final isGif = url.toLowerCase().endsWith('.gif') ||
        (response.headers.value('content-type')?.contains('gif') ?? false);

    if (isGif) {
      // 🔹 Save GIF as a file (keeps animation)
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.gif';
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      // 🔹 This saves the file *into the Gallery*
      res = await ImageGallerySaverPlus.saveFile(file.path,
          isReturnPathOfIOS: true);
    } else {
      // 🔹 Normal static image (JPG/PNG)
      res = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        isReturnImagePathOfIOS: true,
      );
    }

    if (ctx.mounted) {
      if (res != null && res is Map && res['isSuccess']) {
        BotToastUtils.showSuccess(
          ctx.t.saveImageGallery.capitalizeFirst(),
        );
      } else {
        BotToastUtils.showSuccess(
          ctx.t.errorSavingImage.capitalizeFirst(),
        );
      }
    }
  }

  static Future<void> saveNetworkVideo(
    String url, {
    Function(double)? onProgress,
    bool showSuccessMessage = true,
  }) async {
    final ctx = nostrRepository.mainCubit.context;

    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.isNotEmpty ? pathSegments.last : 'video';
      final fileExtension =
          fileName.contains('.') ? '.${fileName.split('.').last}' : '.mp4';

      final appDocDir = await getTemporaryDirectory();
      final savePath =
          '${appDocDir.path}/${DateTime.now().millisecondsSinceEpoch}${fileExtension.toLowerCase()}';

      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (count, total) {
          onProgress?.call(count / total * 100);
        },
        // options: Options(responseType: ResponseType.bytes),
      );

      final res = await ImageGallerySaverPlus.saveFile(savePath);

      if (ctx.mounted) {
        if (res != null && res is Map && res['isSuccess']) {
          if (showSuccessMessage) {
            BotToastUtils.showSuccess(
              ctx.t.saveVideoGallery.capitalizeFirst(),
            );
          }
        } else {
          BotToastUtils.showSuccess(
            ctx.t.errorSavingVideo.capitalizeFirst(),
          );
        }
      }
    } catch (e) {
      BotToastUtils.showSuccess(
        ctx.t.errorSavingVideo.capitalizeFirst(),
      );
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
      final response = await Dio().get(
        link,
        options: Options(responseType: ResponseType.bytes),
      );

      final mimeType = _getMimeType(link, response);

      if (mimeType == null) {
        if (ctx.mounted) {
          BotToastUtils.showError(ctx.t.errorCopyImage);
        }
        return;
      }

      // Convert response data to Uint8List
      final imageBytes = response.data is Uint8List
          ? response.data
          : Uint8List.fromList(response.data);

      // Copy to clipboard
      await Pasteboard.writeImage(imageBytes);

      if (ctx.mounted) {
        BotToastUtils.showSuccess(ctx.t.copyImageGallery);
      }
    } catch (e) {
      lg.i('Error copying image: $e');
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
}
