// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'polls_cubit.dart';

class PollsState extends Equatable {
  final List<PollModel> polls;
  final bool isLoading;
  final UpdatingState loadingState;
  final List<String> mutes;

  const PollsState({
    required this.polls,
    required this.isLoading,
    required this.loadingState,
    required this.mutes,
  });

  @override
  List<Object> get props => [
        polls,
        isLoading,
        loadingState,
        mutes,
      ];

  PollsState copyWith({
    List<PollModel>? polls,
    bool? isLoading,
    UpdatingState? loadingState,
    List<String>? mutes,
  }) {
    return PollsState(
      polls: polls ?? this.polls,
      isLoading: isLoading ?? this.isLoading,
      loadingState: loadingState ?? this.loadingState,
      mutes: mutes ?? this.mutes,
    );
  }
}
