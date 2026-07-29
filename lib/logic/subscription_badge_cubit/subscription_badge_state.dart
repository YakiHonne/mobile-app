// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'subscription_badge_cubit.dart';

class SubscriptionBadgeState extends Equatable {
  const SubscriptionBadgeState({
    this.plans = const {},
    this.badgeImages = const {},
  });

  // pubkey -> plan ('' once fetched with no active plan)
  final Map<String, String> plans;

  // pubkey -> badge image url from the kind-30009 badge definition
  final Map<String, String> badgeImages;

  SubscriptionBadgeState copyWith({
    Map<String, String>? plans,
    Map<String, String>? badgeImages,
  }) {
    return SubscriptionBadgeState(
      plans: plans ?? this.plans,
      badgeImages: badgeImages ?? this.badgeImages,
    );
  }

  @override
  List<Object> get props => [plans, badgeImages];
}
