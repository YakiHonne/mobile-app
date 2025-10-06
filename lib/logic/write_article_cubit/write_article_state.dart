// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_article_cubit.dart';

class WriteArticleState extends Equatable {
  final String title;
  final String content;
  final String imageLink;
  final String excerpt;
  final bool isSensitive;
  final Set<String> keywords;
  final bool deleteDraft;
  final bool isDraft;
  final bool forwardedAsDraft;
  final List<String> suggestions;
  final bool isZapSplitEnabled;
  final List<ZapSplit> zapsSplits;
  final bool tryToLoad;

  const WriteArticleState({
    required this.title,
    required this.content,
    required this.imageLink,
    required this.excerpt,
    required this.isSensitive,
    required this.keywords,
    required this.deleteDraft,
    required this.isDraft,
    required this.forwardedAsDraft,
    required this.suggestions,
    required this.isZapSplitEnabled,
    required this.zapsSplits,
    required this.tryToLoad,
  });

  @override
  List<Object> get props => [
        title,
        content,
        excerpt,
        isSensitive,
        keywords,
        imageLink,
        deleteDraft,
        isDraft,
        suggestions,
        forwardedAsDraft,
        tryToLoad,
        isZapSplitEnabled,
        zapsSplits,
      ];

  WriteArticleState copyWith({
    String? title,
    String? content,
    String? imageLink,
    String? excerpt,
    bool? isSensitive,
    Set<String>? keywords,
    bool? deleteDraft,
    bool? isDraft,
    bool? forwardedAsDraft,
    List<String>? suggestions,
    bool? isZapSplitEnabled,
    List<ZapSplit>? zapsSplits,
    bool? tryToLoad,
  }) {
    return WriteArticleState(
      title: title ?? this.title,
      content: content ?? this.content,
      imageLink: imageLink ?? this.imageLink,
      excerpt: excerpt ?? this.excerpt,
      isSensitive: isSensitive ?? this.isSensitive,
      keywords: keywords ?? this.keywords,
      deleteDraft: deleteDraft ?? this.deleteDraft,
      isDraft: isDraft ?? this.isDraft,
      forwardedAsDraft: forwardedAsDraft ?? this.forwardedAsDraft,
      suggestions: suggestions ?? this.suggestions,
      isZapSplitEnabled: isZapSplitEnabled ?? this.isZapSplitEnabled,
      zapsSplits: zapsSplits ?? this.zapsSplits,
      tryToLoad: tryToLoad ?? this.tryToLoad,
    );
  }
}
