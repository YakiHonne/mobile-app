// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'rewards_cubit.dart';

class RewardsState extends Equatable {
  final List<RewardModel> rewards;
  final bool refresh;
  final UpdatingState updatingState;
  final Set<String> loadingClaims;
  final num initRatingPrice;
  final num initNotePrice;
  final num sealedRatingPrice;
  final num sealedNotePrice;

  const RewardsState({
    required this.rewards,
    required this.refresh,
    required this.updatingState,
    required this.loadingClaims,
    required this.initRatingPrice,
    required this.initNotePrice,
    required this.sealedRatingPrice,
    required this.sealedNotePrice,
  });

  @override
  List<Object> get props => [
        rewards,
        refresh,
        updatingState,
        loadingClaims,
        initRatingPrice,
        initNotePrice,
        sealedRatingPrice,
        sealedNotePrice,
      ];

  RewardsState copyWith({
    List<RewardModel>? rewards,
    bool? refresh,
    UpdatingState? updatingState,
    Set<String>? loadingClaims,
    num? initRatingPrice,
    num? initNotePrice,
    num? sealedRatingPrice,
    num? sealedNotePrice,
  }) {
    return RewardsState(
      rewards: rewards ?? this.rewards,
      refresh: refresh ?? this.refresh,
      updatingState: updatingState ?? this.updatingState,
      loadingClaims: loadingClaims ?? this.loadingClaims,
      initRatingPrice: initRatingPrice ?? this.initRatingPrice,
      initNotePrice: initNotePrice ?? this.initNotePrice,
      sealedRatingPrice: sealedRatingPrice ?? this.sealedRatingPrice,
      sealedNotePrice: sealedNotePrice ?? this.sealedNotePrice,
    );
  }
}
