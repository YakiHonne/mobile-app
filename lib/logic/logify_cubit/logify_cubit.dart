// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:amberflutter/amberflutter.dart' as amb;
import 'package:bip340/bip340.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/remote_event_signer.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/media_handler/media_handler.dart';
import '../../initializers.dart';
import '../../models/app_models/interests_set.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../../views/widgets/response_snackbar.dart';

part 'logify_state.dart';

class LogifyCubit extends Cubit<LogifyState> {
  LogifyCubit()
      : super(
          LogifyState(
            about: '',
            interests: const [],
            name: '',
            private: Keychain.generate().private,
            pubkeys: const {},
            refresh: false,
            isSettingAccount: false,
            includeWallet: true,
            wallet: '',
            lightningAddress: '',
          ),
        );

  RemoteEventSigner? remoteSigner;
  RemoteEventSigner? tempNC;
  RemoteEventSigner? tempB;
  String? remoteSignerSubscriptionId;
  bool isFetchingPubkey = false;
  bool isLoggingIn = false;

  Future<void> login({
    required String key,
    required bool newKey,
    required Function() onSuccess,
    required bool isExternalSigner,
    ExternalKeyType externalKeyType = ExternalKeyType.Bunker,
  }) async {
    try {
      String hex = '';
      bool isPrivKey = false;

      if (!isExternalSigner) {
        if (key.startsWith('nsec')) {
          try {
            hex = Nip19.decodePrivkey(key.trim());
            isPrivKey = true;
          } catch (_) {}

          if (hex.isEmpty) {
            BotToastUtils.showError(
              t.invalidPrivateKey.capitalizeFirst(),
            );
            return;
          }
        } else if (key.startsWith('npub')) {
          try {
            hex = Nip19.decodePubkey(key.trim());
            isPrivKey = false;
          } catch (_) {}

          if (hex.isEmpty) {
            BotToastUtils.showError(
              t.invalidPrivateKey.capitalizeFirst(),
            );
            return;
          }
        } else if (key.length == 64) {
          hex = key;
          isPrivKey = true;
        } else {
          BotToastUtils.showError(
            t.invalidHexKey.capitalizeFirst(),
          );
          return;
        }
      } else {
        hex = key;
      }

      final metadata = await metadataCubit.getFutureMetadata(
        isPrivKey ? getPublicKey(hex) : hex,
        forceTimeout: true,
      );

      if ((metadata?.isDeleted ?? false) && gc.mounted) {
        showCupertinoAccountDeletedDialogue(
          context: nostrRepository.currentContext(),
          onClicked: () {
            YNavigator.pop(nostrRepository.currentContext());
          },
        );

        return;
      }

      await settingsCubit.addAndChangeKey(
        hex,
        isPrivKey,
        isExternalSigner,
        fetchData: true,
        externalKeyType: externalKeyType,
        remoteSigner: remoteSigner,
      );

      await initRelayManager(!isPrivKey ? key : getPublicKey(hex), newKey);

      onSuccess.call();
    } catch (e, stack) {
      lg.i(stack);
    }
  }

  void setIncludeWallet(bool? status) {
    emit(
      state.copyWith(
        includeWallet: status,
      ),
    );
  }

  Future<void> initRelayManager(String publicKey, bool newKey) async {
    BotToastUtils.showWarning(
      t.relayingStuff.capitalizeFirst(),
    );
    nostrRepository.setCurrentAppCustomizationFromCache(broadcast: true);
    nostrRepository.setCurrentUserDraft();

    final c = BotToastUtils.showLoading();

    currentUserRelayList = UserRelayList(
      pubkey: currentSigner?.getPublicKey() ?? '',
      relays: {
        for (final url in DEFAULT_BOOTSTRAP_RELAYS)
          url: ReadWriteMarker.readWrite
      },
      createdAt: Helpers.now,
      refreshedTimestamp: Helpers.now,
    );

    AppInitializer.initRelays(newKey: newKey);

    await Future.delayed(const Duration(seconds: 2)).then(
      (value) {
        nostrRepository.loadCurrentUserRelatedData();
      },
    );

    settingsCubit.saveAndUpdate();

    c.call();
  }

  Future<void> loginWithAmber({
    required Function() onSuccess,
  }) async {
    final amber = amb.Amberflutter();

    final bool isInstalled = await amber.isAppInstalled();

    if (!isInstalled) {
      BotToastUtils.showError(
        t.amberNotInstalled.capitalizeFirst(),
      );
      return;
    }

    try {
      Map? val;

      try {
        val = await amber.getPublicKey(
          permissions: [
            const amb.Permission(type: 'sign_event'),
            const amb.Permission(type: 'nip04_encrypt'),
            const amb.Permission(type: 'nip04_decrypt'),
            const amb.Permission(type: 'nip44_encrypt'),
            const amb.Permission(type: 'nip44_decrypt'),
          ],
        );
      } catch (e) {
        lg.i(e);
      }

      if (val == null) {
        BotToastUtils.showSuccess(
          t.errorAmber.capitalizeFirst(),
        );

        return;
      }

      final pubkeyRaw = val['signature'];

      if (pubkeyRaw != null && (pubkeyRaw as String).isNotEmpty) {
        final pubkey = pubkeyRaw.startsWith('npub1')
            ? Nip19.decodePubkey(pubkeyRaw)
            : pubkeyRaw;

        if (settingsCubit.keyMap.values.contains(pubkey)) {
          BotToastUtils.showWarning(
            t.alreadyLoggedIn.capitalizeFirst(),
          );

          onSuccess.call();
          return;
        }

        login(
          key: pubkey,
          newKey: true,
          onSuccess: () {},
          isExternalSigner: true,
          externalKeyType: ExternalKeyType.Amber,
        );

        BotToastUtils.showSuccess(
          t.loggedIn.capitalizeFirst(),
        );

        onSuccess.call();
      } else {
        BotToastUtils.showError(
          t.attemptConnectAmber.capitalizeFirst(),
        );
      }
    } catch (e) {
      lg.i(e);
    }
  }

  Future<void> selectMetadataMedia(bool isPicture) async {
    final media = await MediaHandler.selectMedia(MediaType.image);

    if (media != null) {
      if (!isClosed) {
        emit(
          state.copyWith(
            picture: isPicture ? media : state.picture,
            cover: !isPicture ? media : state.cover,
            refresh: !state.refresh,
          ),
        );
      }
    }
  }

  void setPersonalInformation({required String text, required bool isName}) {
    if (!isClosed) {
      emit(
        state.copyWith(
          about: !isName ? text : null,
          name: isName ? text : null,
        ),
      );
    }
  }

  void setPubkey(String pubkey) {
    final pubkeys = Set<String>.from(state.pubkeys);

    if (pubkeys.contains(pubkey)) {
      pubkeys.remove(pubkey);
    } else {
      pubkeys.add(pubkey);
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          pubkeys: pubkeys,
        ),
      );
    }
  }

  void setListPubkeys({required Set<String> pkeys, required bool isDelete}) {
    final pubkeys = Set<String>.from(state.pubkeys);

    if (isDelete) {
      pubkeys.removeWhere(
        (p) => pkeys.contains(p),
      );
    } else {
      pubkeys.addAll(pkeys);
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          pubkeys: pubkeys,
        ),
      );
    }
  }

  Future<void> createWallet({
    required String name,
    required Function(String, String) onSuccess,
    required Function() onNameFailure,
  }) async {
    try {
      final data = await HttpFunctionsRepository.post(walletsUrl, {
        'username': name,
      });

      if (data != null) {
        final la = data['lightningAddress'].toString();
        final wallet = data['connectionSecret'].toString();

        if (!isClosed) {
          emit(
            state.copyWith(
              lightningAddress: la,
              wallet: wallet,
            ),
          );
        }

        onSuccess.call(la, wallet);
      } else {
        BotToastUtils.showError(
          t.errorCreatingWallet.capitalizeFirst(),
        );
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.badResponse) {
        onNameFailure.call();
        return;
      }

      BotToastUtils.showError(
        t.errorCreatingWallet.capitalizeFirst(),
      );
    }
  }

  Future<void> setupAccount({
    required Function() onSuccess,
  }) async {
    String picture = '';
    String banner = '';

    final lud16 = state.includeWallet ? state.lightningAddress : '';
    final lud06 = state.includeWallet
        ? Zap.getLud16LinkFromLud16(state.lightningAddress) ?? ''
        : '';

    if (!isClosed) {
      emit(state.copyWith(isSettingAccount: true));
    }

    if (state.picture != null) {
      try {
        picture = (await mediaServersCubit.uploadMedia(
              file: state.picture!,
            ))['url'] ??
            '';
      } catch (_) {
        BotToastUtils.showError(
          t.errorUploadingImage.capitalizeFirst(),
        );
        if (!isClosed) {
          emit(state.copyWith(isSettingAccount: false));
        }
        return;
      }
    }

    if (state.cover != null) {
      try {
        banner = (await mediaServersCubit.uploadMedia(
              file: state.cover!,
            ))['url'] ??
            '';
      } catch (_) {
        if (!isClosed) {
          emit(state.copyWith(isSettingAccount: false));
        }
        BotToastUtils.showError(
          t.errorUploadingImage.capitalizeFirst(),
        );
        return;
      }
    }

    await settingsCubit.addAndChangeKey(state.private, true, false);
    nostrRepository.setCurrentAppCustomizationFromCache(broadcast: true);
    nostrRepository.setCurrentUserDraft();

    walletManagerCubit.switchWallets();

    if (state.wallet.isNotEmpty) {
      walletManagerCubit.addNwc(state.wallet);
    }

    late Event metadataEvent;
    late Event contactListEvent;
    late Event relaySetEvent;
    Event? interestSetEvent;
    final interetags = <String>{};

    metadataEvent = (await Event.genEvent(
      kind: EventKind.METADATA,
      signer: currentSigner,
      tags: [],
      content: Metadata.empty()
          .copyWith(
            about: state.about,
            name: state.name,
            displayName: state.name,
            lud16: lud16,
            lud06: lud06,
            picture: picture,
            banner: banner,
          )
          .toJson(),
    ))!;

    contactListEvent = (await Event.genEvent(
      kind: EventKind.CONTACT_LIST,
      signer: currentSigner,
      tags: [
        if (state.pubkeys.isNotEmpty)
          for (final p in state.pubkeys) ['p', p]
        else
          ['p', yakihonneHex],
      ],
      content: '',
    ))!;

    relaySetEvent = (await Event.genEvent(
      kind: EventKind.RELAY_LIST_METADATA,
      signer: currentSigner,
      tags: [
        for (final r in DEFAULT_BOOTSTRAP_RELAYS) ['r', r],
      ],
      content: '',
    ))!;

    if (state.pubkeys.isNotEmpty) {
      final tags = <String>[];
      final interests = InterestSet.getInterestSets();

      for (final set in interests) {
        if (set.pubkeys.intersection(state.pubkeys).isNotEmpty) {
          tags.add(set.interest);
        }
      }

      interetags.addAll(
        tags
            .map(
              (e) => e.toLowerCase(),
            )
            .toSet(),
      );

      interestSetEvent = await Event.genEvent(
        kind: EventKind.INTEREST_SET,
        signer: currentSigner,
        tags: [
          for (final t in interetags) ['t', t],
        ],
        content: '',
      );
    }

    try {
      await Future.wait([
        NostrFunctionsRepository.sendEvent(
          event: metadataEvent,
          setProgress: false,
          relays: DEFAULT_BOOTSTRAP_RELAYS,
        ),
        NostrFunctionsRepository.sendEvent(
          event: contactListEvent,
          setProgress: false,
          relays: DEFAULT_BOOTSTRAP_RELAYS,
        ),
        NostrFunctionsRepository.sendEvent(
          event: relaySetEvent,
          setProgress: false,
          relays: DEFAULT_BOOTSTRAP_RELAYS,
        ),
        if (interestSetEvent != null)
          NostrFunctionsRepository.sendEvent(
            event: interestSetEvent,
            setProgress: false,
            relays: DEFAULT_BOOTSTRAP_RELAYS,
          ),
      ]);

      metadataCubit.saveMetadata(Metadata.fromEvent(metadataEvent)!);
      contactListCubit.saveContactList(ContactList.fromEvent(contactListEvent));
      await nc.db.saveUserRelayList(
        UserRelayList.fromNip65(Nip65.fromEvent(relaySetEvent)),
      );

      if (interestSetEvent != null) {
        nostrRepository.setInterestSet(interetags);
        await nc.db.saveEvent(interestSetEvent);
      }

      onSuccess.call();

      AppInitializer.initRelays();
      if (!isClosed) {
        emit(state.copyWith(isSettingAccount: false));
      }
    } catch (e) {
      lg.i(e);
      if (!isClosed) {
        emit(state.copyWith(isSettingAccount: false));
      }
      return;
    }
  }

  Future<void> setupDirectAccount({
    required String walletName,
    required Function() onNameFailure,
    required Function() onSuccess,
  }) async {
    if (!isClosed) {
      emit(state.copyWith(isSettingAccount: true));
    }

    if (walletName.isNotEmpty) {
      bool isSuccessful = true;

      await createWallet(
        name: walletName,
        onSuccess: (l, w) {},
        onNameFailure: () {
          onNameFailure.call();
          isSuccessful = false;
        },
      );

      if (!isSuccessful) {
        if (!isClosed) {
          emit(state.copyWith(isSettingAccount: false));
        }

        return;
      }
    }

    String picture = '';
    String banner = '';

    final lud16 = state.includeWallet ? state.lightningAddress : '';
    final lud06 = state.includeWallet
        ? Zap.getLud16LinkFromLud16(state.lightningAddress) ?? ''
        : '';

    if (!isClosed) {
      emit(state.copyWith(isSettingAccount: true));
    }

    if (state.picture != null) {
      try {
        picture = (await mediaServersCubit.uploadMedia(
              file: state.picture!,
            ))['url'] ??
            '';
      } catch (_) {
        BotToastUtils.showError(
          t.errorUploadingImage.capitalizeFirst(),
        );
        if (!isClosed) {
          emit(state.copyWith(isSettingAccount: false));
        }
        return;
      }
    }

    if (state.cover != null) {
      try {
        banner = (await mediaServersCubit.uploadMedia(
              file: state.cover!,
            ))['url'] ??
            '';
      } catch (_) {
        if (!isClosed) {
          emit(state.copyWith(isSettingAccount: false));
        }
        BotToastUtils.showError(
          t.errorUploadingImage.capitalizeFirst(),
        );
        return;
      }
    }

    await settingsCubit.addAndChangeKey(state.private, true, false);
    nostrRepository.setCurrentAppCustomizationFromCache(broadcast: true);
    nostrRepository.setCurrentUserDraft();

    walletManagerCubit.switchWallets();

    if (state.wallet.isNotEmpty) {
      walletManagerCubit.addNwc(state.wallet);
    }

    late Event metadataEvent;
    late Event relaySetEvent;

    metadataEvent = (await Event.genEvent(
      kind: EventKind.METADATA,
      signer: currentSigner,
      tags: [],
      content: Metadata.empty()
          .copyWith(
            about: state.about,
            name: state.name,
            displayName: state.name,
            lud16: lud16,
            lud06: lud06,
            picture: picture,
            banner: banner,
          )
          .toJson(),
    ))!;

    relaySetEvent = (await Event.genEvent(
      kind: EventKind.RELAY_LIST_METADATA,
      signer: currentSigner,
      tags: [
        for (final r in DEFAULT_BOOTSTRAP_RELAYS) ['r', r],
      ],
      content: '',
    ))!;

    try {
      await Future.wait([
        NostrFunctionsRepository.sendEvent(
          event: metadataEvent,
          setProgress: false,
          relays: DEFAULT_BOOTSTRAP_RELAYS,
        ),
        NostrFunctionsRepository.sendEvent(
          event: relaySetEvent,
          setProgress: false,
          relays: DEFAULT_BOOTSTRAP_RELAYS,
        ),
      ]);

      metadataCubit.saveMetadata(Metadata.fromEvent(metadataEvent)!);
      await nc.db.saveUserRelayList(
        UserRelayList.fromNip65(Nip65.fromEvent(relaySetEvent)),
      );

      onSuccess.call();

      AppInitializer.initRelays();
      if (!isClosed) {
        emit(state.copyWith(isSettingAccount: false));
      }
    } catch (e) {
      lg.i(e);
      if (!isClosed) {
        emit(state.copyWith(isSettingAccount: false));
      }
      return;
    }
  }

  // REMOTE SIGNER
  Future<String> initRemoteSignerFromNostrConnect({
    required Function() onSuccess,
    required BuildContext context,
  }) async {
    final completer = Completer<String>();

    getNostrConnectSigner(
      onSuccess: onSuccess,
      onConnectionUrlReady: (url) {
        completer.complete(url);
      },
    );

    return completer.future;
  }

  Future<void> getNostrConnectSigner({
    required Function() onSuccess,
    required Function(String) onConnectionUrlReady,
  }) async {
    final signer = await RemoteEventSigner.fromURI(
      onConnectionUrlReady: onConnectionUrlReady,
      onAuth: (url, p1) => launchRemoteSignerAuth(
        url: url,
      ),
      nc: nc,
    );

    if (signer != null) {
      await signer.getPublicKeyAsync();
      loadRemotePubkeyAndLogin(remoteSigner: signer, onSuccess: onSuccess);
    }
  }

  Future<void> initRemoteSignerFromBunkerUrl({
    required String bunkerUrl,
    required Function() onSuccess,
    required BuildContext context,
  }) async {
    final bunkerPointer = RemoteEventSigner.parseBunkerInput(bunkerUrl);

    if (bunkerPointer == null) {
      BotToastUtils.showError('Invalid bunker URL');
      return;
    }

    final keys = Keychain.generate();

    final signer = await RemoteEventSigner.fromBunker(
      keys.private,
      bunkerPointer,
      onAuth: (url, p1) => launchRemoteSignerAuth(
        url: url,
      ),
      nc: nc,
    );

    if (signer != null) {
      await signer.getPublicKeyAsync();
      loadRemotePubkeyAndLogin(remoteSigner: signer, onSuccess: onSuccess);
    }
  }

  Future<void> loadRemotePubkeyAndLogin({
    required RemoteEventSigner remoteSigner,
    required Function() onSuccess,
  }) async {
    final pubkey = remoteSigner.publicKey;
    remoteSigner.close();

    if (pubkey.isNotEmpty) {
      this.remoteSigner = remoteSigner;

      if (settingsCubit.keyMap.values.contains(pubkey)) {
        BotToastUtils.showWarning(
          t.alreadyLoggedIn.capitalizeFirst(),
        );

        onSuccess.call();
        return;
      }

      login(
        key: pubkey,
        newKey: true,
        onSuccess: () {},
        isExternalSigner: true,
      );

      BotToastUtils.showSuccess(
        t.loggedIn.capitalizeFirst(),
      );

      onSuccess.call();
    }
  }

  void offloadRemoteSigner() {
    remoteSigner = null;
    tempNC = null;
    tempB = null;

    isFetchingPubkey = false;
    isLoggingIn = false;
  }
}
