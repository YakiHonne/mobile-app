import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:giphy_api_client/giphy_api_client.dart';

import '../../utils/utils.dart';

part 'giphy_state.dart';

class GiphyCubit extends Cubit<GiphyState> {
  GiphyCubit()
      : super(
          const GiphyState(
            gifs: [],
            stickers: [],
            gifsUpdatingState: UpdatingState.progress,
            stickersUpdatingState: UpdatingState.progress,
          ),
        ) {
    initView();
  }

  final int limit = 20;
  final client = GiphyClient(apiKey: dotenv.env['GIPHY_KEY']!);
  Timer? timer;

  Future<void> initView() async {
    try {
      if (!isClosed) {
        emit(
          const GiphyState(
            gifs: [],
            stickers: [],
            gifsUpdatingState: UpdatingState.progress,
            stickersUpdatingState: UpdatingState.progress,
          ),
        );
      }

      final res = await Future.wait([
        client.trending(
          limit: 20,
          type: GiphyType.gifs.name,
        ),
        client.trending(
          limit: 20,
          type: GiphyType.stickers.name,
        ),
      ]);
      if (!isClosed) {
        emit(
          state.copyWith(
            gifs: res[0].data,
            stickers: res[1].data,
            stickersUpdatingState: UpdatingState.success,
            gifsUpdatingState: UpdatingState.success,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            gifsUpdatingState: UpdatingState.failure,
            stickersUpdatingState: UpdatingState.failure,
          ),
        );
      }
    }
  }

  Future<void> loadMore(GiphyType giphyType) async {
    const int limit = 20;

    try {
      if (giphyType == GiphyType.gifs) {
        if (state.isLoadingMoreGifs || state.gifsNoMoreData) {
          return;
        }

        emit(state.copyWith(isLoadingMoreGifs: true));

        final res = await client.trending(
          limit: limit,
          offset: state.gifsOffset + limit,
          type: GiphyType.gifs.name,
        );

        final data = res.data ?? [];

        if (data.isEmpty) {
          emit(state.copyWith(
            isLoadingMoreGifs: false,
            gifsNoMoreData: true,
          ));
          return;
        }

        emit(state.copyWith(
          gifs: [...state.gifs, ...data],
          gifsOffset: state.gifsOffset + limit,
          isLoadingMoreGifs: false,
        ));
      } else {
        if (state.isLoadingMoreStickers || state.stickersNoMoreData) {
          return;
        }

        emit(state.copyWith(isLoadingMoreStickers: true));

        final res = await client.trending(
          limit: limit,
          offset: state.stickersOffset + limit,
          type: GiphyType.stickers.name,
        );

        final data = res.data ?? [];

        if (data.isEmpty) {
          emit(state.copyWith(
            isLoadingMoreStickers: false,
            stickersNoMoreData: true,
          ));
          return;
        }

        emit(state.copyWith(
          stickers: [...state.stickers, ...data],
          stickersOffset: state.stickersOffset + limit,
          isLoadingMoreStickers: false,
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          isLoadingMoreGifs: false,
          isLoadingMoreStickers: false,
        ));
      }
    }
  }

  Future<void> startSearch({
    required GiphyType giphyType,
    required String text,
  }) async {
    if (timer != null) {
      timer!.cancel();
    }

    timer = Timer(
      const Duration(seconds: 1),
      () {
        search(giphyType: giphyType, text: text);
      },
    );
  }

  Future<void> search({
    required GiphyType giphyType,
    required String text,
  }) async {
    lg.i('message');
    try {
      if (!isClosed) {
        emit(
          state.copyWith(
            gifsUpdatingState:
                giphyType == GiphyType.gifs ? UpdatingState.progress : null,
            stickersUpdatingState:
                giphyType == GiphyType.stickers ? UpdatingState.progress : null,
            gifs: giphyType == GiphyType.gifs ? [] : null,
            stickers: giphyType == GiphyType.stickers ? [] : null,
          ),
        );
      }

      if (text.trim().isEmpty) {
        if (giphyType == GiphyType.gifs) {
          final res = await client.trending(
            limit: 20,
            type: GiphyType.gifs.name,
          );
          if (!isClosed) {
            emit(
              state.copyWith(
                gifs: res.data,
                gifsUpdatingState: UpdatingState.success,
              ),
            );
          }
        } else {
          final res = await client.trending(
            limit: 20,
            type: GiphyType.stickers.name,
          );
          if (!isClosed) {
            emit(
              state.copyWith(
                stickers: res.data,
                stickersUpdatingState: UpdatingState.success,
              ),
            );
          }
        }
      } else {
        if (giphyType == GiphyType.gifs) {
          final res = await client.search(
            text,
            limit: 20,
            type: GiphyType.gifs.name,
          );
          if (!isClosed) {
            emit(
              state.copyWith(
                gifs: res.data,
                gifsUpdatingState: UpdatingState.success,
              ),
            );
          }
        } else {
          final res = await client.search(
            text,
            limit: 20,
            type: GiphyType.stickers.name,
          );
          if (!isClosed) {
            emit(
              state.copyWith(
                stickers: res.data,
                stickersUpdatingState: UpdatingState.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            gifsUpdatingState:
                giphyType == GiphyType.gifs ? UpdatingState.failure : null,
            stickersUpdatingState:
                giphyType == GiphyType.stickers ? UpdatingState.failure : null,
          ),
        );
      }
    }
  }
}
