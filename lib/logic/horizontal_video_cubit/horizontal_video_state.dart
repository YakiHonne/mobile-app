// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'horizontal_video_cubit.dart';

class HorizontalVideoState extends Equatable {
  final Metadata author;
  final VideoModel video;
  final String currentUserPubkey;
  final bool isSameArticleAuthor;
  final bool isFollowingAuthor;
  final bool canBeZapped;
  final bool isLoading;
  final bool isBookmarked;
  final bool refresh;
  final Map<String, double> zaps;
  final Set<String> reports;
  final Map<String, VoteModel> votes;
  final List<DetailedNoteModel> replies;
  final List<String> mutes;
  final List<String> viewsCount;

  const HorizontalVideoState({
    required this.author,
    required this.video,
    required this.currentUserPubkey,
    required this.isSameArticleAuthor,
    required this.isFollowingAuthor,
    required this.canBeZapped,
    required this.isLoading,
    required this.isBookmarked,
    required this.refresh,
    required this.zaps,
    required this.reports,
    required this.votes,
    required this.replies,
    required this.mutes,
    required this.viewsCount,
  });

  @override
  List<Object> get props => [
        author,
        video,
        currentUserPubkey,
        isSameArticleAuthor,
        isFollowingAuthor,
        canBeZapped,
        isLoading,
        isBookmarked,
        refresh,
        zaps,
        reports,
        votes,
        replies,
        mutes,
        viewsCount,
      ];

  HorizontalVideoState copyWith({
    Metadata? author,
    VideoModel? video,
    String? currentUserPubkey,
    bool? isSameArticleAuthor,
    bool? isFollowingAuthor,
    bool? canBeZapped,
    bool? isLoading,
    bool? isBookmarked,
    bool? refresh,
    Map<String, double>? zaps,
    Set<String>? reports,
    Map<String, VoteModel>? votes,
    List<DetailedNoteModel>? replies,
    List<String>? mutes,
    List<String>? viewsCount,
  }) {
    return HorizontalVideoState(
      author: author ?? this.author,
      video: video ?? this.video,
      currentUserPubkey: currentUserPubkey ?? this.currentUserPubkey,
      isSameArticleAuthor: isSameArticleAuthor ?? this.isSameArticleAuthor,
      isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
      canBeZapped: canBeZapped ?? this.canBeZapped,
      isLoading: isLoading ?? this.isLoading,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      refresh: refresh ?? this.refresh,
      zaps: zaps ?? this.zaps,
      reports: reports ?? this.reports,
      votes: votes ?? this.votes,
      replies: replies ?? this.replies,
      mutes: mutes ?? this.mutes,
      viewsCount: viewsCount ?? this.viewsCount,
    );
  }
}
