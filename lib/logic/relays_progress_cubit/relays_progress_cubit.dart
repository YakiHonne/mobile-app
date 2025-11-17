import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/utils.dart';

part 'relays_progress_state.dart';

class RelaysProgressCubit extends Cubit<RelaysProgressState> {
  RelaysProgressCubit()
      : super(
          RelaysProgressState(
            isProgressVisible: false,
            isRelaysVisible: false,
            totalRelays: nc.relays(),
            successfulRelays: const [],
          ),
        );

  Map<String, DateTime> requests = {};

  Future<void> setRelays({
    required String requestId,
    required List<String> incompleteRelays,
    List<String>? chosenTotalRelays,
  }) async {
    bool canProceed = true;
    final requestDate = requests[requestId];

    if (requestDate == null) {
      requests[requestId] = DateTime.now();
    } else {
      for (final request in requests.values) {
        if (request.compareTo(requestDate) > 0) {
          canProceed = false;
        }
      }
    }

    if (canProceed) {
      final totalRelays = chosenTotalRelays ?? nc.relays();
      final successfulRelays = totalRelays
          .where((element) => !incompleteRelays.contains(element))
          .toList();

      if (!isClosed) {
        emit(
          state.copyWith(
            isProgressVisible: true,
            totalRelays: totalRelays,
            successfulRelays: successfulRelays,
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 3)).then(
        (value) {
          if (!state.isRelaysVisible) {
            dismissProgressBar();
          }
        },
      );
    }
  }

  void setRelaysListVisibility(bool visibility) {
    if (!isClosed) {
      emit(
        state.copyWith(
          isRelaysVisible: visibility,
          isProgressVisible: !visibility ? false : null,
        ),
      );
    }
  }

  void dismissProgressBar() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isProgressVisible: false,
          isRelaysVisible: false,
        ),
      );
    }
  }
}
