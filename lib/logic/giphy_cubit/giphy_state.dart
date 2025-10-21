// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'giphy_cubit.dart';

class GiphyState extends Equatable {
  final List<GiphyGif?> gifs;
  final List<GiphyGif?> stickers;
  final UpdatingState gifsUpdatingState;
  final UpdatingState stickersUpdatingState;
  final int gifsOffset;
  final int stickersOffset;
  final bool isLoadingMoreGifs;
  final bool isLoadingMoreStickers;
  final bool gifsNoMoreData;
  final bool stickersNoMoreData;

  const GiphyState({
    required this.gifs,
    required this.stickers,
    required this.gifsUpdatingState,
    required this.stickersUpdatingState,
    this.gifsOffset = 0,
    this.stickersOffset = 0,
    this.isLoadingMoreGifs = false,
    this.isLoadingMoreStickers = false,
    this.gifsNoMoreData = false,
    this.stickersNoMoreData = false,
  });

  GiphyState copyWith({
    List<GiphyGif?>? gifs,
    List<GiphyGif?>? stickers,
    UpdatingState? gifsUpdatingState,
    UpdatingState? stickersUpdatingState,
    int? gifsOffset,
    int? stickersOffset,
    bool? isLoadingMoreGifs,
    bool? isLoadingMoreStickers,
    bool? gifsNoMoreData,
    bool? stickersNoMoreData,
  }) {
    return GiphyState(
      gifs: gifs ?? this.gifs,
      stickers: stickers ?? this.stickers,
      gifsUpdatingState: gifsUpdatingState ?? this.gifsUpdatingState,
      stickersUpdatingState:
          stickersUpdatingState ?? this.stickersUpdatingState,
      gifsOffset: gifsOffset ?? this.gifsOffset,
      stickersOffset: stickersOffset ?? this.stickersOffset,
      isLoadingMoreGifs: isLoadingMoreGifs ?? this.isLoadingMoreGifs,
      isLoadingMoreStickers:
          isLoadingMoreStickers ?? this.isLoadingMoreStickers,
      gifsNoMoreData: gifsNoMoreData ?? this.gifsNoMoreData,
      stickersNoMoreData: stickersNoMoreData ?? this.stickersNoMoreData,
    );
  }

  @override
  List<Object?> get props => [
        gifs,
        stickers,
        gifsUpdatingState,
        stickersUpdatingState,
        gifsOffset,
        stickersOffset,
        isLoadingMoreGifs,
        isLoadingMoreStickers,
        gifsNoMoreData,
        stickersNoMoreData,
      ];
}
