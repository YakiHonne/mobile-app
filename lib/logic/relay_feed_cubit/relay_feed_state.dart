// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'relay_feed_cubit.dart';

class RelayFeedState extends Equatable {
  final List<BaseEventModel> content;
  final bool onLoading;
  final UpdatingState onAddingData;
  final bool refresh;

  const RelayFeedState({
    required this.content,
    required this.onLoading,
    required this.onAddingData,
    required this.refresh,
  });

  @override
  List<Object> get props => [
        content,
        onLoading,
        onAddingData,
        refresh,
      ];

  RelayFeedState copyWith({
    List<BaseEventModel>? content,
    bool? onLoading,
    UpdatingState? onAddingData,
    bool? refresh,
  }) {
    return RelayFeedState(
      content: content ?? this.content,
      onLoading: onLoading ?? this.onLoading,
      onAddingData: onAddingData ?? this.onAddingData,
      refresh: refresh ?? this.refresh,
    );
  }
}
