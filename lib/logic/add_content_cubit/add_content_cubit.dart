import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/utils.dart';

part 'add_content_state.dart';

class AddContentCubit extends Cubit<AddContentState> {
  AddContentCubit({AppContentType? appContentType})
      : super(
          AddContentState(
            appContentType: appContentType ?? AppContentType.note,
            displayBottomNavigationBar: appContentType == null,
          ),
        ) {
    userDraftsChanges = nostrRepository.userDraftChangesStream.listen(
      (event) {
        if (!isClosed) {
          emit(
            state.copyWith(
              displayBottomNavigationBar: false,
            ),
          );
        }
      },
    );
  }

  late StreamSubscription userDraftsChanges;

  void setAppContentType(AppContentType type) {
    if (!isClosed) {
      emit(
        state.copyWith(
          appContentType: type,
        ),
      );
    }
  }

  void setBottomNavigationBarState(bool st) {
    if (!isClosed) {
      emit(
        state.copyWith(
          displayBottomNavigationBar: st,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    userDraftsChanges.cancel();
    return super.close();
  }
}
