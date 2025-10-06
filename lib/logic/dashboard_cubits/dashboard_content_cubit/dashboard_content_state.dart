// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'dashboard_content_cubit.dart';

class DashboardContentState extends Equatable {
  final List<BaseEventModel> content;
  final bool isLoading;
  final UpdatingState updatingState;
  final AppContentType chosenRE;
  final List<SmartWidget> savedTools;

  const DashboardContentState({
    required this.content,
    required this.isLoading,
    required this.updatingState,
    required this.chosenRE,
    required this.savedTools,
  });

  @override
  List<Object> get props => [
        content,
        isLoading,
        updatingState,
        chosenRE,
        savedTools,
      ];

  DashboardContentState copyWith({
    List<BaseEventModel>? content,
    bool? isLoading,
    UpdatingState? updatingState,
    AppContentType? chosenRE,
    List<SmartWidget>? savedTools,
  }) {
    return DashboardContentState(
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      updatingState: updatingState ?? this.updatingState,
      chosenRE: chosenRE ?? this.chosenRE,
      savedTools: savedTools ?? this.savedTools,
    );
  }
}
