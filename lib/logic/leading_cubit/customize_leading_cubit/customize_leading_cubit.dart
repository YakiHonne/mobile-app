import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'customize_leading_state.dart';

class CustomizeLeadingCubit extends Cubit<CustomizeLeadingState> {
  CustomizeLeadingCubit()
      : super(
          const CustomizeLeadingState(
            feedTypes: {},
            showSuggestions: true,
            refresh: true,
            showInterests: true,
            showPeopleToFollow: true,
            showRelatedContent: true,
            useSingleColumnFeed: false,
            collapseNote: true,
          ),
        ) {
    init();
  }

  bool isUpdated = false;

  void init() {
    final feedTypes = <CommonFeedTypes, bool>{};

    final savedTypes =
        nostrRepository.currentAppCustomization!.leadingFeedCustomization;

    for (final st in savedTypes.entries) {
      feedTypes[nostrRepository.getCommonFeedType(st.key)] = st.value;
    }

    final c = nostrRepository.currentAppCustomization!;
    if (!isClosed) {
      emit(
        state.copyWith(
          feedTypes: feedTypes,
          showSuggestions: c.showLeadingSuggestions,
          showInterests: c.showSuggestedInterests,
          showPeopleToFollow: c.showTrendingUsers,
          showRelatedContent: c.showRelatedContent,
          useSingleColumnFeed: c.useSingleColumnFeed,
          collapseNote: c.collapsedNote,
        ),
      );
    }
  }

  void setSuggestionStatus() {
    isUpdated = true;
    if (!isClosed) {
      emit(
        state.copyWith(
          showSuggestions: !state.showSuggestions,
        ),
      );
    }
  }

  void setPeopleStatus() {
    isUpdated = true;
    if (!isClosed) {
      emit(
        state.copyWith(
          showPeopleToFollow: !state.showPeopleToFollow,
        ),
      );
    }
  }

  void setInterestsStatus() {
    isUpdated = true;
    if (!isClosed) {
      emit(
        state.copyWith(
          showInterests: !state.showInterests,
        ),
      );
    }
  }

  void setColumnFeedStatus() {
    isUpdated = true;
    if (!isClosed) {
      emit(
        state.copyWith(
          useSingleColumnFeed: !state.useSingleColumnFeed,
        ),
      );
    }
  }

  void setCollapseNoteStatus() {
    isUpdated = true;
    if (!isClosed) {
      emit(
        state.copyWith(
          collapseNote: !state.collapseNote,
        ),
      );
    }
  }

  void setRelatedContentStatus() {
    isUpdated = true;
    if (!isClosed) {
      emit(
        state.copyWith(
          showRelatedContent: !state.showRelatedContent,
        ),
      );
    }
  }

  void setCommenFeedType(CommonFeedTypes type) {
    isUpdated = true;
    bool canBeUpdated = true;

    if (state.feedTypes[type]! &&
        state.feedTypes.values
                .where(
                  (element) => element,
                )
                .length ==
            1) {
      canBeUpdated = false;
      BotToastUtils.showError(
        t.oneFeedOptionAvailable.capitalizeFirst(),
      );
      return;
    }

    if (canBeUpdated) {
      final clone = Map<CommonFeedTypes, bool>.from(state.feedTypes);
      clone[type] = !clone[type]!;
      if (!isClosed) {
        emit(
          state.copyWith(
            feedTypes: clone,
          ),
        );
      }
    }
  }

  void setFeedTypesNewOrder(int oldIndex, int newIndex) {
    isUpdated = true;
    final entries =
        List<MapEntry<CommonFeedTypes, bool>>.from(state.feedTypes.entries);

    final video = entries.removeAt(oldIndex);
    entries.insert(newIndex, video);
    final newFeed = {for (final entry in entries) entry.key: entry.value};

    if (!isClosed) {
      emit(
        state.copyWith(
          feedTypes: newFeed,
          refresh: !state.refresh,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    if (isUpdated) {
      final c = nostrRepository.currentAppCustomization;
      c!.showLeadingSuggestions = state.showSuggestions;
      c.showTrendingUsers = state.showPeopleToFollow;
      c.showRelatedContent = state.showRelatedContent;
      c.showSuggestedInterests = state.showInterests;
      c.useSingleColumnFeed = state.useSingleColumnFeed;
      c.collapsedNote = state.collapseNote;

      c.leadingFeedCustomization = {
        for (final c in state.feedTypes.entries) c.key.name: c.value
      };

      nostrRepository.appCustomizations[c.pubkey] = c;

      nostrRepository.broadcastCurrentAppCustomization();
      nostrRepository.saveAppCustomization();
    }

    return super.close();
  }
}
