import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/video_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'write_curation_state.dart';

class WriteCurationCubit extends Cubit<WriteCurationState> {
  WriteCurationCubit({
    required this.curation,
  }) : super(
          WriteCurationState(
            activeArticles: const [],
            activeVideos: const [],
            articles: const [],
            videos: const [],
            isLoading: false,
            isActiveLoading: false,
            searchText: '',
            relaysAddingData: UpdatingState.progress,
            mutes: nostrRepository.muteModel.usersMutes.toList(),
            imageLink: curation?.image ?? '',
            isArticlesCuration: curation?.isArticleCuration() ?? true,
            curationPublishSteps: CurationPublishSteps.content,
            title: curation?.title ?? '',
            description: curation?.description ?? '',
            isZapSplitEnabled: curation?.zapsSplits.isNotEmpty ?? false,
            selfContent: false,
            zapsSplits: curation?.zapsSplits ??
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
    if (curation != null) {
      initView();
    }
  }

  final Curation? curation;
  Set<String> requests = <String>{};

  void toggleZapsSplits() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isZapSplitEnabled: !state.isZapSplitEnabled,
        ),
      );
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

  void setTitle(String title) {
    if (!isClosed) {
      emit(
        state.copyWith(
          title: title,
        ),
      );
    }
  }

  void setDescription(String description) {
    if (!isClosed) {
      emit(
        state.copyWith(
          description: description,
        ),
      );
    }
  }

  void setCurationType() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isArticlesCuration: !state.isArticlesCuration,
        ),
      );
    }
  }

  void setView(bool isNext) {
    late CurationPublishSteps nextStep;
    if (isNext) {
      nextStep = CurationPublishSteps.zaps;
    } else {
      nextStep = CurationPublishSteps.content;
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          curationPublishSteps: nextStep,
        ),
      );
    }
  }

  Future<void> addCuration({
    required Function(String) onFailure,
    required Function(Curation) onSuccess,
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

      if (state.imageLink.isEmpty) {
        onFailure.call(
          t.validImageCuration.capitalizeFirst(),
        );
        cancel.call();
        return;
      }

      List<List<String>> items = <List<String>>[];

      if (state.isArticlesCuration) {
        if (state.activeArticles.isNotEmpty) {
          items = state.activeArticles
              .map(
                (Article article) => <String>[
                  'a',
                  EventCoordinates(
                    EventKind.LONG_FORM,
                    article.pubkey,
                    article.identifier,
                    '',
                  ).toString()
                ],
              )
              .toList();
        }
      } else {
        if (state.activeVideos.isNotEmpty) {
          items = state.activeVideos
              .map(
                (VideoModel video) => <String>[
                  'e',
                  video.id,
                ],
              )
              .toList();
        }
      }

      final event = await Event.genEvent(
        kind: state.isArticlesCuration
            ? EventKind.CURATION_ARTICLES
            : EventKind.CURATION_VIDEOS,
        content: '',
        signer: currentSigner,
        verify: true,
        tags: [
          getClientTag(),
          [
            'd',
            curation?.identifier ?? randomHexString(16),
          ],
          ['title', state.title.trim()],
          ['description', state.description.trim()],
          ['image', state.imageLink],
          [
            'published_at',
            if (curation != null)
              curation!.publishedAt.toSecondsSinceEpoch().toString()
            else
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
          ...items,
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
        onSuccess.call(Curation.fromEvent(event, ''));
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      cancel.call();
    } catch (_) {
      cancel.call();
      onFailure.call(
        curation == null
            ? t.errorAddingCuration.capitalizeFirst()
            : t.errorUpdatingCuration.capitalizeFirst(),
      );
    }
  }

  void initView() {
    getItems(true);
  }

  void getItems(bool isActiveItems) {
    List<String> identifiers = <String>[];
    nc.closeRequests(requests.toList());

    if (isActiveItems) {
      final items = curation!.eventsIds
          .where((EventCoordinates event) => curation!.isArticleCuration()
              ? event.kind == EventKind.LONG_FORM
              : (event.kind == EventKind.VIDEO_HORIZONTAL ||
                  event.kind == EventKind.VIDEO_VERTICAL))
          .toList();

      if (items.isEmpty) {
        if (!isClosed) {
          emit(
            state.copyWith(
              isActiveLoading: false,
            ),
          );
        }

        return;
      }

      identifiers = items.map((EventCoordinates e) => e.identifier).toList();

      if (!isClosed) {
        emit(
          state.copyWith(
            isActiveLoading: true,
            activeArticles: <Article>[],
            activeVideos: <VideoModel>[],
            articles: <Article>[],
            videos: <VideoModel>[],
            searchText: '',
          ),
        );
      }
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(
            articles: <Article>[],
            videos: <VideoModel>[],
            isLoading: true,
            searchText: '',
          ),
        );
      }
    }

    if (state.isArticlesCuration) {
      NostrFunctionsRepository.getArticles(
        pubkeys:
            !state.selfContent ? null : <String>[currentSigner!.getPublicKey()],
        limit: isActiveItems ? null : 20,
        articlesIds: isActiveItems ? identifiers : null,
      ).listen(
        (List<Article> articles) {
          if (!isClosed) {
            emit(
              state.copyWith(
                articles: isActiveItems ? null : articles.toList(),
                activeArticles: isActiveItems ? articles.toList() : null,
                isActiveLoading: isActiveItems ? false : null,
                isLoading: isActiveItems ? null : false,
              ),
            );
          }
        },
        onDone: () {
          if (state.selfContent) {
            if (!isClosed) {
              emit(
                state.copyWith(
                  isLoading: false,
                ),
              );
            }
          }
        },
      );
    } else {
      NostrFunctionsRepository.getVideos(
        loadHorizontal: true,
        loadVertical: true,
        limit: isActiveItems ? null : 20,
        videosIds: isActiveItems ? identifiers : null,
        pubkeys:
            !state.selfContent ? null : <String>[currentSigner!.getPublicKey()],
        onAllVideos: (List<VideoModel> videos) {
          if (!isClosed) {
            emit(
              state.copyWith(
                videos: isActiveItems ? null : videos,
                activeVideos: isActiveItems ? videos.toList() : null,
                isActiveLoading: isActiveItems ? false : null,
                isLoading: isActiveItems ? null : false,
              ),
            );
          }
        },
        onHorizontalVideos: (List<VideoModel> hVideos) {},
        onVerticalVideos: (List<VideoModel> vVideos) {},
        onDone: () {
          if (state.selfContent) {
            if (!isClosed) {
              emit(
                state.copyWith(
                  isLoading: false,
                ),
              );
            }
          }
        },
      );
    }
  }

  void toggleView() {
    if (!isClosed) {
      emit(
        state.copyWith(
          selfContent: !state.selfContent,
        ),
      );
    }
  }

  Future<void> getMoreItems() async {
    if (state.isArticlesCuration) {
      final int lastIndex = state.articles.length;
      final List<Article> existingArticles = List<Article>.from(state.articles);

      if (!isClosed) {
        emit(
          state.copyWith(
            relaysAddingData: UpdatingState.progress,
          ),
        );
      }

      NostrFunctionsRepository.getArticles(
        pubkeys:
            !state.selfContent ? null : <String>[currentSigner!.getPublicKey()],
        limit: 20,
        until: lastIndex == 0
            ? null
            : state.articles[lastIndex - 1].createdAt.toSecondsSinceEpoch() - 1,
      ).listen(
        (List<Article> articles) {
          final List<Article> updatedArticles = List.from(existingArticles);
          updatedArticles.addAll(articles);
          if (!isClosed) {
            emit(
              state.copyWith(
                articles: updatedArticles,
                relaysAddingData: UpdatingState.success,
              ),
            );
          }
        },
        onDone: () {
          if (!isClosed) {
            emit(
              state.copyWith(
                relaysAddingData: UpdatingState.success,
              ),
            );
          }
        },
      );
    } else {
      final int lastIndex = state.videos.length;
      final List<VideoModel> existingVideos = List.from(state.videos);

      if (!isClosed) {
        emit(
          state.copyWith(
            relaysAddingData: UpdatingState.progress,
          ),
        );
      }

      NostrFunctionsRepository.getVideos(
        loadHorizontal: true,
        loadVertical: true,
        limit: 20,
        until: lastIndex == 0
            ? null
            : state.videos[lastIndex - 1].createdAt.toSecondsSinceEpoch() - 1,
        onAllVideos: (List<VideoModel> videos) {
          final List<VideoModel> updatedVideos = List.from(existingVideos);
          updatedVideos.addAll(videos);
          if (!isClosed) {
            emit(
              state.copyWith(
                videos: updatedVideos,
                relaysAddingData: UpdatingState.success,
              ),
            );
          }
        },
        onHorizontalVideos: (List<VideoModel> hVideos) {},
        onVerticalVideos: (List<VideoModel> vVideos) {},
        onDone: () {
          if (state.selfContent) {
            if (!isClosed) {
              emit(
                state.copyWith(
                  relaysAddingData: UpdatingState.success,
                ),
              );
            }
          }
        },
      );

      NostrFunctionsRepository.getArticles(
        pubkeys:
            !state.selfContent ? null : <String>[currentSigner!.getPublicKey()],
        limit: 20,
        until: lastIndex == 0
            ? null
            : state.articles[lastIndex - 1].createdAt.toSecondsSinceEpoch() - 1,
      ).listen(
        (List<Article> articles) {
          final List<Article> updatedArticles = List.from(existingVideos);
          updatedArticles.addAll(articles);
          if (!isClosed) {
            emit(
              state.copyWith(
                articles: updatedArticles,
                relaysAddingData: UpdatingState.success,
              ),
            );
          }
        },
        onDone: () {
          if (!isClosed) {
            emit(
              state.copyWith(
                relaysAddingData: UpdatingState.success,
              ),
            );
          }
        },
      );
    }
  }

  void setSearchText(String text) {
    if (!isClosed) {
      emit(
        state.copyWith(
          searchText: text,
        ),
      );
    }
  }

  static List<Article> getUpdatedArticles(List<dynamic> values) {
    final List<Article> articles = List.from(
      values[0].sublist(values[3], values[0].length),
    );

    articles.addAll(values[1]);
    articles.sort((Article a, Article b) => b.createdAt.compareTo(a.createdAt));

    return List.from(values[2])..addAll(articles.toList());
  }

  void setArticleToActive(Article article) {
    if (!isClosed) {
      emit(
        state.copyWith(
            activeArticles: List.from(state.activeArticles)..add(article)),
      );
    }
  }

  void setVideoToActive(VideoModel video) {
    if (!isClosed) {
      emit(
        state.copyWith(activeVideos: List.from(state.activeVideos)..add(video)),
      );
    }
  }

  void deleteActiveArticle(String id) {
    if (state.isArticlesCuration) {
      final List<Article> articles = List<Article>.from(state.activeArticles)
        ..removeWhere((Article element) => element.id == id);

      if (!isClosed) {
        emit(
          state.copyWith(
            activeArticles: articles,
          ),
        );
      }
    } else {
      final List<VideoModel> videos = List<VideoModel>.from(state.activeVideos)
        ..removeWhere((VideoModel element) => element.id == id);

      if (!isClosed) {
        emit(
          state.copyWith(activeVideos: videos),
        );
      }
    }
  }

  void setArticlesNewOrder(int oldIndex, int newIndex) {
    final List<Article> newArticles = List.from(state.activeArticles);
    final Article article = newArticles.removeAt(oldIndex);
    newArticles.insert(newIndex, article);

    if (!isClosed) {
      emit(
        state.copyWith(
          activeArticles: newArticles,
        ),
      );
    }
  }

  void setVideossNewOrder(int oldIndex, int newIndex) {
    final List<VideoModel> newVideos = List.from(state.activeVideos);
    final VideoModel video = newVideos.removeAt(oldIndex);
    newVideos.insert(newIndex, video);

    if (!isClosed) {
      emit(
        state.copyWith(
          activeVideos: newVideos,
        ),
      );
    }
  }

  void setArticleGrid(List<Article> articles) {
    if (!isClosed) {
      emit(
        state.copyWith(
          activeArticles: articles,
        ),
      );
    }
  }

  void setVideosGrid(List<VideoModel> videos) {
    if (!isClosed) {
      emit(
        state.copyWith(
          activeVideos: videos,
        ),
      );
    }
  }
}
