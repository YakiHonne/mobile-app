import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/flash_news_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'relay_feed_state.dart';

class RelayFeedCubit extends Cubit<RelayFeedState> {
  RelayFeedCubit({required this.relay})
      : super(
          const RelayFeedState(
            content: [],
            onAddingData: UpdatingState.success,
            onLoading: true,
            refresh: false,
          ),
        );

  String relay;
  bool removeUponDisposal = false;

  Future<void> initView() async {
    if (!nc.activeRelays().contains(relay)) {
      await nc.connect(
        relay,
        waitForAuth: relay.contains('nostr.wine') ? true : null,
      );

      removeUponDisposal = true;
    }

    buildRelayFeed(type: RelayContentType.notes, isAdding: false);
  }

  void clearData() {
    if (!isClosed) {
      emit(
        state.copyWith(
          content: [],
          onAddingData: UpdatingState.success,
          onLoading: true,
        ),
      );
    }
  }

  Future<void> buildRelayFeed({
    required RelayContentType type,
    required bool isAdding,
  }) async {
    if (!isAdding) {
      clearData();
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(
            onAddingData: UpdatingState.progress,
          ),
        );
      }
    }

    final until = state.content.isNotEmpty
        ? state.content.last.createdAt.toSecondsSinceEpoch() - 1
        : null;

    final content = await NostrFunctionsRepository.buildSingleRelayFeed(
      until: until,
      limit: 50,
      type: type,
      relay: relay,
    );

    lg.i(content);

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [...state.content, ...content],
          onLoading: false,
          onAddingData:
              content.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    if (removeUponDisposal) {
      nc.closeConnect([relay]);
    }

    return super.close();
  }
}
