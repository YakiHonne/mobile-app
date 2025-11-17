import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/smart_widgets_components.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'smart_widgets_state.dart';

class SmartWidgetsCubit extends Cubit<SmartWidgetsState> {
  SmartWidgetsCubit()
      : super(
          SmartWidgetsState(
            isLoading: true,
            loadingState: UpdatingState.success,
            mutes: nostrRepository.muteModel.usersMutes.toList(),
            widgets: const [],
          ),
        ) {
    getSmartWidgets(isAdd: false, isSelf: false);

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mm) {
        if (!isClosed) {
          emit(
            state.copyWith(
              mutes: mm.usersMutes.toList(),
            ),
          );
        }
      },
    );

    refreshSelfSmartWidgets = nostrRepository.refreshSelfArticlesStream.listen(
      (user) {
        getSmartWidgets(isAdd: false, isSelf: isSelfVal);
      },
    );
  }

  late StreamSubscription refreshSelfSmartWidgets;
  late StreamSubscription muteListSubscription;
  bool isSelfVal = false;

  void getSmartWidgets({required bool isAdd, required bool isSelf}) {
    final oldWidgets = List<SmartWidget>.from(state.widgets);

    if (isAdd) {
      if (!isClosed) {
        emit(
          state.copyWith(
            loadingState: UpdatingState.progress,
          ),
        );
      }
    } else {
      isSelfVal = isSelf;

      if (!isClosed) {
        emit(
          state.copyWith(
            widgets: [],
            isLoading: true,
          ),
        );
      }
    }

    List<SmartWidget> addedWidgets = [];

    NostrFunctionsRepository.getSmartWidgets(
      pubkeys: isSelfVal
          ? canSign()
              ? [currentSigner!.getPublicKey()]
              : []
          : null,
      until:
          isAdd ? state.widgets.last.createdAt.toSecondsSinceEpoch() - 1 : null,
    ).listen(
      (widgets) {
        if (isAdd) {
          addedWidgets = widgets;
          if (!isClosed) {
            emit(
              state.copyWith(
                widgets: [...oldWidgets, ...widgets],
                loadingState: UpdatingState.success,
              ),
            );
          }
        } else {
          if (!isClosed) {
            emit(
              state.copyWith(
                widgets: widgets,
                isLoading: false,
              ),
            );
          }
        }
      },
      onDone: () {
        if (!isClosed) {
          emit(
            state.copyWith(
              isLoading: false,
              loadingState:
                  isAdd && addedWidgets.isEmpty ? UpdatingState.idle : null,
            ),
          );
        }
      },
    );
  }

  Future<void> deleteSmartWidget(String eventId, Function() onSuccess) async {
    final cancel = BotToast.showLoading();

    final isSuccessful =
        await NostrFunctionsRepository.deleteEvent(eventId: eventId);

    if (isSuccessful) {
      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    cancel.call();
  }

  @override
  Future<void> close() {
    muteListSubscription.cancel();
    refreshSelfSmartWidgets.cancel();
    return super.close();
  }
}
