// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_curation_cubit.dart';

class WriteCurationState extends Equatable {
  final String imageLink;
  final String title;
  final String description;
  final bool isArticlesCuration;
  final CurationPublishSteps curationPublishSteps;
  final List<Article> articles;
  final List<Article> activeArticles;
  final List<VideoModel> videos;
  final List<VideoModel> activeVideos;
  final bool isLoading;
  final bool isActiveLoading;
  final UpdatingState relaysAddingData;
  final String searchText;
  final List<String> mutes;
  final bool isZapSplitEnabled;
  final List<ZapSplit> zapsSplits;
  final bool selfContent;

  const WriteCurationState({
    required this.imageLink,
    required this.title,
    required this.description,
    required this.isArticlesCuration,
    required this.curationPublishSteps,
    required this.articles,
    required this.activeArticles,
    required this.videos,
    required this.activeVideos,
    required this.isLoading,
    required this.isActiveLoading,
    required this.relaysAddingData,
    required this.searchText,
    required this.mutes,
    required this.isZapSplitEnabled,
    required this.zapsSplits,
    required this.selfContent,
  });

  @override
  List<Object> get props => [
        imageLink,
        title,
        description,
        isArticlesCuration,
        curationPublishSteps,
        articles,
        activeArticles,
        videos,
        activeVideos,
        isLoading,
        isActiveLoading,
        relaysAddingData,
        searchText,
        mutes,
        isZapSplitEnabled,
        zapsSplits,
        selfContent,
      ];

  WriteCurationState copyWith({
    String? imageLink,
    String? title,
    String? description,
    bool? isArticlesCuration,
    CurationPublishSteps? curationPublishSteps,
    List<Article>? articles,
    List<Article>? activeArticles,
    List<VideoModel>? videos,
    List<VideoModel>? activeVideos,
    bool? isLoading,
    bool? isActiveLoading,
    UpdatingState? relaysAddingData,
    String? searchText,
    List<String>? mutes,
    bool? isZapSplitEnabled,
    List<ZapSplit>? zapsSplits,
    bool? selfContent,
  }) {
    return WriteCurationState(
      imageLink: imageLink ?? this.imageLink,
      title: title ?? this.title,
      description: description ?? this.description,
      isArticlesCuration: isArticlesCuration ?? this.isArticlesCuration,
      curationPublishSteps: curationPublishSteps ?? this.curationPublishSteps,
      articles: articles ?? this.articles,
      activeArticles: activeArticles ?? this.activeArticles,
      videos: videos ?? this.videos,
      activeVideos: activeVideos ?? this.activeVideos,
      isLoading: isLoading ?? this.isLoading,
      isActiveLoading: isActiveLoading ?? this.isActiveLoading,
      relaysAddingData: relaysAddingData ?? this.relaysAddingData,
      searchText: searchText ?? this.searchText,
      mutes: mutes ?? this.mutes,
      isZapSplitEnabled: isZapSplitEnabled ?? this.isZapSplitEnabled,
      zapsSplits: zapsSplits ?? this.zapsSplits,
      selfContent: selfContent ?? this.selfContent,
    );
  }
}
