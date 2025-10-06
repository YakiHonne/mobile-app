import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../repositories/http_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'search_user_state.dart';

class SearchUserCubit extends Cubit<SearchUserState> {
  SearchUserCubit()
      : super(
          const SearchUserState(
            authors: [],
            isLoading: false,
          ),
        );

  void emptyAuthorsList() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isLoading: false,
          authors: [],
        ),
      );
    }
  }

  Future<void> getAuthors(
    String search,
    Function(Metadata) onUserSelected,
  ) async {
    try {
      if (search.startsWith('npub') ||
          search.startsWith('nprofile') ||
          search.length == 64) {
        if (!isClosed) {
          emit(state.copyWith(isLoading: true));
        }

        try {
          final hex = search.startsWith('npub')
              ? Nip19.decodePubkey(search)
              : search.startsWith('nprofile')
                  ? Nip19.decodeShareableEntity(search)['special']
                  : search;

          final user = await metadataCubit.getFutureMetadata(hex);

          if (user != null) {
            onUserSelected.call(user);
          } else {
            onUserSelected.call(
              Metadata.empty().copyWith(
                pubkey: hex,
              ),
            );
          }
          if (!isClosed) {
            emit(state.copyWith(isLoading: false));
          }
        } catch (_) {
          BotToastUtils.showError(
            t.errorDecodingData.capitalizeFirst(),
          );
          if (!isClosed) {
            emit(state.copyWith(isLoading: false));
          }
          return;
        }
      } else {
        if (!isClosed) {
          emit(
            state.copyWith(
              isLoading: true,
            ),
          );
        }

        final searchedUsers = (await metadataCubit.searchCacheMetadatas(search))
          ..where((author) => !nostrRepository.mutes.contains(author.pubkey))
              .toList();

        if (!isClosed) {
          emit(
            state.copyWith(
              authors: searchedUsers,
              isLoading: searchedUsers.isEmpty,
            ),
          );
        }

        final users = await HttpFunctionsRepository.getUsers(search);
        final newList = <Metadata>[...state.authors];

        for (final user in users) {
          final userExists = newList
              .where((element) => element.pubkey == user.pubkey)
              .isNotEmpty;

          if (!userExists && !nostrRepository.mutes.contains(user.pubkey)) {
            newList.add(user);
            metadataCubit.saveMetadata(user);
          }
        }

        newList.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );

        if (!isClosed) {
          emit(
            state.copyWith(
              authors: newList,
              isLoading: false,
            ),
          );
        }
      }
    } catch (e) {
      Logger().i(e);
    }
  }
}
