import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/flash_news_model.dart';
import '../../models/packs_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/enums.dart';

part 'pack_feed_state.dart';

class PackFeedCubit extends Cubit<PackFeedState> {
  PackFeedCubit({
    required this.packsModel,
  }) : super(
          const PackFeedState(
            content: [],
            onLoading: true,
            onAddingData: UpdatingState.success,
            refresh: false,
          ),
        );

  final PacksModel packsModel;

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

  Future<void> buildPackFeed({
    required RelayContentType type,
    required bool isAdding,
  }) async {
    final pubkeys = packsModel.pubkeys.take(50);

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

    final events = await NostrFunctionsRepository.getEventsAsync(
      until: until,
      limit: 50,
      kinds: [
        if (type == RelayContentType.notes) EventKind.TEXT_NOTE,
        if (type == RelayContentType.articles) EventKind.LONG_FORM,
        if (type == RelayContentType.curations) ...[
          EventKind.CURATION_ARTICLES,
          EventKind.CURATION_VIDEOS,
        ],
        if (type == RelayContentType.media) ...[
          EventKind.VIDEO_HORIZONTAL,
          EventKind.VIDEO_VERTICAL,
          EventKind.LEGACY_VIDEO_HORIZONTAL,
          EventKind.LEGACY_VIDEO_VERTICAL,
          EventKind.PICTURE,
        ],
      ],
      pubkeys: pubkeys.toList(),
    );

    final content = <BaseEventModel>[];

    for (final e in events) {
      final baseEventModel = getBaseEventModel(e);

      if (baseEventModel != null) {
        content.add(baseEventModel);
      }
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [
            ...state.content,
            ...content,
          ],
          onLoading: false,
          onAddingData:
              content.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }
}
