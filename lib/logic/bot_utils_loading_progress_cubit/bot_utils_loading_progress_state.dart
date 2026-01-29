part of 'bot_utils_loading_progress_cubit.dart';

class BotUtilsLoadingProgressState extends Equatable {
  const BotUtilsLoadingProgressState({
    required this.status,
  });

  final String status;

  @override
  List<Object> get props => [status];

  BotUtilsLoadingProgressState copyWith({
    String? status,
  }) {
    return BotUtilsLoadingProgressState(
      status: status ?? this.status,
    );
  }
}
