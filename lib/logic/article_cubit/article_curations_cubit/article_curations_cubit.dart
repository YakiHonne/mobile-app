// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../models/article_model.dart';
import '../../../models/curation_model.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'article_curations_state.dart';

class ArticleCurationsCubit extends Cubit<ArticleCurationsState> {
  ArticleCurationsCubit({
    required String articleId,
    required String articleAuthor,
    required int kind,
  }) : super(
          ArticleCurationsState(
            refresh: false,
            articleId: articleId,
            articleAuthor: articleAuthor,
            curations: const [],
            isCurationsLoading: true,
            articleCuration: ArticleCuration.curationsList,
            imageLink: '',
            isLocalImage: false,
            isImageSelected: false,
            description: '',
            title: '',
            selectedRelays: mandatoryRelays,
            curationKind: kind,
            totalRelays: currentUserRelayList.writes,
            isZapSplitEnabled: false,
            zapsSplits: [
              ZapSplit(
                pubkey: currentSigner!.getPublicKey(),
                percentage: 95,
              ),
              const ZapSplit(
                pubkey: yakihonneHex,
                percentage: 5,
              ),
            ],
          ),
        ) {
    if (canSign()) {
      getCurations();
    }

    cs = nostrRepository.currentSignerStream.listen(
      (event) {
        if (!isClosed) {
          emit(
            state.copyWith(
              refresh: !state.refresh,
            ),
          );
        }
      },
    );
  }

  late StreamSubscription cs;
  Timer? curationsTimer;
  Set<String> requests = {};

  void toggleZapsSplits() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isZapSplitEnabled: !state.isZapSplitEnabled,
        ),
      );
    }
  }

  void setZapPropertion({
    required int index,
    required ZapSplit zapSplit,
    required int newPercentage,
  }) {
    final zaps = List<ZapSplit>.from(state.zapsSplits);

    zaps[index] = ZapSplit(
      pubkey: zapSplit.pubkey,
      percentage: newPercentage,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          zapsSplits: zaps,
        ),
      );
    }
  }

  void addZapSplit(String pubkey) {
    final zaps = List<ZapSplit>.from(state.zapsSplits);
    final doesNotExist =
        zaps.where((element) => element.pubkey == pubkey).toList().isEmpty;

    if (doesNotExist) {
      zaps.add(
        ZapSplit(
          pubkey: pubkey,
          percentage: 1,
        ),
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            zapsSplits: zaps,
          ),
        );
      }
    }
  }

  void onRemoveZapSplit(String pubkey) {
    if (state.zapsSplits.length > 1) {
      final zaps = List<ZapSplit>.from(state.zapsSplits);
      zaps.removeWhere(
        (element) => element.pubkey == pubkey,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            zapsSplits: zaps,
          ),
        );
      }
    } else {
      BotToastUtils.showError(
        t.zapSplitsMessage.capitalizeFirst(),
      );
    }
  }

  void setText(bool isTitle, String text) {
    if (isTitle) {
      if (!isClosed) {
        emit(
          state.copyWith(
            title: text,
          ),
        );
      }
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(
            description: text,
          ),
        );
      }
    }
  }

  void setRelaySelection(String relay) {
    if (state.selectedRelays.contains(relay)) {
      if (!isClosed) {
        emit(
          state.copyWith(
            selectedRelays: List.from(state.selectedRelays)..remove(relay),
          ),
        );
      }
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(
            selectedRelays: List.from(state.selectedRelays)..add(relay),
          ),
        );
      }
    }
  }

  void emptyText() {
    if (!isClosed) {
      emit(
        state.copyWith(
          title: '',
          description: '',
        ),
      );
    }
  }

  void getCurations() {
    curationsTimer?.cancel();

    if (!isClosed) {
      emit(
        state.copyWith(
          curations: [],
          isCurationsLoading: true,
        ),
      );
    }

    final curationsToBeEmitted = <String, Curation>{};

    final request = nc.addSubscription(
      [
        Filter(
          kinds: [state.curationKind],
          authors: [nostrRepository.currentMetadata.pubkey],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == state.curationKind) {
          final curation = Curation.fromEvent(event, relay);

          final oldCuration = curationsToBeEmitted[curation.identifier];

          curationsToBeEmitted[curation.identifier] = filterCuration(
            oldCuration: oldCuration,
            newCuration: curation,
          );
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        if (curationsToBeEmitted.isNotEmpty) {
          final List<Curation> curations = List.from(state.curations);

          curations.removeWhere(
            (element) => curationsToBeEmitted.keys.contains(element.identifier),
          );

          curations.insertAll(0, curationsToBeEmitted.values);

          if (!isClosed) {
            emit(
              state.copyWith(
                curations: curations,
                isCurationsLoading: false,
              ),
            );
          }
        } else {
          if (!isClosed) {
            emit(
              state.copyWith(
                curations: [],
                isCurationsLoading: false,
              ),
            );
          }
        }

        nc.closeSubscription(curationRequestId, relay);
      },
    );

    curationsTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (timer.tick >= 6 && state.curations.isEmpty) {
          timer.cancel();

          if (!isClosed) {
            emit(
              state.copyWith(
                isCurationsLoading: false,
              ),
            );
          }
        }
      },
    );

    requests.add(request);
  }

  void setView(ArticleCuration articleCuration) {
    if (!isClosed) {
      emit(
        state.copyWith(
          articleCuration: articleCuration,
        ),
      );
    }
  }

  Curation filterCuration({
    required Curation? oldCuration,
    required Curation newCuration,
  }) {
    if (oldCuration != null) {
      final isNew = oldCuration.createdAt.compareTo(newCuration.createdAt) < 1;
      if (isNew) {
        newCuration.relays.addAll(oldCuration.relays);
        return newCuration;
      } else {
        oldCuration.relays.addAll(newCuration.relays);
        return oldCuration;
      }
    } else {
      return newCuration;
    }
  }

  Future<void> setCuration({
    required Curation curation,
    required Function(String) onFailure,
    required Function() onSuccess,
  }) async {
    final cancel = BotToastUtils.showLoading();

    try {
      final articlesList = curation.eventsIds
          .map(
            (event) => [
              'a',
              EventCoordinates(
                EventKind.LONG_FORM,
                event.pubkey,
                event.identifier,
                '',
              ).toString()
            ],
          )
          .toList();

      articlesList.add(
        [
          'a',
          EventCoordinates(
            EventKind.LONG_FORM,
            state.articleAuthor,
            state.articleId,
            '',
          ).toString()
        ],
      );

      final event = await Event.genEvent(
        kind: state.curationKind,
        content: '',
        signer: currentSigner,
        verify: true,
        tags: [
          ['d', curation.identifier],
          ['title', curation.title],
          ['description', curation.description],
          ['image', curation.image],
          ...articlesList,
        ],
      );

      if (event == null) {
        cancel.call();
        return;
      }

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        relays: currentUserRelayList.writes,
        setProgress: true,
      );

      if (isSuccessful) {
        onSuccess.call();
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      cancel.call();
    } catch (_) {
      onFailure.call(
        t.errorUpdatingCuration.capitalizeFirst(),
      );
    }
  }

  Future<void> addCuration({
    required Function(String) onFailure,
  }) async {
    final cancel = BotToastUtils.showLoading();

    try {
      if (state.title.trim().isEmpty) {
        onFailure.call(
          t.validTitleCuration.capitalizeFirst(),
        );
        cancel.call();
        return;
      }

      if (!state.isImageSelected) {
        onFailure.call(
          t.validImageCuration.capitalizeFirst(),
        );
        cancel.call();
        return;
      }

      String imageLink = '';

      if (state.isLocalImage) {
        imageLink = await uploadImage();
      } else {
        imageLink = state.imageLink;
      }

      final event = await Event.genEvent(
        kind: state.curationKind,
        content: '',
        signer: currentSigner,
        verify: true,
        tags: [
          ['d', randomHexString(16)],
          ['title', state.title],
          ['description', state.description],
          ['image', imageLink],
          [
            'published_at',
            currentUnixTimestampSeconds().toString(),
          ],
          if (state.isZapSplitEnabled)
            ...state.zapsSplits.map(
              (e) => [
                'zap',
                e.pubkey,
                mandatoryRelays.first,
                e.percentage.toString(),
              ],
            ),
        ],
      );

      if (event == null) {
        cancel.call();
        return;
      }

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        relays: currentUserRelayList.writes,
        setProgress: true,
      );

      if (isSuccessful) {
        if (!isClosed) {
          emit(
            state.copyWith(
              curations: List<Curation>.from(state.curations)
                ..add(
                  Curation.fromEvent(event, ''),
                ),
              articleCuration: ArticleCuration.curationsList,
            ),
          );
        }
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      cancel.call();
    } catch (_) {
      cancel.call();
      onFailure.call(
        t.errorAddingCuration.capitalizeFirst(),
      );
    }
  }

  Future<void> selectProfileImage({
    required Function() onFailed,
  }) async {
    try {
      final XFile? image;
      image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image != null) {
        final file = File(image.path);

        if (!isClosed) {
          emit(
            state.copyWith(
              localImage: file,
              isLocalImage: true,
              imageLink: '',
              isImageSelected: true,
            ),
          );
        }
      }
    } catch (e) {
      onFailed.call();
    }
  }

  Future<void> selectUrlImage({
    required String url,
    required Function() onFailed,
  }) async {
    if (url.trim().isEmpty || !url.startsWith('https')) {
      onFailed.call();
      return;
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          isLocalImage: false,
          isImageSelected: true,
          imageLink: url,
        ),
      );
    }
  }

  void removeImage() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isLocalImage: false,
          isImageSelected: false,
          imageLink: '',
        ),
      );
    }
  }

  Future<String> uploadImage() async {
    try {
      return (await mediaServersCubit.uploadMedia(
              file: state.localImage!))['url'] ??
          '';
    } catch (e) {
      Logger().i(e);
      rethrow;
    }
  }

  @override
  Future<void> close() {
    cs.cancel();
    return super.close();
  }
}
