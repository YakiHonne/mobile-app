// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'search_user_cubit.dart';

class SearchUserState extends Equatable {
  final List<Metadata> authors;
  final bool isLoading;

  const SearchUserState({
    required this.authors,
    required this.isLoading,
  });

  @override
  List<Object> get props => [authors, isLoading];

  SearchUserState copyWith({
    List<Metadata>? authors,
    bool? isLoading,
  }) {
    return SearchUserState(
      authors: authors ?? this.authors,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
