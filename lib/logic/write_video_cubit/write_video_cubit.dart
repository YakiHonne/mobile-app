import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/video_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'write_video_state.dart';

class WriteVideoCubit extends Cubit<WriteVideoState> {
  WriteVideoCubit({
    required this.videoModel,
  }) : super(
          WriteVideoState(
            contentWarning: videoModel?.contentWarning ?? false,
            isHorizontal: videoModel?.isHorizontal ?? true,
            tags: videoModel?.tags ?? [],
            summary: videoModel?.summary ?? '',
            title: videoModel?.title ?? '',
            imageLink: videoModel?.thumbnail ?? '',
            suggestions: const [],
            videoUrl: videoModel?.url ?? '',
            videoPublishSteps: VideoPublishSteps.content,
            isUpdating: videoModel != null,
            isZapSplitEnabled: videoModel?.zapsSplits.isNotEmpty ?? false,
            mimeType: videoModel?.mimeType ?? '',
            zapsSplits: videoModel?.zapsSplits ??
                [
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
    setSuggestions();
  }

  VideoModel? videoModel;

  void toggleVideoOrientation() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isHorizontal: !state.isHorizontal,
        ),
      );
    }
  }

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

  void setImage(String image) {
    if (!isClosed) {
      emit(
        state.copyWith(
          imageLink: image,
        ),
      );
    }
  }

  void deleteImage() {
    if (!isClosed) {
      emit(
        state.copyWith(
          imageLink: '',
        ),
      );
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
          imageLink: url,
        ),
      );
    }
  }

  void removeImage() {
    if (!isClosed) {
      emit(
        state.copyWith(
          imageLink: '',
        ),
      );
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

  void setSuggestions() {
    final Set<String> suggestions = {};
    for (final topic in nostrRepository.topics) {
      suggestions.addAll([topic.topic, ...topic.subTopics]);
      suggestions.addAll(nostrRepository.userTopics);
    }

    if (!isClosed) {
      emit(
        state.copyWith(suggestions: suggestions.toList()),
      );
    }
  }

  void setVideoPublishStep(VideoPublishSteps step) {
    if (state.videoPublishSteps == VideoPublishSteps.content) {
      final title = state.title.trim();
      final videoUrl = state.videoUrl.trim();

      if (title.isEmpty || videoUrl.isEmpty) {
        BotToastUtils.showError(
          t.setAllRequiredContent.capitalizeFirst(),
        );
        return;
      }
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          videoPublishSteps: step,
        ),
      );
    }
  }

  void setTitle(String title) {
    if (!isClosed) {
      emit(
        state.copyWith(
          title: title,
        ),
      );
    }
  }

  void setSummary(String summary) {
    if (!isClosed) {
      emit(
        state.copyWith(
          summary: summary,
        ),
      );
    }
  }

  void setUrl(String videoUrl) {
    if (!isClosed) {
      emit(
        state.copyWith(
          videoUrl: videoUrl,
        ),
      );
    }
  }

  void addKeyword(String keyword) {
    if (!state.tags.contains(keyword.trim())) {
      final tags = [...state.tags, keyword.trim()];

      if (!isClosed) {
        emit(
          state.copyWith(
            tags: tags,
          ),
        );
      }
    }
  }

  void deleteKeyword(String keyword) {
    if (state.tags.contains(keyword)) {
      final tags = List<String>.from(state.tags)..remove(keyword);

      if (!isClosed) {
        emit(
          state.copyWith(
            tags: tags,
          ),
        );
      }
    }
  }

  void addFileMetadata(String nevent) {
    if (nevent.startsWith('nevent') || nevent.startsWith('nostr:nevent')) {
      final cancel = BotToast.showLoading();
      final map = Nip19.decodeShareableEntity(nevent);

      if (map['prefix'] == 'nevent' && map['kind'] == EventKind.FILE_METADATA) {
        Event? currentEvent;

        NostrFunctionsRepository.getEvents(
          ids: [map['special']],
          pubkeys: [map['author']],
        ).listen((event) {
          currentEvent = event;
        }).onDone(
          () {
            if (currentEvent == null) {
              BotToastUtils.showError(
                t.noEventIdCanBeFound.capitalizeFirst(),
              );
            } else {
              String url = '';
              bool isVideo = false;

              for (final tag in currentEvent!.tags) {
                if (tag.first == 'url' && tag.length > 1) {
                  url = tag[1];
                } else if (tag.first == 'm' && tag.length > 1) {
                  isVideo = tag[1].toLowerCase().startsWith('video/');
                }
              }

              if (!isVideo) {
                BotToastUtils.showError(
                  t.notValidVideoEvent.capitalizeFirst(),
                );
              } else if (url.isEmpty) {
                BotToastUtils.showError(
                  t.emptyVideoUrl.capitalizeFirst(),
                );
              } else {
                emit(
                  state.copyWith(videoUrl: url),
                );
              }
            }
          },
        );
      } else {
        BotToastUtils.showError(
          t.submitValidVideoEvent.capitalizeFirst(),
        );
      }

      cancel.call();
    } else {
      BotToastUtils.showError(
        t.submitValidVideoEvent.capitalizeFirst(),
      );
    }
  }

  Future<void> selectAndUploadVideo() async {
    try {
      final cancel = BotToast.showLoading();

      final XFile? video;
      video = await ImagePicker().pickVideo(source: ImageSource.gallery);

      if (video != null) {
        final file = File(video.path);
        final data = await uploadVideo(file);
        if (data.isEmpty || (data['url'] ?? '').isEmpty) {
          BotToastUtils.showError(
            t.errorUploadingVideo.capitalizeFirst(),
          );
          cancel.call();
          return;
        }

        if (!isClosed) {
          emit(
            state.copyWith(
              videoUrl: data['url'],
              imageLink: data['thumbnail'] ?? '',
              mimeType: data['m'] ?? '',
            ),
          );
        }
      }

      cancel.call();
    } catch (e) {
      BotToastUtils.showError(
        t.errorUploadingVideo.capitalizeFirst(),
      );
    }
  }

  Future<Map<String, dynamic>> uploadVideo(File video) async {
    try {
      return await mediaServersCubit.uploadMedia(
        file: video,
      );
    } catch (e) {
      Logger().i(e);
      rethrow;
    }
  }

  Future<void> setVideo({
    required Function(String) onFailure,
    required Function(VideoModel) onSuccess,
  }) async {
    final cancel = BotToast.showLoading();

    try {
      final event = await Event.genEvent(
        content: state.summary,
        kind: state.isHorizontal
            ? EventKind.VIDEO_HORIZONTAL
            : EventKind.VIDEO_VERTICAL,
        signer: currentSigner,
        tags: [
          getClientTag(),
          ['title', state.title],
          [
            'published_at',
            if (videoModel != null)
              videoModel!.publishedAt.toSecondsSinceEpoch().toString()
            else
              currentUnixTimestampSeconds().toString(),
          ],
          [
            'imeta',
            'url ${state.videoUrl}',
            'image ${state.imageLink}',
            'm ${state.mimeType}',
          ],
          ...state.tags.map((tag) => ['t', tag]),
          if (state.contentWarning) ['L', 'content-warning'],
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
        setProgress: true,
        relays: currentUserRelayList.writes,
      );

      if (isSuccessful) {
        onSuccess.call(VideoModel.fromEvent(event));
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      cancel.call();
    } catch (e, stack) {
      lg.i(stack);
      cancel.call();
      onFailure.call(
        t.errorAddingVideo.capitalizeFirst(),
      );
    }
  }
}
