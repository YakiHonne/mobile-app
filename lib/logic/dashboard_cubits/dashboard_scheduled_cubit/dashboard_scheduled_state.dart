part of 'dashboard_scheduled_cubit.dart';

class DashboardScheduledState extends Equatable {
  const DashboardScheduledState({
    this.notes = const [],
    this.isLoading = false,
  });

  final List<DvmPendingItem> notes;
  final bool isLoading;

  @override
  List<Object> get props => [notes, isLoading];

  DashboardScheduledState copyWith({
    List<DvmPendingItem>? notes,
    bool? isLoading,
  }) {
    return DashboardScheduledState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
