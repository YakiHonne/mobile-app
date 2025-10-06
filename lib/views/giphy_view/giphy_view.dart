// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:giphy_api_client/giphy_api_client.dart';

import '../../logic/giphy_cubit/giphy_cubit.dart';
import '../../utils/utils.dart';
import '../search_view/search_view.dart';
import '../widgets/dotted_container.dart';
import '../widgets/no_content_widgets.dart';

class GiphyView extends HookWidget {
  const GiphyView({
    super.key,
    required this.onGifSelected,
  });

  final Function(String) onGifSelected;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController();
    final tabController = useTabController(
      initialLength: 2,
    );

    return BlocProvider(
      create: (context) => GiphyCubit(),
      child: Material(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                _tabBar(tabController, textController, context),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      SelectedGifType(
                        gifType: GiphyType.gifs,
                        onGifSelected: onGifSelected,
                        scrollController: scrollController,
                      ),
                      SelectedGifType(
                        gifType: GiphyType.stickers,
                        onGifSelected: onGifSelected,
                        scrollController: scrollController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column _tabBar(TabController tabController,
      TextEditingController textController, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ModalBottomSheetHandle(),
        Builder(builder: (context) {
          final isDark = themeCubit.isDark;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: TextFormField(
              textCapitalization: TextCapitalization.sentences,
              onChanged: (search) {
                context.read<GiphyCubit>().startSearch(
                      giphyType: tabController.index == 0
                          ? GiphyType.gifs
                          : GiphyType.stickers,
                      text: search,
                    );
              },
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Search now',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                  ),
                  child: Image.asset(
                    isDark ? Images.giphyWhite : Images.giphyBlack,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  maxHeight: 25,
                ),
              ),
            ),
          );
        }),
        TabBar(
          labelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
          dividerColor: Theme.of(context).primaryColorLight,
          controller: tabController,
          unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
          onTap: (index) {},
          tabs: [
            Tab(
              text: context.t.gifs.capitalizeFirst(),
            ),
            Tab(
              text: context.t.stickers.capitalizeFirst(),
            ),
          ],
        ),
      ],
    );
  }
}

class SelectedGifType extends StatelessWidget {
  const SelectedGifType({
    super.key,
    required this.gifType,
    required this.scrollController,
    required this.onGifSelected,
  });

  final GiphyType gifType;
  final ScrollController scrollController;
  final Function(String) onGifSelected;

  @override
  Widget build(BuildContext context) {
    if (gifType == GiphyType.gifs) {
      return BlocBuilder<GiphyCubit, GiphyState>(
        buildWhen: (previous, current) =>
            previous.gifsUpdatingState != current.gifsUpdatingState,
        builder: (context, state) {
          if (state.gifsUpdatingState == UpdatingState.progress) {
            return const SearchLoading();
          } else if (state.gifsUpdatingState == UpdatingState.success) {
            return GiphyContentGrid(
              content: state.gifs,
              onGifSelected: onGifSelected,
              scrollController: scrollController,
            );
          } else {
            return WrongView(
              onClicked: () {},
            );
          }
        },
      );
    } else if (gifType == GiphyType.stickers) {
      return BlocBuilder<GiphyCubit, GiphyState>(
        buildWhen: (previous, current) =>
            previous.stickersUpdatingState != current.stickersUpdatingState,
        builder: (context, state) {
          if (state.stickersUpdatingState == UpdatingState.progress) {
            return const SearchLoading();
          } else if (state.stickersUpdatingState == UpdatingState.success) {
            return GiphyContentGrid(
              content: state.stickers,
              onGifSelected: onGifSelected,
              scrollController: scrollController,
            );
          } else {
            return WrongView(
              onClicked: () {},
            );
          }
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class GiphyContentGrid extends StatefulWidget {
  const GiphyContentGrid({
    super.key,
    required this.content,
    required this.scrollController,
    required this.onGifSelected,
  });

  final List<GiphyGif?> content;
  final ScrollController scrollController;
  final Function(String) onGifSelected;

  @override
  State<GiphyContentGrid> createState() => _GiphyContentGridState();
}

class _GiphyContentGridState extends State<GiphyContentGrid> {
  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: kDefaultPadding,
      ),
      controller: widget.scrollController,
      itemCount: widget.content.length,
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      itemBuilder: (ctx, idx) {
        final GiphyGif? gif = widget.content[idx];
        return _item(gif);
      },
    );
  }

  Widget _item(GiphyGif? gif) {
    final res = gif?.images == null || gif?.images?.fixedWidth?.webp == null;

    if (res) {
      return Container();
    }

    final double aspectRatio = double.parse(gif!.images!.fixedWidth!.width!) /
        double.parse(gif.images!.fixedWidth!.height!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: InkWell(
        onTap: () {
          widget.onGifSelected(gif.images!.fixedWidth!.webp!.split('?').first);
          Navigator.pop(context);
        },
        child: ExtendedImage.network(
          gif.images!.fixedWidth!.webp!,
          semanticLabel: gif.title,
          gaplessPlayback: true,
          fit: BoxFit.fill,
          headers: const {'accept': 'image/*'},
          loadStateChanged: (state) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: gif.images == null
                ? Container()
                : case2(
                    state.extendedImageLoadState,
                    {
                      LoadState.loading: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: ColoredBox(
                          color: Theme.of(context).cardColor,
                          child: SpinKitChasingDots(
                            color: Theme.of(context).primaryColorDark,
                            size: 20,
                          ),
                        ),
                      ),
                      LoadState.completed: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: ExtendedRawImage(
                          fit: BoxFit.fill,
                          image: state.extendedImageInfo?.image,
                        ),
                      ),
                      LoadState.failed: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Container(
                          color: Theme.of(context).cardColor,
                        ),
                      ),
                    },
                    AspectRatio(
                      aspectRatio: aspectRatio,
                      child: Container(
                        color: Theme.of(context).cardColor,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  TValue? case2<TOptionType, TValue>(
    TOptionType selectedOption,
    Map<TOptionType, TValue> branches, [
    TValue? defaultValue,
  ]) {
    if (!branches.containsKey(selectedOption)) {
      return defaultValue;
    }

    return branches[selectedOption];
  }
}
