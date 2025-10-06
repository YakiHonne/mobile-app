// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'profile_fast_access_cubit.dart';

class ProfileFastAccessState extends Equatable {
  final Set<String> commonPubkeys;
  final int followersCount;
  final bool isFollowing;
  final bool refresh;

  const ProfileFastAccessState({
    required this.commonPubkeys,
    required this.followersCount,
    required this.isFollowing,
    required this.refresh,
  });

  @override
  List<Object> get props => [
        commonPubkeys,
        isFollowing,
        followersCount,
        refresh,
      ];

  ProfileFastAccessState copyWith({
    Set<String>? commonPubkeys,
    int? followersCount,
    bool? isFollowing,
    bool? refresh,
  }) {
    return ProfileFastAccessState(
      commonPubkeys: commonPubkeys ?? this.commonPubkeys,
      followersCount: followersCount ?? this.followersCount,
      isFollowing: isFollowing ?? this.isFollowing,
      refresh: refresh ?? this.refresh,
    );
  }
}
