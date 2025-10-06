// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'mute_list_cubit.dart';

class MuteListState extends Equatable {
  final List<String> mutes;
  final bool isUsingPrivKey;

  const MuteListState({
    required this.mutes,
    required this.isUsingPrivKey,
  });

  @override
  List<Object> get props => [
        mutes,
        isUsingPrivKey,
      ];

  MuteListState copyWith({
    List<String>? mutes,
    bool? isUsingPrivKey,
  }) {
    return MuteListState(
      mutes: mutes ?? this.mutes,
      isUsingPrivKey: isUsingPrivKey ?? this.isUsingPrivKey,
    );
  }
}
