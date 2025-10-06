import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/utils.dart';

part 'routing_state.dart';

class RoutingCubit extends Cubit<RoutingState> {
  RoutingCubit()
      : super(
          const RoutingState(
            currentRoute: CurrentRoute.logify,
            updatingState: UpdatingState.progress,
          ),
        ) {
    routingViewInit();
  }

  StreamController controller = StreamController();
  late StreamSubscription _sub;

  Future<void> routingViewInit() async {
    if (!isClosed) {
      if (!isClosed) {
        emit(
          state.copyWith(
            updatingState: UpdatingState.progress,
          ),
        );
      }
    }

    try {
      final onboardingStatus =
          await localDatabaseRepository.getOnboardingStatus();

      if (onboardingStatus) {
        if (!isClosed) {
          emit(
            state.copyWith(
              currentRoute: CurrentRoute.logify,
              updatingState: UpdatingState.idle,
            ),
          );
        }

        return;
      }

      final disclosureStatus =
          await localDatabaseRepository.getDisclosureStatus();

      if (disclosureStatus) {
        if (!isClosed) {
          emit(
            state.copyWith(
              currentRoute: CurrentRoute.disclosure,
              updatingState: UpdatingState.idle,
            ),
          );
        }

        return;
      }

      if (!isClosed) {
        emit(
          state.copyWith(
            updatingState: UpdatingState.idle,
            currentRoute: CurrentRoute.main,
          ),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        if (!isClosed) {
          emit(
            state.copyWith(
              updatingState: UpdatingState.networkFailure,
            ),
          );
        }
      } else {
        if (!isClosed) {
          emit(
            state.copyWith(
              updatingState: UpdatingState.failure,
            ),
          );
        }
      }
    }
  }

  void setDisclosureView() {
    if (!isClosed) {
      emit(
        state.copyWith(
          currentRoute: CurrentRoute.disclosure,
          updatingState: UpdatingState.idle,
        ),
      );
    }
  }

  void setMainView() {
    if (!isClosed) {
      emit(
        state.copyWith(currentRoute: CurrentRoute.main),
      );
    }
  }

  @override
  Future<void> close() {
    controller.close();
    _sub.cancel();
    return super.close();
  }
}
