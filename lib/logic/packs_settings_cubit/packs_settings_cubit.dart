import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/packs_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'packs_settings_state.dart';

class PacksSettingsCubit extends Cubit<PacksSettingsState> {
  PacksSettingsCubit()
      : super(
          const PacksSettingsState(
            packs: {},
            starterPacks: {},
            isLoading: true,
          ),
        );

  Future<void> initPacks() async {
    clear();
    if (canSign()) {
      await loadLocalPacks();
      syncPacks();
    }
  }

  void clear() {
    emit(
      const PacksSettingsState(
        packs: {},
        starterPacks: {},
        isLoading: true,
      ),
    );
  }

  Future<void> loadLocalPacks() async {
    final events = await nc.db.loadEvents(
      f: Filter(
        kinds: [
          EventKind.STARTER_PACKS,
          EventKind.MEDIA_PACKS,
        ],
        authors: [
          currentSigner!.getPublicKey(),
        ],
      ),
    );

    final packs = <String, PacksModel>{};
    final starterPacks = <String, bool>{};

    for (final e in events) {
      final p = PacksModel.fromEvent(e);

      packs[p.identifier] = p;
      starterPacks[p.identifier] = p.isStarterPack();
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          packs: packs,
          starterPacks: starterPacks,
          isLoading: false,
        ),
      );
    }
  }

  Future<void> syncPacks() async {
    if (!canSign()) {
      return;
    }

    await Future.delayed(const Duration(seconds: 2));

    final events = await NostrFunctionsRepository.getEventsAsync(
      pubkeys: [
        currentSigner!.getPublicKey(),
      ],
      source: EventsSource.all,
      kinds: [
        EventKind.STARTER_PACKS,
        EventKind.MEDIA_PACKS,
      ],
    );

    final packs = <String, PacksModel>{};
    final starterPacks = <String, bool>{};

    for (final e in events) {
      final p = PacksModel.fromEvent(e);

      packs[p.identifier] = p;
      starterPacks[p.identifier] = p.isStarterPack();
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          packs: packs,
          starterPacks: starterPacks,
          isLoading: false,
        ),
      );
    }
  }

  Future<void> setPack({
    required String title,
    required String description,
    required String image,
    required Set<String> pubkeys,
    required int kind,
    Function()? onSuccess,
    String? identifier,
    bool? isOwner,
  }) async {
    if (!canSign()) {
      return;
    }

    final event = await Event.genEvent(
      kind: kind,
      tags: [
        ['d', identifier ?? randomHexString(16)],
        if (title.isNotEmpty) ['title', title],
        if (description.isNotEmpty) ['description', description],
        if (image.isNotEmpty) ['image', image],
        ...pubkeys.map((pubkey) => ['p', pubkey]),
      ],
      content: '',
      signer: currentSigner,
    );

    if (event != null) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: false,
      );

      if (isSuccessful) {
        await nc.db.saveEvent(event);
        BotToastUtils.showSuccess(isOwner != null
            ? isOwner
                ? t.packUpdated
                : t.packCloned
            : t.packCreated);
        addPack(PacksModel.fromEvent(event));
        onSuccess?.call();
      } else {
        BotToastUtils.showError(
          identifier != null ? t.errorOnUpdatingPack : t.errorOnCreatingPack,
        );
      }
    } else {
      BotToastUtils.showError(t.errorGeneratingEvent);
    }
  }

  Future<void> deletePack(PacksModel pack) async {
    final cancel = BotToastUtils.showLoading();

    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: '',
      aTag: pack.aTag(),
    );

    cancel();

    if (isSuccessful) {
      BotToastUtils.showSuccess(t.packDeleted);
      removePack(pack);
      nc.db.removeEventByDTag(pack.identifier);
    } else {
      BotToastUtils.showError(t.errorDeletingContent);
    }
  }

  void addPack(PacksModel pack) {
    emit(
      state.copyWith(
        packs: {
          ...state.packs,
          pack.identifier: pack,
        },
        starterPacks: {
          ...state.starterPacks,
          pack.identifier: pack.isStarterPack(),
        },
      ),
    );
  }

  void removePack(PacksModel pack) {
    final packs = Map<String, PacksModel>.from(state.packs);
    final starterPacks = Map<String, bool>.from(state.starterPacks);
    packs.remove(pack.identifier);
    starterPacks.remove(pack.identifier);

    emit(
      state.copyWith(
        packs: packs,
        starterPacks: starterPacks,
      ),
    );
  }
}
