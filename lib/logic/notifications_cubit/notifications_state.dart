// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'notifications_cubit.dart';

class NotificationsState extends Equatable {
  final List<Event> events;
  final List<Event> premiumEvents;
  final int index;
  final bool isRead;
  final bool refresh;
  final bool isLoading;
  final bool isPremiumLoading;

  const NotificationsState({
    required this.events,
    required this.index,
    required this.isRead,
    required this.refresh,
    required this.isLoading,
    this.premiumEvents = const <Event>[],
    this.isPremiumLoading = false,
  });

  @override
  List<Object> get props => [
        events,
        premiumEvents,
        index,
        isRead,
        refresh,
        isLoading,
        isPremiumLoading,
      ];

  NotificationsState copyWith({
    List<Event>? events,
    List<Event>? premiumEvents,
    int? index,
    bool? isRead,
    bool? refresh,
    bool? isLoading,
    bool? isPremiumLoading,
  }) {
    return NotificationsState(
      events: events ?? this.events,
      premiumEvents: premiumEvents ?? this.premiumEvents,
      index: index ?? this.index,
      isRead: isRead ?? this.isRead,
      refresh: refresh ?? this.refresh,
      isLoading: isLoading ?? this.isLoading,
      isPremiumLoading: isPremiumLoading ?? this.isPremiumLoading,
    );
  }
}
