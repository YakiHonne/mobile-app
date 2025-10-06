// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'suggestions_box_cubit.dart';

class SuggestionsBoxState extends Equatable {
  final List<Metadata> trendingUsers24;
  final List<DetailedNoteModel> notes;
  final List<Article> articles;
  final List<Topic> suggestions;

  const SuggestionsBoxState({
    required this.trendingUsers24,
    required this.notes,
    required this.articles,
    required this.suggestions,
  });

  @override
  List<Object> get props => [trendingUsers24, notes, articles, suggestions];

  SuggestionsBoxState copyWith({
    List<Metadata>? trendingUsers24,
    List<DetailedNoteModel>? notes,
    List<Article>? articles,
    List<Topic>? suggestions,
  }) {
    return SuggestionsBoxState(
      trendingUsers24: trendingUsers24 ?? this.trendingUsers24,
      notes: notes ?? this.notes,
      articles: articles ?? this.articles,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}
