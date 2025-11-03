import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/common_regex.dart';
import '../../common/media_handler/media_handler.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'profile_settings_state.dart';

class ProfileSettingsCubit extends Cubit<ProfileSettingsState> {
  ProfileSettingsCubit()
      : super(
          ProfileSettingsState(
            imageLink: nostrRepository.currentMetadata.picture,
            description: nostrRepository.currentMetadata.about,
            name: nostrRepository.currentMetadata.name,
            displayName: nostrRepository.currentMetadata.displayName,
            website: nostrRepository.currentMetadata.website,
            bannerLink: nostrRepository.currentMetadata.banner,
            pubkey: nostrRepository.currentMetadata.pubkey,
            isUploading: false,
            lud16: nostrRepository.currentMetadata.lud16,
            lud6:
                Zap.getLnurlFromLud16(nostrRepository.currentMetadata.lud16) ??
                    '',
            nip05: nostrRepository.currentMetadata.nip05,
            refresh: false,
          ),
        );

  Future<void> updateMetadata({
    required Map<String, String> data,
    required Function(String) onFailure,
    required Function(String) onSuccess,
  }) async {
    final cancel = BotToast.showLoading();

    try {
      String lud16 = data['lud16'] ?? '';
      String lud06 = '';

      if (lud16.isNotEmpty) {
        if (emailRegExp.hasMatch(lud16)) {
          final l06 = Zap.getLnurlFromLud16(lud16);
          if (l06 == null) {
            onFailure.call(t.submitValidLud.capitalizeFirst());
            cancel.call();
            return;
          } else {
            lud06 = l06;
          }
        } else if (lud16.toLowerCase().startsWith('lnurl')) {
          final l16 = Zap.getLud16FromLud06(lud16);

          if (l16 != null) {
            lud16 = l16;
          } else {
            onFailure.call(t.submitValidLud.capitalizeFirst());
            cancel.call();
            return;
          }
        } else {
          onFailure.call(t.submitValidLud.capitalizeFirst());
          cancel.call();
          return;
        }
      }

      final metadata = nostrRepository.currentMetadata.copyWith(
        nip05: data['nip05'],
        name: data['name'],
        displayName: data['displayName'],
        about: data['about'],
        lud16: lud16,
        lud06: lud06,
        banner: data['banner'],
        website: data['website'],
        picture: data['picture'],
      );

      final kind0Event = await Event.genEvent(
        content: metadata.toJson(),
        kind: 0,
        signer: currentSigner,
        tags: [],
      );

      if (kind0Event == null) {
        cancel.call();
        return;
      }

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: kind0Event,
        relays: currentUserRelayList.urls.toList(),
        setProgress: true,
      );

      if (isSuccessful) {
        onSuccess.call(t.updatedSuccesfuly.capitalizeFirst());

        sendPointsActions(data);

        nostrRepository.currentMetadata = Metadata.fromEvent(kind0Event)!;
        nostrRepository.setCurrentSignerState(currentSigner);
        metadataCubit.saveMetadata(nostrRepository.currentMetadata);

        setCurrentMetadata();
      } else {
        onFailure.call(t.errorUpdatingData.capitalizeFirst());
      }

      cancel.call();
    } catch (e, stack) {
      lg.i(stack);
      cancel.call();
      onFailure.call(t.errorUpdatingData.capitalizeFirst());
    }
  }

  Future<void> sendPointsActions(Map<String, String> data) async {
    final lud16Points = data['nip05'] != nostrRepository.currentMetadata.lud16;
    final nip05Points = data['nip05'] != nostrRepository.currentMetadata.nip05;
    final namePoints = data['name'] != nostrRepository.currentMetadata.name;
    final displayPoints =
        data['displayName'] != nostrRepository.currentMetadata.displayName;
    final aboutPoints = data['about'] != nostrRepository.currentMetadata.about;
    final picturePoints =
        data['picture'] != nostrRepository.currentMetadata.picture;
    final bannerPoints =
        data['banner'] != nostrRepository.currentMetadata.banner;

    if (nip05Points) {
      await HttpFunctionsRepository.sendAction(PointsActions.NIP05);
    }

    if (lud16Points) {
      await HttpFunctionsRepository.sendAction(PointsActions.LUDS);
    }

    if (namePoints || displayPoints) {
      await HttpFunctionsRepository.sendAction(PointsActions.USERNAME);
    }

    if (aboutPoints) {
      await HttpFunctionsRepository.sendAction(PointsActions.BIO);
    }

    if (picturePoints) {
      await HttpFunctionsRepository.sendAction(PointsActions.PROFILE_PICTURE);
    }

    if (bannerPoints) {
      await HttpFunctionsRepository.sendAction(PointsActions.COVER);
    }
  }

  void setCurrentMetadata() {
    if (!isClosed) {
      emit(
        state.copyWith(
          imageLink: nostrRepository.currentMetadata.picture,
          description: nostrRepository.currentMetadata.about,
          name: nostrRepository.currentMetadata.name,
          displayName: nostrRepository.currentMetadata.displayName,
          website: nostrRepository.currentMetadata.website,
          bannerLink: nostrRepository.currentMetadata.banner,
          pubkey: nostrRepository.currentMetadata.pubkey,
          isUploading: false,
          lud16: nostrRepository.currentMetadata.lud16,
          lud6: Zap.getLnurlFromLud16(nostrRepository.currentMetadata.lud16) ??
              '',
          nip05: nostrRepository.currentMetadata.nip05,
          refresh: !state.refresh,
        ),
      );
    }
  }

  void deleteBanner() {
    if (!isClosed) {
      emit(
        state.copyWith(bannerLink: ''),
      );
    }
  }

  Future<void> setMetadataMedia(bool isPicture) async {
    final media = await MediaHandler.selectMedia(MediaType.image);

    if (media != null) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isUploading: true,
          ),
        );
      }

      try {
        final picture = (await mediaServersCubit.uploadMedia(
              file: media,
            ))['url'] ??
            '';

        if (picture.isNotEmpty) {
          if (!isClosed) {
            emit(
              state.copyWith(
                imageLink: isPicture ? picture : state.imageLink,
                bannerLink: !isPicture ? picture : state.bannerLink,
              ),
            );
          }
        } else {
          BotToastUtils.showError(
            t.errorUploadingImage.capitalizeFirst(),
          );
        }
      } catch (_) {
        BotToastUtils.showError(
          t.errorUploadingImage.capitalizeFirst(),
        );
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            isUploading: false,
          ),
        );
      }
    }
  }
}
