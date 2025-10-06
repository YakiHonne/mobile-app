// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'article_cubit.dart';

class ArticleState extends Equatable {
  final Metadata metadata;
  final Article article;
  final String currentUserPubkey;
  final bool isSameArticleAuthor;
  final bool isFollowingAuthor;
  final bool canBeZapped;
  final bool isLoading;
  final bool isBookmarked;
  final bool refresh;

  const ArticleState({
    required this.metadata,
    required this.article,
    required this.currentUserPubkey,
    required this.isSameArticleAuthor,
    required this.isFollowingAuthor,
    required this.canBeZapped,
    required this.isLoading,
    required this.isBookmarked,
    required this.refresh,
  });

  @override
  List<Object> get props => [
        currentUserPubkey,
        refresh,
        metadata,
        isSameArticleAuthor,
        canBeZapped,
        article,
        isFollowingAuthor,
        isLoading,
        isBookmarked,
      ];

  ArticleState copyWith({
    Metadata? metadata,
    Article? article,
    String? currentUserPubkey,
    bool? isSameArticleAuthor,
    bool? isFollowingAuthor,
    bool? canBeZapped,
    bool? isLoading,
    bool? isBookmarked,
    bool? refresh,
  }) {
    return ArticleState(
      metadata: metadata ?? this.metadata,
      article: article ?? this.article,
      currentUserPubkey: currentUserPubkey ?? this.currentUserPubkey,
      isSameArticleAuthor: isSameArticleAuthor ?? this.isSameArticleAuthor,
      isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
      canBeZapped: canBeZapped ?? this.canBeZapped,
      isLoading: isLoading ?? this.isLoading,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      refresh: refresh ?? this.refresh,
    );
  }
}
