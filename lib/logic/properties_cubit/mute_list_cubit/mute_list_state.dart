// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'mute_list_cubit.dart';

class MuteListState extends Equatable {
  final List<String> usersMutes;
  final List<String> eventsMutes;
  final bool isUsingPrivKey;

  const MuteListState({
    required this.usersMutes,
    required this.eventsMutes,
    required this.isUsingPrivKey,
  });

  @override
  List<Object> get props => [
        usersMutes,
        eventsMutes,
        isUsingPrivKey,
      ];

  MuteListState copyWith({
    List<String>? usersMutes,
    List<String>? eventsMutes,
    bool? isUsingPrivKey,
  }) {
    return MuteListState(
      usersMutes: usersMutes ?? this.usersMutes,
      eventsMutes: eventsMutes ?? this.eventsMutes,
      isUsingPrivKey: isUsingPrivKey ?? this.isUsingPrivKey,
    );
  }
}
