import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState(index: 0));

  void increaseIndex() {
    if (!isClosed) {
      emit(
        state.copyWith(
          index: state.index + 1,
        ),
      );
    }
  }

  void decreaseIndex() {
    if (!isClosed) {
      emit(
        state.copyWith(
          index: state.index - 1,
        ),
      );
    }
  }

  void chec() {
    if (!isClosed) {
      emit(
        state.copyWith(
          index: state.index - 1,
        ),
      );
    }
  }
}
