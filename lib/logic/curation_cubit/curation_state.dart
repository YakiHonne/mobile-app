// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'curation_cubit.dart';

class CurationState extends Equatable {
  final Curation curation;
  final bool isArticleLoading;
  final bool refresh;
  final List<Article> articles;
  final List<VideoModel> videos;
  final bool isValidUser;
  final bool isSameCurationAuthor;
  final String currentUserPubkey;
  final bool isFollowingAuthor;
  final bool canBeZapped;
  final bool isBookmarked;
  final Map<String, double> zaps;
  final Map<String, VoteModel> votes;
  final Set<String> reports;
  final List<String> mutes;
  final List<DetailedNoteModel> replies;
  final bool isArticlesCuration;

  const CurationState({
    required this.curation,
    required this.isArticleLoading,
    required this.refresh,
    required this.articles,
    required this.videos,
    required this.isValidUser,
    required this.isSameCurationAuthor,
    required this.currentUserPubkey,
    required this.isFollowingAuthor,
    required this.canBeZapped,
    required this.isBookmarked,
    required this.zaps,
    required this.votes,
    required this.reports,
    required this.mutes,
    required this.replies,
    required this.isArticlesCuration,
  });

  @override
  List<Object> get props => [
        isArticleLoading,
        articles,
        curation,
        currentUserPubkey,
        canBeZapped,
        refresh,
        isBookmarked,
        zaps,
        votes,
        reports,
        replies,
        isValidUser,
        isSameCurationAuthor,
        mutes,
        videos,
        isArticlesCuration,
        isFollowingAuthor,
      ];

  CurationState copyWith({
    Curation? curation,
    bool? isArticleLoading,
    bool? refresh,
    List<Article>? articles,
    List<VideoModel>? videos,
    bool? isValidUser,
    bool? isSameCurationAuthor,
    String? currentUserPubkey,
    bool? isFollowingAuthor,
    bool? canBeZapped,
    bool? isBookmarked,
    Map<String, double>? zaps,
    Map<String, VoteModel>? votes,
    Set<String>? reports,
    List<String>? mutes,
    List<DetailedNoteModel>? replies,
    bool? isArticlesCuration,
  }) {
    return CurationState(
      curation: curation ?? this.curation,
      isArticleLoading: isArticleLoading ?? this.isArticleLoading,
      refresh: refresh ?? this.refresh,
      articles: articles ?? this.articles,
      videos: videos ?? this.videos,
      isValidUser: isValidUser ?? this.isValidUser,
      isSameCurationAuthor: isSameCurationAuthor ?? this.isSameCurationAuthor,
      currentUserPubkey: currentUserPubkey ?? this.currentUserPubkey,
      isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
      canBeZapped: canBeZapped ?? this.canBeZapped,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      zaps: zaps ?? this.zaps,
      votes: votes ?? this.votes,
      reports: reports ?? this.reports,
      mutes: mutes ?? this.mutes,
      replies: replies ?? this.replies,
      isArticlesCuration: isArticlesCuration ?? this.isArticlesCuration,
    );
  }
}
