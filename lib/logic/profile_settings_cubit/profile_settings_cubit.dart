import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/common_regex.dart';
import '../../common/media_handler/media_handler.dart';
import '../../models/identity_models.dart';
import '../../models/wallet_model.dart';
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
            username: subscriptionCubit.state.subscriptionStatus?.username ?? '',
            // A claimed username is settled — the field renders read-only.
            usernameStatus:
                (subscriptionCubit.state.subscriptionStatus?.username ?? '')
                        .isNotEmpty
                    ? AddressStatus.alreadySet
                    : AddressStatus.unchecked,
            accountNip05:
                subscriptionCubit.state.subscriptionStatus?.nip05.name ?? '',
            accountNip05Active:
                subscriptionCubit.state.subscriptionStatus?.nip05.isActive ??
                    false,
          ),
        );

  static const _kDebounce = Duration(milliseconds: 500);

  Timer? _usernameDebounce;

  /// Guards against a slow response for an older value overwriting a newer one.
  int _usernameSeq = 0;

  /// What the user has typed into the Yaki username field but not yet claimed.
  /// Held here so the update-profile press can claim it — the field itself has
  /// no claim button.
  String _pendingUsername = '';

  /// Debounced availability check for the Yaki username field. A claimed
  /// username never re-checks — it cannot be changed.
  void onUsernameChanged(String value) {
    if (state.username.isNotEmpty) {
      return;
    }

    _usernameDebounce?.cancel();
    final name = value.trim();
    _pendingUsername = name;

    if (name.isEmpty || !isValidUsername(name)) {
      _usernameSeq++;
      _emit(
        state.copyWith(
          usernameStatus: AddressStatus.unchecked,
          // The chip renders nothing for `unchecked`, so without this an
          // illegal name would show no feedback at all and silently fail to
          // claim on update.
          identityError: name.isEmpty ? '' : t.onboarding_username_invalid,
        ),
      );
      return;
    }

    _emit(state.copyWith(usernameStatus: AddressStatus.checking));
    _usernameDebounce = Timer(_kDebounce, () => _checkUsername(name));
  }

  /// Runs the pending check immediately instead of waiting out the debounce.
  ///
  /// Pressing update within 500ms of typing would otherwise leave the row at
  /// `checking`, and the name would be silently dropped.
  Future<void> settleUsernameCheck() async {
    final pending = (_usernameDebounce?.isActive ?? false) ||
        state.usernameStatus == AddressStatus.checking;

    if (!pending) {
      return;
    }

    _usernameDebounce?.cancel();

    if (isValidUsername(_pendingUsername)) {
      await _checkUsername(_pendingUsername);
    }
  }

  Future<void> _checkUsername(String name) async {
    final seq = ++_usernameSeq;
    final result =
        await HttpFunctionsRepository.checkUsernameAvailability(name);

    if (seq != _usernameSeq) {
      return;
    }

    _emit(
      state.copyWith(
        usernameStatus: addressStatusOf(result),
        identityError:
            result.available || result.owned ? '' : result.reason ?? '',
      ),
    );
  }

  /// Claims the username on the account. Returns true on success, which is what
  /// flips the field to read-only. Does not touch kind-0 — a username is an
  /// account-level handle, not a profile field.
  Future<bool> claimUsername(String name) async {
    final trimmed = name.trim();

    if (state.isClaiming ||
        state.username.isNotEmpty ||
        !isValidUsername(trimmed)) {
      return false;
    }

    _emit(state.copyWith(isClaiming: true, identityError: ''));

    final reason = await HttpFunctionsRepository.claimUsername(trimmed);

    if (reason != null) {
      _emit(
        state.copyWith(
          isClaiming: false,
          usernameStatus: AddressStatus.taken,
          identityError: reason,
        ),
      );
      return false;
    }

    _emit(
      state.copyWith(
        isClaiming: false,
        username: trimmed,
        usernameStatus: AddressStatus.alreadySet,
      ),
    );

    // Pulls the claim back into subscription state so a second visit seeds from
    // it instead of offering the name again.
    unawaited(subscriptionCubit.refreshStatus());
    return true;
  }

  /// Publishes [nip05Address] to kind-0 and mirrors it into local state, so the
  /// sheet links the address immediately the way the Yaki Pro sheet does.
  ///
  /// The caller must also write the address into the NIP-05 controller. State
  /// and controller staying in sync is what stops a later "Update profile"
  /// press from reverting the address with a stale value.
  Future<bool> linkNip05ToProfile(String nip05Address) async {
    final metadata =
        nostrRepository.currentMetadata.copyWith(nip05: nip05Address);

    final kind0Event = await Event.genEvent(
      content: metadata.toJson(),
      kind: EventKind.METADATA,
      signer: currentSigner,
      tags: [],
    );

    if (kind0Event == null) {
      return false;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: kind0Event,
      relays: currentUserRelayList.urls.toList(),
      setProgress: false,
    );

    if (!isSuccessful) {
      return false;
    }

    nostrRepository.currentMetadata = Metadata.fromEvent(kind0Event)!;
    nostrRepository.setCurrentSignerState(currentSigner);
    await metadataCubit.saveMetadata(nostrRepository.currentMetadata);

    setCurrentMetadata();
    return true;
  }

  /// Claims `name@yakihonne.com` on the account. Returns the claimed address on
  /// success, null on failure. Claiming alone does not publish — the caller
  /// links it via [linkNip05ToProfile].
  Future<String?> claimAccountNip05(String name) async {
    final trimmed = name.trim();

    if (state.isClaiming || trimmed.isEmpty) {
      return null;
    }

    _emit(state.copyWith(isClaiming: true, identityError: ''));

    final reason = await HttpFunctionsRepository.claimNip05(
      name: trimmed,
      pubkey: state.pubkey.isNotEmpty
          ? state.pubkey
          : currentSigner?.getPublicKey() ?? '',
    );

    if (reason != null) {
      _emit(state.copyWith(isClaiming: false, identityError: reason));
      return null;
    }

    _emit(
      state.copyWith(
        isClaiming: false,
        accountNip05: trimmed,
        accountNip05Active: true,
      ),
    );

    unawaited(subscriptionCubit.refreshStatus());
    return '$trimmed@$kNip05Domain';
  }

  /// Lightning addresses from the user's connected NWC wallets, deduplicated.
  /// A wallet carrying no address is dropped — there is nothing to link.
  List<WalletModel> get walletAddresses {
    final seen = <String>{};

    return walletManagerCubit.state.wallets.values
        .where((w) =>
            w.kind == NostrWalletConnectKind &&
            w.lud16.isNotEmpty &&
            seen.add(w.lud16))
        .toList();
  }

  /// Drives the wallet picker button: no connected NWC wallet means there is
  /// nothing to pick from, so the button does not belong on screen.
  bool get hasWalletAddresses => walletAddresses.isNotEmpty;

  void _emit(ProfileSettingsState next) {
    if (!isClosed) {
      emit(next);
    }
  }

  @override
  Future<void> close() {
    _usernameDebounce?.cancel();
    return super.close();
  }

  Future<void> updateMetadata({
    required Map<String, String> data,
    required Function(String) onFailure,
    required Function(String) onSuccess,
  }) async {
    final cancel = BotToastUtils.showLoading();

    try {
      // The username field has no button of its own — an available name is
      // claimed here. Settle any in-flight check first: pressing update within
      // the debounce window would otherwise drop the name silently.
      await settleUsernameCheck();

      var usernameRefused = false;

      // Gated here too, not just in the UI: the row is hidden for a trial, so
      // a claim from one would mean stale state rather than a real intent.
      if ((subscriptionCubit.state.subscriptionStatus?.isActivePaidSub ??
              false) &&
          shouldClaimUsernameOnUpdate(
            claimed: state.username,
            pending: _pendingUsername,
            status: state.usernameStatus,
          )) {
        // A refusal must not block the metadata update — that is what the user
        // pressed for — but it must not be reported as success either.
        usernameRefused = !await claimUsername(_pendingUsername);
      }

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
        // The profile did save, so this is not a plain failure — but reporting
        // an unqualified success would hide a username that was refused.
        if (usernameRefused) {
          onFailure.call(
            state.identityError.isNotEmpty
                ? state.identityError
                : t.onboarding_claim_failed,
          );
        } else {
          onSuccess.call(t.updatedSuccesfuly.capitalizeFirst());
        }

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
