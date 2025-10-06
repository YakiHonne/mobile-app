// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'search_cubit.dart';

class SearchState extends Equatable {
  final List<dynamic> content;
  final List<Metadata> authors;
  final String search;
  final SearchResultsType contentSearchResult;
  final SearchResultsType profileSearchResult;
  final Set<String> bookmarks;
  final List<String> interests;
  final List<String> mutes;
  final RelayConnectivity relayConnectivity;
  final bool refresh;

  const SearchState({
    required this.content,
    required this.authors,
    required this.search,
    required this.interests,
    required this.contentSearchResult,
    required this.profileSearchResult,
    required this.bookmarks,
    required this.mutes,
    required this.refresh,
    required this.relayConnectivity,
  });

  @override
  List<Object> get props => [
        content,
        authors,
        search,
        interests,
        contentSearchResult,
        profileSearchResult,
        bookmarks,
        mutes,
        refresh,
        relayConnectivity,
      ];

  SearchState copyWith({
    List<dynamic>? content,
    List<Metadata>? authors,
    String? search,
    SearchResultsType? contentSearchResult,
    SearchResultsType? profileSearchResult,
    Set<String>? bookmarks,
    List<String>? interests,
    List<String>? mutes,
    RelayConnectivity? relayConnectivity,
    bool? refresh,
  }) {
    return SearchState(
      content: content ?? this.content,
      authors: authors ?? this.authors,
      search: search ?? this.search,
      contentSearchResult: contentSearchResult ?? this.contentSearchResult,
      profileSearchResult: profileSearchResult ?? this.profileSearchResult,
      bookmarks: bookmarks ?? this.bookmarks,
      interests: interests ?? this.interests,
      mutes: mutes ?? this.mutes,
      relayConnectivity: relayConnectivity ?? this.relayConnectivity,
      refresh: refresh ?? this.refresh,
    );
  }
}
