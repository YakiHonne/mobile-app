// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../repositories/localdatabase_repository.dart';
import '../../repositories/nostr_data_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'article_state.dart';

class ArticleCubit extends Cubit<ArticleState> {
  ArticleCubit({
    required this.nostrRepository,
    required this.article,
    required this.localDatabaseRepository,
  }) : super(
          ArticleState(
            article: article,
            currentUserPubkey: nostrRepository.currentMetadata.pubkey,
            canBeZapped: false,
            refresh: false,
            metadata: Metadata.empty().copyWith(),
            isSameArticleAuthor:
                article.pubkey == nostrRepository.currentMetadata.pubkey,
            isFollowingAuthor: false,
            isBookmarked: getBookmarkIds(nostrRepository.bookmarksLists)
                .contains(article.identifier),
            isLoading: true,
          ),
        ) {
    if (article.client.isEmpty ||
        !article.client.startsWith(EventKind.APPLICATION_INFO.toString())) {
      identifier = '';
    } else {
      settingsCubit.getAppClient(article.client);

      final splits = article.client.split(':');
      if (splits.length > 2) {
        identifier = splits[2];
      }
    }

    userSubscription = nostrRepository.currentSignerStream.listen((signer) {
      if (signer == null || !signer.isGuest()) {
        if (!isClosed) {
          emit(
            state.copyWith(
              isSameArticleAuthor: false,
            ),
          );
        }
      } else {
        if (!isClosed) {
          emit(
            state.copyWith(
              isSameArticleAuthor:
                  canSign() && article.pubkey == signer.getPublicKey(),
            ),
          );
        }
      }
    });

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        final isBookmarked = getBookmarkIds(nostrRepository.bookmarksLists)
            .contains(article.identifier);

        if (!isClosed) {
          emit(
            state.copyWith(
              isBookmarked: isBookmarked,
            ),
          );
        }
      },
    );

    followingsSubscription = nostrRepository.contactListStream.listen(
      (followings) {
        if (!isClosed) {
          emit(
            state.copyWith(
              isFollowingAuthor: followings.contains(article.pubkey),
            ),
          );
        }
      },
    );

    mutesSubscription = nostrRepository.mutesStream.listen(
      (_) {
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

  final NostrDataRepository nostrRepository;
  final LocalDatabaseRepository localDatabaseRepository;
  late StreamSubscription followingsSubscription;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription mutesSubscription;
  late StreamSubscription userSubscription;
  final Article article;
  String identifier = '';
  Set<String> requests = {};

  void emptyArticleState() {
    ArticleState(
      article: article,
      refresh: !state.refresh,
      currentUserPubkey: nostrRepository.currentMetadata.pubkey,
      canBeZapped: false,
      metadata: Metadata.empty().copyWith(pubkey: article.pubkey),
      isSameArticleAuthor:
          canSign() && article.pubkey == currentSigner!.getPublicKey(),
      isFollowingAuthor: false,
      isBookmarked: getBookmarkIds(nostrRepository.bookmarksLists)
          .contains(article.identifier),
      isLoading: true,
    );
  }

  Future<void> initView() async {
    bool isFollowing = false;
    final metadata =
        await metadataCubit.getFutureMetadata(state.article.pubkey);

    if (metadata != null) {
      if (canSign() && article.pubkey != state.currentUserPubkey) {
        isFollowing = contactListCubit.contacts.contains(metadata.pubkey);
      }

      if (!isClosed) {
        emit(
          state.copyWith(
            metadata: metadata,
            isFollowingAuthor: isFollowing,
            canBeZapped: metadata.lud16.isNotEmpty &&
                canSign() &&
                state.article.pubkey != currentSigner!.getPublicKey(),
          ),
        );
      }

      return;
    }
  }

  Future<void> setFollowingState() async {
    final cancel = BotToastUtils.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowingAuthor,
      targetPubkey: state.article.pubkey,
    );

    cancel.call();
  }

  Future<void> shareLink(widgets.RenderBox? renderBox) async {
    final res = await externalShearableLink(
      kind: EventKind.LONG_FORM,
      pubkey: state.article.pubkey,
      id: state.article.identifier,
    );

    Share.share(
      res,
      subject: 'Check out www.yakihonne.com for me more articles.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(widgets.Offset.zero) & renderBox.size
          : null,
    );
  }

  @override
  Future<void> close() {
    followingsSubscription.cancel();
    bookmarksSubscription.cancel();
    userSubscription.cancel();
    mutesSubscription.cancel();
    nc.closeRequests(requests.toList());
    return super.close();
  }
}
