// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'interests_management_cubit.dart';

class InterestsManagementState extends Equatable {
  final Set<String> interests;
  final bool refresh;

  const InterestsManagementState({
    required this.interests,
    required this.refresh,
  });

  @override
  List<Object> get props => [interests, refresh];

  InterestsManagementState copyWith({
    Set<String>? interests,
    bool? refresh,
  }) {
    return InterestsManagementState(
      interests: interests ?? this.interests,
      refresh: refresh ?? this.refresh,
    );
  }
}
