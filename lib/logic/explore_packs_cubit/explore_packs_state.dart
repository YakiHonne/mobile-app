part of 'explore_packs_cubit.dart';

class ExplorePacksState extends Equatable {
  const ExplorePacksState({
    required this.isLoading,
    required this.updatingState,
    required this.packs,
    required this.pendings,
    required this.currentUserPubKey,
    required this.ownFollowings,
  });

  final bool isLoading;
  final UpdatingState updatingState;
  final List<PacksModel> packs;
  final Set<String> pendings;
  final String currentUserPubKey;
  final List<String> ownFollowings;

  @override
  List<Object> get props => [
        isLoading,
        updatingState,
        packs,
        pendings,
        currentUserPubKey,
        ownFollowings,
      ];

  ExplorePacksState copyWith({
    bool? isLoading,
    UpdatingState? updatingState,
    List<PacksModel>? packs,
    Set<String>? pendings,
    String? currentUserPubKey,
    List<String>? ownFollowings,
  }) {
    return ExplorePacksState(
      isLoading: isLoading ?? this.isLoading,
      updatingState: updatingState ?? this.updatingState,
      packs: packs ?? this.packs,
      pendings: pendings ?? this.pendings,
      currentUserPubKey: currentUserPubKey ?? this.currentUserPubKey,
      ownFollowings: ownFollowings ?? this.ownFollowings,
    );
  }
}
