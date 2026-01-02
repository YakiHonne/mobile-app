// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';
import 'package:nostr_core_enhanced/nostr/nips/nip_033.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/video_model.dart';
import '../../models/vote_model.dart';
import '../../repositories/nostr_data_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'curation_state.dart';

class CurationCubit extends Cubit<CurationState> {
  CurationCubit({
    required this.nostrRepository,
    required this.curation,
  }) : super(
          CurationState(
            curation: curation,
            isArticlesCuration: curation.isArticleCuration(),
            isArticleLoading: true,
            refresh: false,
            votes: const <String, VoteModel>{},
            mutes: nostrRepository.muteModel.usersMutes.toList(),
            articles: const <Article>[],
            currentUserPubkey: nostrRepository.currentMetadata.pubkey,
            canBeZapped: false,
            isValidUser: canSign(),
            isSameCurationAuthor:
                canSign() && curation.pubkey == currentSigner!.getPublicKey(),
            replies: const <DetailedNoteModel>[],
            zaps: const <String, double>{},
            reports: const <String>{},
            videos: const <VideoModel>[],
            isFollowingAuthor:
                contactListCubit.contacts.contains(curation.pubkey),
            isBookmarked: getBookmarkIds(nostrRepository.bookmarksLists)
                .contains(curation.identifier),
          ),
        ) {
    if (curation.client.isEmpty ||
        !curation.client.startsWith(EventKind.APPLICATION_INFO.toString())) {
      identifier = '';
    } else {
      settingsCubit.getAppClient(curation.client);

      final splits = curation.client.split(':');
      if (splits.length > 2) {
        identifier = splits[2];
      }
    }

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mm) {
        if (!isClosed) {
          emit(
            state.copyWith(
              mutes: mm.usersMutes.toList(),
              refresh: !state.refresh,
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
              isFollowingAuthor: followings.contains(curation.pubkey),
            ),
          );
        }
      },
    );
  }

  final NostrDataRepository nostrRepository;
  late StreamSubscription muteListSubscription;
  late StreamSubscription followingsSubscription;
  final Curation curation;
  String identifier = '';
  Set<String> requests = <String>{};

  void initView() {
    setAuthor();
    getStats();
    getItems();
  }

  void getStats() {
    NostrFunctionsRepository.getStats(
      identifier: curation.identifier,
      eventKind: curation.kind,
      eventPubkey: curation.pubkey,
      isEtag: false,
    ).listen(
      (data) {
        if (data is Map<String, Map<String, VoteModel>>) {
          final Map<String, VoteModel> votes =
              Map<String, VoteModel>.from(state.votes)
                ..addAll(data[curation.identifier] ?? <String, VoteModel>{});
          if (!isClosed) {
            emit(
              state.copyWith(
                votes: votes,
              ),
            );
          }
        } else if (data is Map<String, DetailedNoteModel>) {
          if (!isClosed) {
            emit(
              state.copyWith(
                replies: data.values.toList(),
              ),
            );
          }
        } else if (data is Map<String, double>) {
          if (!isClosed) {
            emit(
              state.copyWith(
                zaps: data,
              ),
            );
          }
        } else if (data is Set<String>) {
          if (!isClosed) {
            emit(
              state.copyWith(
                reports: data,
              ),
            );
          }
        }
      },
      onDone: () {
        getAuthors();
      },
    );
  }

  void getItems() {
    final List<String> itemsIds = <String>[];

    if (curation.eventsIds.isEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isArticleLoading: false,
          ),
        );
      }

      return;
    }

    for (final EventCoordinates eventId in curation.eventsIds) {
      if (curation.isArticleCuration()
          ? eventId.kind == EventKind.LONG_FORM
          : (eventId.kind == EventKind.VIDEO_HORIZONTAL ||
              eventId.kind == EventKind.VIDEO_VERTICAL)) {
        if (!itemsIds.contains(eventId.identifier)) {
          itemsIds.add(eventId.identifier);
        }
      }
    }

    if (itemsIds.isNotEmpty) {
      if (curation.isArticleCuration()) {
        NostrFunctionsRepository.getArticles(articlesIds: itemsIds).listen(
          (List<Article> articles) {
            if (!isClosed) {
              emit(
                state.copyWith(
                  isArticleLoading: false,
                  articles: articles,
                ),
              );
            }
          },
          onDone: () {
            if (!isClosed) {
              emit(
                state.copyWith(
                  isArticleLoading: false,
                ),
              );
            }
          },
        ).onDone(() {
          if (!isClosed) {
            emit(
              state.copyWith(
                isArticleLoading: false,
              ),
            );
          }
        });
      } else {
        NostrFunctionsRepository.getVideos(
          loadHorizontal: true,
          loadVertical: true,
          videosIds: itemsIds,
          onAllVideos: (List<VideoModel> videos) {
            if (!isClosed) {
              emit(
                state.copyWith(
                  isArticleLoading: false,
                  videos: videos,
                ),
              );
            }
          },
          onHorizontalVideos: (List<VideoModel> hVideos) {},
          onVerticalVideos: (List<VideoModel> vVideos) {},
          onDone: () {
            if (!isClosed) {
              emit(
                state.copyWith(
                  isArticleLoading: false,
                ),
              );
            }
          },
        );
      }
    }
  }

  void getAuthors() {
    final Set<String> authors = <String>{};

    for (final reply in state.replies) {
      authors.add(reply.pubkey);
    }

    for (final voteModel in state.votes.values) {
      authors.add(voteModel.pubkey);
    }
  }

  Future<void> setVote({
    required bool upvote,
    required String eventId,
    required String eventPubkey,
  }) async {
    final cancel = BotToastUtils.showLoading();

    final VoteModel? currentVoteModel = state.votes[state.currentUserPubkey];

    if (currentVoteModel == null || upvote != currentVoteModel.vote) {
      final String? addingEventId = await NostrFunctionsRepository.addVote(
        eventId: eventId,
        upvote: upvote,
        eventPubkey: eventPubkey,
        kind: curation.kind,
        identifier: curation.identifier,
        isEtag: false,
      );

      if (addingEventId != null) {
        if (currentVoteModel != null) {
          await NostrFunctionsRepository.deleteEvent(
            eventId: currentVoteModel.eventId,
          );
        }

        final Map<String, VoteModel> newMap = Map.from(state.votes);

        newMap[state.currentUserPubkey] = VoteModel(
          eventId: addingEventId,
          pubkey: state.currentUserPubkey,
          vote: upvote,
        );
        if (!isClosed) {
          emit(
            state.copyWith(votes: newMap),
          );
        }
      } else {
        BotToastUtils.showError(
          t.voteNotSubmitted.capitalizeFirst(),
        );
      }
    } else {
      final bool isSuccessful = await NostrFunctionsRepository.deleteEvent(
        eventId: currentVoteModel.eventId,
      );

      if (isSuccessful) {
        final Map<String, VoteModel> newMap = Map.from(state.votes);

        newMap.remove(currentVoteModel.pubkey);
        if (!isClosed) {
          emit(
            state.copyWith(
              votes: newMap,
            ),
          );
        }
      } else {
        BotToastUtils.showError(
          t.voteNotSubmitted.capitalizeFirst(),
        );
      }
    }

    cancel.call();
  }

  void addReply({
    required Event event,
  }) {
    if (!isClosed) {
      emit(
        state.copyWith(
          replies: List.from(state.replies)
            ..add(
              DetailedNoteModel.fromEvent(event),
            ),
        ),
      );
    }
  }

  Future<void> setFollowingState() async {
    final cancel = BotToastUtils.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowingAuthor,
      targetPubkey: state.curation.pubkey,
    );

    cancel.call();
  }

  Future<void> setAuthor() async {
    final metadata = await metadataCubit.getCachedMetadata(curation.pubkey);

    if (metadata != null) {
      if (!isClosed) {
        emit(
          state.copyWith(
            canBeZapped: metadata.lud16.isNotEmpty &&
                canSign() &&
                curation.pubkey != currentSigner!.getPublicKey(),
          ),
        );
      }

      return;
    }

    NostrFunctionsRepository.getUserMetaData(
      pubkey: curation.pubkey,
    ).listen(
      (Metadata author) {
        if (!isClosed) {
          emit(
            state.copyWith(
                canBeZapped: author.lud16.isNotEmpty &&
                    canSign() &&
                    curation.pubkey != currentSigner!.getPublicKey()),
          );
        }
      },
    );
  }

  Future<void> shareLink(RenderBox? renderBox) async {
    final res = await externalShearableLink(
      kind: curation.kind,
      pubkey: curation.pubkey,
      id: curation.identifier,
    );

    Share.share(
      res,
      subject: 'Check out www.yakihonne.com for me more articles.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  @override
  Future<void> close() {
    nc.closeRequests(requests.toList());
    muteListSubscription.cancel();
    followingsSubscription.cancel();
    return super.close();
  }
}
