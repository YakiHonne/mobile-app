// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'profile_cubit.dart';

class ProfileState extends Equatable {
  final ProfileStatus profileStatus;
  final bool isArticlesLoading;
  final bool isVideoLoading;
  final bool isRelaysLoading;
  final bool isNotesLoading;
  final bool isRepliesLoading;
  final bool isSmartWidgetsLoading;
  final bool isNip05;
  final UpdatingState notesLoading;
  final UpdatingState repliesLoading;
  final List<Article> articles;
  final List<Curation> curations;
  final List<VideoModel> videos;
  final List<SmartWidget> smartWidgets;
  final List<Event> notes;
  final List<Event> replies;
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

  final num writingImpact;
  final num positiveWritingImpact;
  final num negativeWritingImpact;
  final num ongoingWritingImpact;
  final num ratingImpact;
  final num positiveRatingImpactH;
  final num positiveRatingImpactNh;
  final num negativeRatingImpactH;
  final num negativeRatingImpactNh;
  final num ongoingRatingImpact;
  final bool refresh;

  const ProfileState({
    required this.profileStatus,
    required this.isArticlesLoading,
    required this.isVideoLoading,
    required this.isRelaysLoading,
    required this.isNotesLoading,
    required this.isRepliesLoading,
    required this.isSmartWidgetsLoading,
    required this.isNip05,
    required this.notesLoading,
    required this.repliesLoading,
    required this.articles,
    required this.curations,
    required this.videos,
    required this.smartWidgets,
    required this.notes,
    required this.replies,
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
    required this.writingImpact,
    required this.positiveWritingImpact,
    required this.negativeWritingImpact,
    required this.ongoingWritingImpact,
    required this.ratingImpact,
    required this.positiveRatingImpactH,
    required this.positiveRatingImpactNh,
    required this.negativeRatingImpactH,
    required this.negativeRatingImpactNh,
    required this.ongoingRatingImpact,
    required this.refresh,
  });

  @override
  List<Object> get props => [
        profileStatus,
        isArticlesLoading,
        isVideoLoading,
        isRelaysLoading,
        isNotesLoading,
        isRepliesLoading,
        isSmartWidgetsLoading,
        isNip05,
        notesLoading,
        repliesLoading,
        articles,
        curations,
        videos,
        smartWidgets,
        notes,
        replies,
        bookmarks,
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
        writingImpact,
        positiveWritingImpact,
        negativeWritingImpact,
        ongoingWritingImpact,
        ratingImpact,
        positiveRatingImpactH,
        positiveRatingImpactNh,
        negativeRatingImpactH,
        negativeRatingImpactNh,
        ongoingRatingImpact,
        refresh,
      ];

  ProfileState copyWith({
    ProfileStatus? profileStatus,
    bool? isArticlesLoading,
    bool? isVideoLoading,
    bool? isRelaysLoading,
    bool? isNotesLoading,
    bool? isRepliesLoading,
    bool? isSmartWidgetsLoading,
    bool? isNip05,
    UpdatingState? notesLoading,
    UpdatingState? repliesLoading,
    List<Article>? articles,
    List<Curation>? curations,
    List<VideoModel>? videos,
    List<SmartWidget>? smartWidgets,
    List<Event>? notes,
    List<Event>? replies,
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
    num? writingImpact,
    num? positiveWritingImpact,
    num? negativeWritingImpact,
    num? ongoingWritingImpact,
    num? ratingImpact,
    num? positiveRatingImpactH,
    num? positiveRatingImpactNh,
    num? negativeRatingImpactH,
    num? negativeRatingImpactNh,
    num? ongoingRatingImpact,
    bool? refresh,
  }) {
    return ProfileState(
      profileStatus: profileStatus ?? this.profileStatus,
      isArticlesLoading: isArticlesLoading ?? this.isArticlesLoading,
      isVideoLoading: isVideoLoading ?? this.isVideoLoading,
      isRelaysLoading: isRelaysLoading ?? this.isRelaysLoading,
      isNotesLoading: isNotesLoading ?? this.isNotesLoading,
      isRepliesLoading: isRepliesLoading ?? this.isRepliesLoading,
      isSmartWidgetsLoading:
          isSmartWidgetsLoading ?? this.isSmartWidgetsLoading,
      isNip05: isNip05 ?? this.isNip05,
      notesLoading: notesLoading ?? this.notesLoading,
      repliesLoading: repliesLoading ?? this.repliesLoading,
      articles: articles ?? this.articles,
      curations: curations ?? this.curations,
      videos: videos ?? this.videos,
      smartWidgets: smartWidgets ?? this.smartWidgets,
      notes: notes ?? this.notes,
      replies: replies ?? this.replies,
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
      writingImpact: writingImpact ?? this.writingImpact,
      positiveWritingImpact:
          positiveWritingImpact ?? this.positiveWritingImpact,
      negativeWritingImpact:
          negativeWritingImpact ?? this.negativeWritingImpact,
      ongoingWritingImpact: ongoingWritingImpact ?? this.ongoingWritingImpact,
      ratingImpact: ratingImpact ?? this.ratingImpact,
      positiveRatingImpactH:
          positiveRatingImpactH ?? this.positiveRatingImpactH,
      positiveRatingImpactNh:
          positiveRatingImpactNh ?? this.positiveRatingImpactNh,
      negativeRatingImpactH:
          negativeRatingImpactH ?? this.negativeRatingImpactH,
      negativeRatingImpactNh:
          negativeRatingImpactNh ?? this.negativeRatingImpactNh,
      ongoingRatingImpact: ongoingRatingImpact ?? this.ongoingRatingImpact,
      refresh: refresh ?? this.refresh,
    );
  }
}
