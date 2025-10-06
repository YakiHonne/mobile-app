// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'onboarding_cubit.dart';

class OnboardingState extends Equatable {
  final int index;

  const OnboardingState({
    required this.index,
  });

  @override
  List<Object> get props => [index];

  OnboardingState copyWith({
    int? index,
  }) {
    return OnboardingState(
      index: index ?? this.index,
    );
  }
}
