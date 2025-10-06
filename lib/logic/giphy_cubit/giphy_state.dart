// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'giphy_cubit.dart';

class GiphyState extends Equatable {
  final List<GiphyGif?> gifs;
  final List<GiphyGif?> stickers;

  final UpdatingState gifsUpdatingState;
  final UpdatingState stickersUpdatingState;

  const GiphyState({
    required this.gifs,
    required this.stickers,
    required this.gifsUpdatingState,
    required this.stickersUpdatingState,
  });

  @override
  List<Object> get props => [
        gifs,
        stickers,
        gifsUpdatingState,
        stickersUpdatingState,
      ];

  GiphyState copyWith({
    List<GiphyGif?>? gifs,
    List<GiphyGif?>? stickers,
    UpdatingState? gifsUpdatingState,
    UpdatingState? stickersUpdatingState,
  }) {
    return GiphyState(
      gifs: gifs ?? this.gifs,
      stickers: stickers ?? this.stickers,
      gifsUpdatingState: gifsUpdatingState ?? this.gifsUpdatingState,
      stickersUpdatingState:
          stickersUpdatingState ?? this.stickersUpdatingState,
    );
  }
}
