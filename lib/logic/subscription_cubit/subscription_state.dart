// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'subscription_cubit.dart';

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.subscriptionStatus,
    this.usageData,
    this.refreshing = false,
    this.usageRefreshing = false,
  });

  final SubscriptionStatus? subscriptionStatus;
  final UsageData? usageData;
  final bool refreshing;
  final bool usageRefreshing;

  SubscriptionState copyWith({
    SubscriptionStatus? subscriptionStatus,
    UsageData? usageData,
    bool? clearSubscription,
    bool? clearUsage,
    bool? refreshing,
    bool? usageRefreshing,
  }) {
    return SubscriptionState(
      subscriptionStatus: (clearSubscription ?? false)
          ? null
          : subscriptionStatus ?? this.subscriptionStatus,
      usageData:
          (clearUsage ?? false) ? null : usageData ?? this.usageData,
      refreshing: refreshing ?? this.refreshing,
      usageRefreshing: usageRefreshing ?? this.usageRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [subscriptionStatus, usageData, refreshing, usageRefreshing];
}
