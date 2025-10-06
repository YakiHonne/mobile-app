// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'profile_follow_authors_cubit.dart';

class ProfileFollowAuthorsState extends Equatable {
  final List<String> followers;
  final List<String> followings;
  final bool isFollowersLoading;
  final bool isFollowingLoading;
  final bool isFollowers;
  final bool isValidUser;
  final List<String> ownFollowings;
  final String currentUserPubKey;
  final Set<String> pendings;

  const ProfileFollowAuthorsState({
    required this.followers,
    required this.followings,
    required this.isFollowersLoading,
    required this.isFollowingLoading,
    required this.isFollowers,
    required this.isValidUser,
    required this.ownFollowings,
    required this.currentUserPubKey,
    required this.pendings,
  });

  @override
  List<Object> get props => [
        followers,
        followings,
        isFollowersLoading,
        isFollowingLoading,
        isFollowers,
        ownFollowings,
        isValidUser,
        currentUserPubKey,
        pendings,
      ];

  ProfileFollowAuthorsState copyWith({
    List<String>? followers,
    List<String>? followings,
    bool? isFollowersLoading,
    bool? isFollowingLoading,
    bool? isFollowers,
    bool? isValidUser,
    List<String>? ownFollowings,
    String? currentUserPubKey,
    Set<String>? pendings,
  }) {
    return ProfileFollowAuthorsState(
      followers: followers ?? this.followers,
      followings: followings ?? this.followings,
      isFollowersLoading: isFollowersLoading ?? this.isFollowersLoading,
      isFollowingLoading: isFollowingLoading ?? this.isFollowingLoading,
      isFollowers: isFollowers ?? this.isFollowers,
      isValidUser: isValidUser ?? this.isValidUser,
      ownFollowings: ownFollowings ?? this.ownFollowings,
      currentUserPubKey: currentUserPubKey ?? this.currentUserPubKey,
      pendings: pendings ?? this.pendings,
    );
  }
}
