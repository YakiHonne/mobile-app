// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'dashboard_home_cubit.dart';

class DashboardHomeState extends Equatable {
  final Map<String, num> stats;
  final List<DetailedNoteModel> popular;
  final List<Article> drafts;
  final List<BaseEventModel> latest;

  const DashboardHomeState({
    required this.stats,
    required this.popular,
    required this.drafts,
    required this.latest,
  });

  @override
  List<Object> get props => [
        stats,
        popular,
        drafts,
        latest,
      ];

  DashboardHomeState copyWith({
    Map<String, num>? stats,
    List<DetailedNoteModel>? popular,
    List<Article>? drafts,
    List<BaseEventModel>? latest,
  }) {
    return DashboardHomeState(
      stats: stats ?? this.stats,
      popular: popular ?? this.popular,
      drafts: drafts ?? this.drafts,
      latest: latest ?? this.latest,
    );
  }
}
