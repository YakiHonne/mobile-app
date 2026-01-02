import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  PropertiesCubit()
      : super(
          PropertiesState(
            refresh: false,
            propertiesViews: PropertiesViews.main,
            propertiesToggle: PropertiesToggle.none,
            relays: currentUserRelayList.urls.toList(),
            activeRelays: nc.currentUserActiveRelays(
              <String>{
                ...currentUserRelayList.urls,
                ...nostrRepository.dmRelays
              }.toList(),
            ),
            authPrivKey: '',
            isUsingSigner: nostrRepository.isUsingExternalSigner,
            isUsingNip44: nostrRepository.isUsingNip44,
            authPubKey: '',
            onlineRelays: const [],
            enableOneTapZap: nostrRepository.enableOneTapZap,
            enableAutomaticSigning:
                localDatabaseRepository.getAutomaticSigning(),
            enableGossip: settingsCubit.settingData.gossip ?? false,
            enableUsingExternalBrowser:
                settingsCubit.settingData.useExternalBrowser ?? true,
            enableOneTapReaction: nostrRepository.enableOneTapReaction,
            defaultReaction: canSign()
                ? nostrRepository
                        .defaultReactions[currentSigner!.getPublicKey()] ??
                    '+'
                : '+',
          ),
        ) {
    setKeys();
    setRelaysStatus();

    currentRelays = currentUserRelayList.urls.toList();
    lud16 = nostrRepository.currentMetadata.lud16;
    userSubcription = nostrRepository.currentSignerStream.listen(
      (user) {
        if (user == null) {
          if (!isClosed) {
            emit(
              state.copyWith(
                refresh: !state.refresh,
              ),
            );
          }
        } else {
          if (!isClosed) {
            emit(
              state.copyWith(
                refresh: !state.refresh,
                relays: currentUserRelayList.urls.toList(),
              ),
            );
          }
        }
      },
    );
  }

  late StreamSubscription userSubcription;
  List<String> currentRelays = [];
  late String lud16;
  late Timer timer;

  Future<void> setUsedMessagingNip(bool isUsingNip44) async {
    if (!isClosed) {
      emit(
        state.copyWith(isUsingNip44: isUsingNip44),
      );
    }

    dmsCubit.setUsedMessagingNip(isUsingNip44);
  }

  Future<void> setAutomaticSigning(bool enableAutomaticSigning) async {
    if (!isClosed) {
      emit(
        state.copyWith(enableAutomaticSigning: enableAutomaticSigning),
      );
    }

    localDatabaseRepository.setAutomaticSigning(enableAutomaticSigning);
  }

  Future<void> setGossip(bool enableGossip) async {
    if (!isClosed) {
      emit(
        state.copyWith(enableGossip: enableGossip),
      );
    }

    settingsCubit.gossip = enableGossip;
  }

  Future<void> setExternalBrowser(bool enableExternalBrowser) async {
    if (!isClosed) {
      emit(
        state.copyWith(enableUsingExternalBrowser: enableExternalBrowser),
      );
    }

    settingsCubit.useExternalBrowser = enableExternalBrowser;
  }

  void setKeys() {
    if (canSign()) {
      if (!isClosed) {
        emit(
          state.copyWith(
            authPrivKey: currentSigner is Bip340EventSigner
                ? (currentSigner! as Bip340EventSigner).privateKey!
                : '',
            authPubKey: currentSigner!.getPublicKey(),
          ),
        );
      }
    }
  }

  void setOneTapZap(bool enableOneTap) {
    emit(
      state.copyWith(
        enableOneTapZap: enableOneTap,
      ),
    );

    nostrRepository.enableOneTapZap = enableOneTap;
    localDatabaseRepository.setOneTapZap(enableOneTap);
  }

  void setOneTapReaction(bool enableOneTap) {
    emit(
      state.copyWith(
        enableOneTapReaction: enableOneTap,
      ),
    );

    nostrRepository.enableOneTapReaction = enableOneTap;
    localDatabaseRepository.setOneTapReaction(enableOneTap);
  }

  void setDefaultReaction(String defaultReaction) {
    emit(
      state.copyWith(
        defaultReaction: defaultReaction,
      ),
    );

    nostrRepository.defaultReactions[currentSigner!.getPublicKey()] =
        defaultReaction;
    localDatabaseRepository.setDefaultReactions(
      rs: nostrRepository.defaultReactions,
    );
  }

  void setRelaysStatus() {
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        final activeRelays = nc.currentUserActiveRelays(
          {...currentUserRelayList.urls, ...nostrRepository.dmRelays}.toList(),
        );

        final relays = currentUserRelayList.urls.toList();

        if (!isClosed) {
          emit(
            state.copyWith(
              activeRelays: activeRelays,
              relays: relays,
            ),
          );
        }
      },
    );
  }

  void setPropertyToggle(PropertiesToggle propertiesToggle) {
    if (!isClosed) {
      emit(
        state.copyWith(
          propertiesToggle: propertiesToggle,
        ),
      );
    }
  }

  Future<void> deleteUserAccount({
    required Function() onSuccess,
  }) async {
    try {
      final cancel = BotToastUtils.showLoading();

      final kind0Event = await Event.genEvent(
        content: jsonEncode({
          'name': 'unknown',
          'deleted': true,
        }),
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
        metadataCubit.saveMetadata(Metadata.fromEvent(kind0Event)!);
        onSuccess.call();
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      cancel.call();
    } catch (e) {
      lg.i(e);
    }
  }

  @override
  Future<void> close() {
    userSubcription.cancel();
    timer.cancel();
    return super.close();
  }
}
