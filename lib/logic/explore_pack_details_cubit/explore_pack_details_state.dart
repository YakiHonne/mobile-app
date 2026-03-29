part of 'explore_pack_details_cubit.dart';

class ExplorePackDetailsState extends Equatable {
  const ExplorePackDetailsState({
    this.ownFollowings = const [],
    this.pendings = const {},
    required this.currentUserPubKey,
  });

  final List<String> ownFollowings;
  final Set<String> pendings;
  final String currentUserPubKey;

  @override
  List<Object> get props => [ownFollowings, pendings];

  ExplorePackDetailsState copyWith({
    List<String>? ownFollowings,
    Set<String>? pendings,
    String? currentUserPubKey,
  }) {
    return ExplorePackDetailsState(
      ownFollowings: ownFollowings ?? this.ownFollowings,
      pendings: pendings ?? this.pendings,
      currentUserPubKey: currentUserPubKey ?? this.currentUserPubKey,
    );
  }
}
