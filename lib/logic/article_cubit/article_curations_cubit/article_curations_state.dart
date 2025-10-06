// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'article_curations_cubit.dart';

class ArticleCurationsState extends Equatable {
  final bool refresh;
  final List<Curation> curations;
  final bool isCurationsLoading;
  final String articleId;
  final ArticleCuration articleCuration;
  final String articleAuthor;
  final int curationKind;

  final File? localImage;
  final bool isLocalImage;
  final bool isImageSelected;
  final String imageLink;

  final String title;
  final String description;
  final List<String> selectedRelays;
  final List<String> totalRelays;
  final bool isZapSplitEnabled;
  final List<ZapSplit> zapsSplits;

  const ArticleCurationsState({
    required this.refresh,
    required this.curations,
    required this.isCurationsLoading,
    required this.articleId,
    required this.articleCuration,
    required this.articleAuthor,
    required this.curationKind,
    this.localImage,
    required this.isLocalImage,
    required this.isImageSelected,
    required this.imageLink,
    required this.title,
    required this.description,
    required this.selectedRelays,
    required this.totalRelays,
    required this.isZapSplitEnabled,
    required this.zapsSplits,
  });

  @override
  List<Object> get props => [
        refresh,
        curations,
        isCurationsLoading,
        articleId,
        articleAuthor,
        isLocalImage,
        isImageSelected,
        imageLink,
        title,
        description,
        selectedRelays,
        totalRelays,
        articleCuration,
        isZapSplitEnabled,
        zapsSplits,
        curationKind,
      ];

  ArticleCurationsState copyWith({
    bool? refresh,
    List<Curation>? curations,
    bool? isCurationsLoading,
    String? articleId,
    ArticleCuration? articleCuration,
    String? articleAuthor,
    int? curationKind,
    File? localImage,
    bool? isLocalImage,
    bool? isImageSelected,
    String? imageLink,
    String? title,
    String? description,
    List<String>? selectedRelays,
    List<String>? totalRelays,
    bool? isZapSplitEnabled,
    List<ZapSplit>? zapsSplits,
  }) {
    return ArticleCurationsState(
      refresh: refresh ?? this.refresh,
      curations: curations ?? this.curations,
      isCurationsLoading: isCurationsLoading ?? this.isCurationsLoading,
      articleId: articleId ?? this.articleId,
      articleCuration: articleCuration ?? this.articleCuration,
      articleAuthor: articleAuthor ?? this.articleAuthor,
      curationKind: curationKind ?? this.curationKind,
      localImage: localImage ?? this.localImage,
      isLocalImage: isLocalImage ?? this.isLocalImage,
      isImageSelected: isImageSelected ?? this.isImageSelected,
      imageLink: imageLink ?? this.imageLink,
      title: title ?? this.title,
      description: description ?? this.description,
      selectedRelays: selectedRelays ?? this.selectedRelays,
      totalRelays: totalRelays ?? this.totalRelays,
      isZapSplitEnabled: isZapSplitEnabled ?? this.isZapSplitEnabled,
      zapsSplits: zapsSplits ?? this.zapsSplits,
    );
  }
}
