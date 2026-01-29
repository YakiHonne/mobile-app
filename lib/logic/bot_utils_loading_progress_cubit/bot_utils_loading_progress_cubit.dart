import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'bot_utils_loading_progress_state.dart';

class BotUtilsLoadingProgressCubit extends Cubit<BotUtilsLoadingProgressState> {
  BotUtilsLoadingProgressCubit()
      : super(
          const BotUtilsLoadingProgressState(status: ''),
        );

  void emitStatus(String status) {
    if (!isClosed) {
      emit(state.copyWith(status: status));
    }
  }
}
