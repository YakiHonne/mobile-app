import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/common_regex.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'write_article_state.dart';

class WriteArticleCubit extends Cubit<WriteArticleState> {
  WriteArticleCubit({
    this.article,
  }) : super(
          WriteArticleState(
            content: article?.content ?? '',
            excerpt: article?.summary ?? '',
            isZapSplitEnabled: article?.zapsSplits.isNotEmpty ?? false,
            zapsSplits: article?.zapsSplits ??
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
            isSensitive: article?.isSensitive ?? false,
            keywords: article?.hashTags.toSet() ?? {},
            title: article?.title ?? '',
            imageLink: article?.image ?? '',
            isDraft: article?.isDraft ?? false,
            deleteDraft: true,
            forwardedAsDraft: false,
            suggestions: const [],
            tryToLoad: false,
          ),
        ) {
    setSuggestions();

    if (article == null &&
        nostrRepository.userDrafts!.articleDraft.isNotEmpty) {
      loadArticleAutoSaveModel();
    } else {
      articleAutoSaveModel = ArticleAutoSaveModel(
        content: article?.content ?? '',
        title: article?.title ?? '',
        description: article?.summary ?? '',
        isSensitive: article?.isSensitive ?? false,
        tags: article?.hashTags ?? [],
      );
    }
  }

  final Article? article;
  late ArticleAutoSaveModel articleAutoSaveModel;

  Future<void> loadArticleAutoSaveModel() async {
    articleAutoSaveModel = ArticleAutoSaveModel.fromJson(
      nostrRepository.userDrafts!.articleDraft,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: articleAutoSaveModel.content,
          isSensitive: articleAutoSaveModel.isSensitive,
          title: articleAutoSaveModel.title,
          keywords: articleAutoSaveModel.tags.toSet(),
          excerpt: articleAutoSaveModel.description,
          tryToLoad: !state.tryToLoad,
        ),
      );
    }
  }

  void deleteDraft() {
    nostrRepository.deleteArticleDraft();
    if (!isClosed) {
      emit(
        state.copyWith(
          content: '',
          isSensitive: false,
          title: '',
          keywords: {},
          excerpt: '',
          tryToLoad: !state.tryToLoad,
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

  void deleteArticleAutoSaveModel() {
    if (!isClosed) {
      emit(
        state.copyWith(
          content: '',
          isSensitive: false,
          title: '',
          keywords: {},
          excerpt: '',
        ),
      );
    }

    nostrRepository.saveArticleDraft(article: '');

    BotToastUtils.showSuccess(
      t.autoSavedArticleDeleted.capitalizeFirst(),
    );
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

  void toggleDraftDeletion() {
    if (!isClosed) {
      emit(
        state.copyWith(
          deleteDraft: !state.deleteDraft,
        ),
      );
    }
  }

  void toggleSensitive() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isSensitive: !state.isSensitive,
        ),
      );
    }

    articleAutoSaveModel = articleAutoSaveModel.copyWith(
      isSensitive: state.isSensitive,
    );

    nostrRepository.saveArticleDraft(
      article: articleAutoSaveModel.toJson(),
    );
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

  void setTitleText(String title) {
    if (!isClosed) {
      emit(
        state.copyWith(
          title: title,
        ),
      );
    }

    articleAutoSaveModel = articleAutoSaveModel.copyWith(
      title: title,
    );

    nostrRepository.saveArticleDraft(
      article: articleAutoSaveModel.title.trim().isEmpty &&
              articleAutoSaveModel.content.trim().isEmpty
          ? ''
          : articleAutoSaveModel.toJson(),
    );
  }

  void setContentText(String content) {
    if (!isClosed) {
      emit(
        state.copyWith(
          content: content,
        ),
      );
    }

    articleAutoSaveModel = articleAutoSaveModel.copyWith(
      content: content,
    );

    nostrRepository.saveArticleDraft(
      article: articleAutoSaveModel.toJson(),
    );
  }

  void setDescription(String description) {
    if (!isClosed) {
      emit(
        state.copyWith(excerpt: description),
      );
    }

    articleAutoSaveModel = articleAutoSaveModel.copyWith(
      description: description,
    );

    lg.i(articleAutoSaveModel.toJson());

    nostrRepository.saveArticleDraft(
      article: articleAutoSaveModel.toJson(),
    );
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

  void setContentKeywords() {
    final matches = hashtagsRegExp.allMatches(state.content).toList();
    if (matches.isNotEmpty) {
      final keywords = {
        ...state.keywords,
        ...matches.map(
          (e) => e.group(1)!,
        )
      };
      if (!isClosed) {
        emit(
          state.copyWith(
            keywords: keywords,
          ),
        );
      }
    }
  }

  void addKeyword(String keyword) {
    if (!state.keywords.contains(keyword.trim())) {
      final keywords = {...state.keywords, keyword.trim()};

      if (!isClosed) {
        emit(
          state.copyWith(
            keywords: keywords,
          ),
        );
      }

      articleAutoSaveModel = articleAutoSaveModel.copyWith(
        tags: keywords.toList(),
      );

      nostrRepository.saveArticleDraft(
        article: articleAutoSaveModel.toJson(),
      );
    }
  }

  void deleteKeyword(String keyword) {
    if (state.keywords.contains(keyword)) {
      final keywords = Set<String>.from(state.keywords)..remove(keyword);

      if (!isClosed) {
        emit(
          state.copyWith(
            keywords: keywords,
          ),
        );
      }

      articleAutoSaveModel = articleAutoSaveModel.copyWith(
        tags: keywords.toList(),
      );

      nostrRepository.saveArticleDraft(
        article: articleAutoSaveModel.toJson(),
      );
    }
  }

  Future<void> setArticle({
    required bool isDraft,
    required Function(Article?) onSuccess,
    required EventSigner signer,
  }) async {
    final cancel = BotToastUtils.showLoading();

    try {
      final content = sanitizeContent(state.content);
      final event = await Event.genEvent(
        content: content,
        kind: isDraft ? EventKind.LONG_FORM_DRAFT : EventKind.LONG_FORM,
        signer: signer,
        tags: [
          getClientTag(),
          [
            'd',
            if (article != null) article!.identifier else randomHexString(16)
          ],
          ['image', state.imageLink],
          ['title', state.title],
          ['summary', state.excerpt],
          [
            'published_at',
            if (article != null)
              article!.publishedAt.toSecondsSinceEpoch().toString()
            else
              currentUnixTimestampSeconds().toString(),
          ],
          if (state.isSensitive) ...[
            ['content-warning', ''],
            ['L', 'content-warning']
          ],
          ...state.keywords.map((tag) => ['t', tag]),
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
        relays: currentUserRelayList.urls.toList(),
        setProgress: true,
      );

      if (isSuccessful) {
        nostrRepository.refreshSelfArticlesController.add(true);
        nostrRepository.saveArticleDraft(
          article: '',
        );
        BotToastUtils.showSuccess(
          t.articlePublished.capitalizeFirst(),
        );
        onSuccess.call(!isDraft ? Article.fromEvent(event) : null);
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      if (article != null &&
          article!.isDraft &&
          !isDraft &&
          state.deleteDraft) {
        deleteArticle(
          article!.id,
          () {},
        );
      }

      cancel.call();
    } catch (e) {
      cancel.call();
      BotToastUtils.showError(
        t.errorAddingArticle.capitalizeFirst(),
      );
    }
  }

  Future<void> deleteArticle(
    String eventId,
    Function() onSuccess,
  ) async {
    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: eventId,
    );

    if (isSuccessful) {
      onSuccess.call();
    }
  }
}
