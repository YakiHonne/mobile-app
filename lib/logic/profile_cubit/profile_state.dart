// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'profile_cubit.dart';

class ProfileState extends Equatable {
  final ProfileStatus profileStatus;
  final bool isLoading;
  final UpdatingState loadingState;
  final List<Event> content;
  final bool isNip05;

  final Set<String> bookmarks;
  final List<String> userRelays;
  final List<String> activeRelays;
  final List<String> ownRelays;
  final List<String> mutes;
  final int followers;
  final int followings;
  final Metadata user;
  final bool isSameUser;
  final bool isFollowingUser;
  final bool isFollowedByUser;
  final bool canBeZapped;

  final bool refresh;

  const ProfileState({
    required this.profileStatus,
    required this.isLoading,
    required this.loadingState,
    required this.content,
    required this.isNip05,
    required this.bookmarks,
    required this.userRelays,
    required this.activeRelays,
    required this.ownRelays,
    required this.mutes,
    required this.followers,
    required this.followings,
    required this.user,
    required this.isSameUser,
    required this.isFollowingUser,
    required this.isFollowedByUser,
    required this.canBeZapped,
    required this.refresh,
  });

  factory ProfileState.intial({required String pubkey}) {
    return ProfileState(
      profileStatus: ProfileStatus.loading,
      isLoading: true,
      loadingState: UpdatingState.success,
      content: const [],
      isFollowedByUser: false,
      mutes: nostrRepository.muteModel.usersMutes.toList(),
      userRelays: const [],
      canBeZapped: false,
      isFollowingUser: false,
      isNip05: false,
      isSameUser: canSign() && pubkey == currentSigner!.getPublicKey(),
      followers: 0,
      followings: 0,
      bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
      activeRelays: nc.activeRelays(),
      ownRelays: nc.relays(),
      user: Metadata.empty().copyWith(
        pubkey: pubkey,
      ),
      refresh: false,
    );
  }

  ProfileState intialData() {
    return copyWith(
      isLoading: true,
      loadingState: UpdatingState.success,
      content: const [],
    );
  }

  @override
  List<Object> get props => [
        profileStatus,
        isNip05,
        bookmarks,
        isLoading,
        loadingState,
        content,
        userRelays,
        activeRelays,
        ownRelays,
        mutes,
        followers,
        followings,
        user,
        isSameUser,
        isFollowingUser,
        isFollowedByUser,
        canBeZapped,
        refresh,
      ];

  ProfileState copyWith({
    ProfileStatus? profileStatus,
    bool? isLoading,
    UpdatingState? loadingState,
    List<Event>? content,
    bool? isNip05,
    Set<String>? bookmarks,
    List<String>? userRelays,
    List<String>? activeRelays,
    List<String>? ownRelays,
    List<String>? mutes,
    int? followers,
    int? followings,
    Metadata? user,
    bool? isSameUser,
    bool? isFollowingUser,
    bool? isFollowedByUser,
    bool? canBeZapped,
    bool? refresh,
  }) {
    return ProfileState(
      profileStatus: profileStatus ?? this.profileStatus,
      isLoading: isLoading ?? this.isLoading,
      loadingState: loadingState ?? this.loadingState,
      content: content ?? this.content,
      isNip05: isNip05 ?? this.isNip05,
      bookmarks: bookmarks ?? this.bookmarks,
      userRelays: userRelays ?? this.userRelays,
      activeRelays: activeRelays ?? this.activeRelays,
      ownRelays: ownRelays ?? this.ownRelays,
      mutes: mutes ?? this.mutes,
      followers: followers ?? this.followers,
      followings: followings ?? this.followings,
      user: user ?? this.user,
      isSameUser: isSameUser ?? this.isSameUser,
      isFollowingUser: isFollowingUser ?? this.isFollowingUser,
      isFollowedByUser: isFollowedByUser ?? this.isFollowedByUser,
      canBeZapped: canBeZapped ?? this.canBeZapped,
      refresh: refresh ?? this.refresh,
    );
  }
}
