import 'dart:async';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../common/common_regex.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../repositories/http_functions_repository.dart';
import '../../utils/utils.dart';

part 'share_content_state.dart';

class ShareContentCubit extends Cubit<ShareContentState> {
  ShareContentCubit({
    required Color color,
    required this.url,
  }) : super(
          ShareContentState(
            isSendingToFollowings: true,
            selectedQrColor: color,
            availablePubkeys: contactListCubit.getRandomPubkeys(number: 50),
            processedPubkeys: const {},
            isSending: false,
            hasFinished: false,
          ),
        );

  final String url;
  Timer? searchOnStoppedTyping;

  Future<void> getUsers(String search) async {
    try {
      if (searchOnStoppedTyping != null) {
        searchOnStoppedTyping!.cancel();
      }

      searchOnStoppedTyping = Timer(
        const Duration(seconds: 1),
        () async {
          if (search.trim().isEmpty) {
            emit(
              state.copyWith(
                availablePubkeys: contactListCubit.getRandomPubkeys(number: 50),
              ),
            );

            return;
          }

          List<Metadata> searchedUsers = [];

          if (search.length == 64) {
            final m = await metadataCubit.getFutureMetadata(search);

            if (m != null) {
              searchedUsers.add(m);
            }
          }

          try {
            if (userRegex.hasMatch(search)) {
              final matches = userRegex.allMatches(search);

              for (final match in matches) {
                final c = match.group(0)!;

                if (c.contains('npub')) {
                  final p = Nip19.decodePubkey(c);
                  final m = await metadataCubit.getFutureMetadata(p);

                  if (m != null) {
                    searchedUsers.add(m);
                  }
                } else if (c.contains('nprofile')) {
                  final decode = Nip19.decodeShareableEntity(c);
                  final p = decode['special'] ?? decode['author'];
                  final m = await metadataCubit.getFutureMetadata(p);

                  if (m != null) {
                    searchedUsers.add(m);
                  }
                }
              }
            }
          } catch (e) {
            lg.i(e);
          }

          searchedUsers
              .addAll((await metadataCubit.searchCacheMetadatasFromContactList(
            search,
          ))
                ..where(
                  (element) => isUserMuted(element.pubkey),
                ).toList());

          final local = await metadataCubit.searchCacheMetadatas(search);
          final filteredLocal = <Metadata>[];

          for (final user in local) {
            final notAvailable = searchedUsers
                .where((Metadata element) => element.pubkey == user.pubkey)
                .isEmpty;

            if (notAvailable) {
              filteredLocal.add(user);
            }
          }

          searchedUsers = [
            ...searchedUsers,
            ...orderMetadataByScore(metadatas: filteredLocal, match: search)
          ];

          if (!isClosed) {
            final cached = orderMetadataByScore(
              metadatas: searchedUsers
                  .where((Metadata author) => !isUserMuted(author.pubkey))
                  .toList(),
              match: search,
            );

            if (!isClosed) {
              _emitState(
                state.copyWith(
                  availablePubkeys: cached
                      .map(
                        (e) => e.pubkey,
                      )
                      .toSet(),
                ),
              );
            }
          }

          final users = await HttpFunctionsRepository.getUsers(search);
          final newList = <String>{...state.availablePubkeys};

          for (final user in users) {
            final userExists =
                newList.where((element) => element == user.pubkey).isNotEmpty;

            if (!userExists && !isUserMuted(user.pubkey)) {
              newList.add(user.pubkey);
              metadataCubit.saveMetadata(user);
            }
          }

          if (!isClosed) {
            _emitState(
              state.copyWith(
                availablePubkeys: newList,
              ),
            );
          }
        },
      );
    } catch (e) {
      lg.i(e);
    }
  }

  void addPubkey(String pubkey) {
    final processedPubkeys = Map<String, ShareContentUserStatus>.from(
      state.processedPubkeys,
    );

    processedPubkeys[pubkey] = ShareContentUserStatus.idle;

    _emitState(
      state.copyWith(processedPubkeys: processedPubkeys),
    );
  }

  void removePubkey(String pubkey) {
    final processedPubkeys = Map<String, ShareContentUserStatus>.from(
      state.processedPubkeys,
    );

    processedPubkeys.remove(pubkey);

    _emitState(
      state.copyWith(processedPubkeys: processedPubkeys),
    );
  }

  void setQrColor(Color color) {
    _emitState(state.copyWith(selectedQrColor: color));
  }

  void setIsSending(bool isSending) {
    _emitState(state.copyWith(isSendingToFollowings: isSending));
  }

  Future<void> sendUrl(String message) async {
    final toBeSendMessage = message.trim().isNotEmpty ? '$message $url' : url;

    final processedPubkeys = Map<String, ShareContentUserStatus>.from(
      state.processedPubkeys,
    );

    processedPubkeys.updateAll(
      (key, value) => ShareContentUserStatus.sending,
    );

    _emitState(
      state.copyWith(
        isSending: true,
        processedPubkeys: processedPubkeys,
      ),
    );

    for (final p in processedPubkeys.entries) {
      bool isSuccessful = false;

      await dmsCubit.sendEvent(
        p.key,
        toBeSendMessage,
        '',
        () {
          isSuccessful = true;
        },
      );

      processedPubkeys[p.key] = isSuccessful
          ? ShareContentUserStatus.success
          : ShareContentUserStatus.failure;

      _emitState(
        state.copyWith(
          processedPubkeys: processedPubkeys,
        ),
      );
    }

    _emitState(
      state.copyWith(
        processedPubkeys: processedPubkeys,
        hasFinished: true,
        isSending: false,
      ),
    );
  }

  void refresh() {
    _emitState(
      state.copyWith(
        isSending: false,
        processedPubkeys: {},
        hasFinished: false,
      ),
    );
  }

  void _emitState(ShareContentState state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
