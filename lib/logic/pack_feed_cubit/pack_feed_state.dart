part of 'pack_feed_cubit.dart';

class PackFeedState extends Equatable {
  const PackFeedState({
    required this.content,
    required this.onLoading,
    required this.onAddingData,
    required this.refresh,
  });

  final List<BaseEventModel> content;
  final bool onLoading;
  final UpdatingState onAddingData;
  final bool refresh;

  @override
  List<Object> get props => [
        content,
        onLoading,
        onAddingData,
        refresh,
      ];

  PackFeedState copyWith({
    List<BaseEventModel>? content,
    bool? onLoading,
    UpdatingState? onAddingData,
    bool? refresh,
  }) {
    return PackFeedState(
      content: content ?? this.content,
      onLoading: onLoading ?? this.onLoading,
      onAddingData: onAddingData ?? this.onAddingData,
      refresh: refresh ?? this.refresh,
    );
  }
}
