part of 'media_cubit.dart';

class MediaState extends Equatable {
  const MediaState({
    required this.content,
    required this.extraContent,
    required this.onLoading,
    required this.onAddingData,
    required this.refresh,
    required this.selectedSource,
  });

  final List<BaseEventModel> content;
  final List<BaseEventModel> extraContent;
  final bool onLoading;
  final UpdatingState onAddingData;
  final bool refresh;
  final AppContentSource selectedSource;

  @override
  List<Object> get props => [
        content,
        extraContent,
        onLoading,
        onAddingData,
        refresh,
        selectedSource,
      ];

  MediaState copyWith({
    List<BaseEventModel>? content,
    List<BaseEventModel>? extraContent,
    bool? onLoading,
    UpdatingState? onAddingData,
    bool? refresh,
    AppContentSource? selectedSource,
  }) {
    return MediaState(
      content: content ?? this.content,
      extraContent: extraContent ?? this.extraContent,
      onLoading: onLoading ?? this.onLoading,
      onAddingData: onAddingData ?? this.onAddingData,
      refresh: refresh ?? this.refresh,
      selectedSource: selectedSource ?? this.selectedSource,
    );
  }
}
