// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'relays_progress_cubit.dart';

class RelaysProgressState extends Equatable {
  final bool isProgressVisible;
  final bool isRelaysVisible;
  final List<String> totalRelays;
  final List<String> successfulRelays;

  const RelaysProgressState({
    required this.isProgressVisible,
    required this.isRelaysVisible,
    required this.totalRelays,
    required this.successfulRelays,
  });

  @override
  List<Object> get props => [
        isProgressVisible,
        isRelaysVisible,
        totalRelays,
        successfulRelays,
      ];

  RelaysProgressState copyWith({
    bool? isProgressVisible,
    bool? isRelaysVisible,
    List<String>? totalRelays,
    List<String>? successfulRelays,
  }) {
    return RelaysProgressState(
      isProgressVisible: isProgressVisible ?? this.isProgressVisible,
      isRelaysVisible: isRelaysVisible ?? this.isRelaysVisible,
      totalRelays: totalRelays ?? this.totalRelays,
      successfulRelays: successfulRelays ?? this.successfulRelays,
    );
  }
}
