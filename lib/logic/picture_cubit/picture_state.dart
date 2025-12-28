part of 'picture_cubit.dart';

class PictureState extends Equatable {
  const PictureState({
    this.refresh = false,
    this.isFollowingAuthor = false,
  });

  final bool refresh;
  final bool isFollowingAuthor;

  @override
  List<Object> get props => [refresh, isFollowingAuthor];

  PictureState copyWith({
    bool? refresh,
    bool? isFollowingAuthor,
  }) {
    return PictureState(
      refresh: refresh ?? this.refresh,
      isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
    );
  }
}
