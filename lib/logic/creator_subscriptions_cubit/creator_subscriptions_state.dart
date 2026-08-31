// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'creator_subscriptions_cubit.dart';

class CreatorSubscriptionsState extends Equatable {
  const CreatorSubscriptionsState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.hasFetched = false,
  });

  final List<SubscriberSubscription> subscriptions;
  final bool isLoading;
  final bool hasFetched;

  CreatorSubscriptionsState copyWith({
    List<SubscriberSubscription>? subscriptions,
    bool? isLoading,
    bool? hasFetched,
  }) {
    return CreatorSubscriptionsState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      hasFetched: hasFetched ?? this.hasFetched,
    );
  }

  @override
  List<Object> get props => [subscriptions, isLoading, hasFetched];
}
