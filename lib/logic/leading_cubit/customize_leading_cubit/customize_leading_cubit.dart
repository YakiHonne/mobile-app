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
            hideNonFollowedMedia: true,
            actionsArrangement: defaultActionsArrangement,
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
          actionsArrangement: c.actionsArrangement,
          hideNonFollowedMedia: c.hideNonFollowingMedia,
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

  void setHideNonFollowedMedia() {
    isUpdated = true;
    if (!isClosed) {
      emit(
        state.copyWith(
          hideNonFollowedMedia: !state.hideNonFollowedMedia,
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

  void setActionsNewOrder(int oldIndex, int newIndex) {
    isUpdated = true;
    final actions =
        List<MapEntry<String, bool>>.from(state.actionsArrangement.entries);

    final action = actions.removeAt(oldIndex);
    actions.insert(newIndex, action);

    if (!isClosed) {
      emit(
        state.copyWith(
          actionsArrangement: Map.fromEntries(actions),
          refresh: !state.refresh,
        ),
      );
    }
  }

  void setActionStatus(String action) {
    isUpdated = true;
    final actions = Map<String, bool>.from(state.actionsArrangement);

    actions[action] = !actions[action]!;

    if (!isClosed) {
      emit(
        state.copyWith(
          actionsArrangement: actions,
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
      c.actionsArrangement = state.actionsArrangement;
      c.hideNonFollowingMedia = state.hideNonFollowedMedia;
      lg.i(state.actionsArrangement);

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
