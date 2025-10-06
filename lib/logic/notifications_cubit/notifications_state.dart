// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'notifications_cubit.dart';

class NotificationsState extends Equatable {
  final List<Event> events;
  final int index;
  final bool isRead;
  final bool refresh;
  final bool isLoading;

  const NotificationsState({
    required this.events,
    required this.index,
    required this.isRead,
    required this.refresh,
    required this.isLoading,
  });

  @override
  List<Object> get props => [events, index, isRead, refresh, isLoading];

  NotificationsState copyWith({
    List<Event>? events,
    int? index,
    bool? isRead,
    bool? refresh,
    bool? isLoading,
  }) {
    return NotificationsState(
      events: events ?? this.events,
      index: index ?? this.index,
      isRead: isRead ?? this.isRead,
      refresh: refresh ?? this.refresh,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
