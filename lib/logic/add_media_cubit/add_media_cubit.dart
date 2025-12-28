// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../common/common_regex.dart';
import '../../common/media_handler/media_handler.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'add_media_state.dart';

class AddMediaCubit extends Cubit<AddMediaState> {
  AddMediaCubit() : super(const AddMediaState());

  bool isPublishing = false;

  Future<void> addMedia({
    required File media,
    required bool isVideo,
    required String description,
    required String dimensions,
    required bool isSensitive,
    required String imageLink,
    required EventSigner signer,
    required Function(Event)? onSuccess,
  }) async {
    if (state.status != PublishMediaStatus.idle) {
      return;
    }

    emit(state.copyWith(status: PublishMediaStatus.uploading));

    try {
      final data = await MediaHandler.uploadMediaWithData(
        media,
        message: isVideo ? gc.t.uploadingVideo : gc.t.uploadingImage,
        onSendProgress: (int sent, int total) {
          emit(state.copyWith(progress: sent / total));
        },
      );

      if (data.isEmpty || data['url'] == null) {
        emit(state.copyWith(status: PublishMediaStatus.idle, progress: 0));
        BotToastUtils.showError(gc.t.errorUploadingMedia);
        return;
      }

      final url = data['url'];
      String? mimeType;
      String? blurhash;
      String? dim;
      String? duration;
      String? size;
      String? sha256;

      if (data['m'] != null) {
        mimeType = data['m'];
      }

      mimeType ??=
          '${isVideo ? 'video' : 'image'}/${media.path.split('.').last}';

      if (data['blurhash'] != null) {
        blurhash = data['blurhash'];
      }

      if (data['dim'] != null) {
        dim = data['dim'];
      }

      dim ??= dimensions;

      if (data['duration'] != null) {
        duration = data['duration'];
      }

      if (data['size'] != null) {
        size = data['size'];
      }

      if (data['x'] != null) {
        sha256 = data['x'];
      }

      final tags = hashtagsRegExp
          .allMatches(description)
          .map((match) => match.group(1)!.trim())
          .toList();

      final event = await Event.genEvent(
        content: description,
        kind: isVideo ? EventKind.VIDEO_VERTICAL : EventKind.PICTURE,
        signer: signer,
        tags: [
          getClientTag(),
          [
            'imeta',
            'url $url',
            if (isVideo && imageLink.isNotEmpty) 'image $imageLink',
            if (mimeType.isNotEmpty) 'm $mimeType',
            if (blurhash != null) 'blurhash $blurhash',
            if (dim.isNotEmpty) 'dim $dim',
            if (duration != null) 'duration $duration',
            if (size != null) 'size $size',
            if (sha256 != null) 'sha256 $sha256',
          ],
          if (mimeType.isNotEmpty) ['m', mimeType],
          if (tags.isNotEmpty) ...tags.map((tag) => ['t', tag]),
          if (isSensitive) ['L', 'content-warning'],
        ],
      );

      if (event == null) {
        emit(state.copyWith(status: PublishMediaStatus.idle, progress: 0));
        return;
      } else {
        emit(state.copyWith(status: PublishMediaStatus.publishing));
      }

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: false,
        relays: currentUserRelayList.writes,
      );

      if (isSuccessful) {
        onSuccess?.call(event);
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }
      emit(state.copyWith(status: PublishMediaStatus.idle, progress: 0));
    } catch (e, stack) {
      lg.i(stack);
      emit(state.copyWith(status: PublishMediaStatus.idle, progress: 0));
      BotToastUtils.showError(
        gc.t.errorUploadingMedia.capitalizeFirst(),
      );
    }
  }
}
