// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../../logic/write_curation_cubit/write_curation_cubit.dart';
import '../../../../utils/utils.dart';
import '../../../profile_view/widgets/profile_connections_view.dart';
import '../../../widgets/classic_footer.dart';
import '../../../widgets/dotted_container.dart';
import '../../../widgets/empty_list.dart';
import '../../../widgets/place_holders.dart';
import 'curation_content.dart';

class CurationArticlesList extends StatefulWidget {
  const CurationArticlesList({super.key});

  @override
  State<CurationArticlesList> createState() => _CurationArticlesListState();
}

class _CurationArticlesListState extends State<CurationArticlesList> {
  final refreshController = RefreshController();
  final scrollController = ScrollController();
  final textEditingController = TextEditingController();

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    scrollController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WriteCurationCubit, WriteCurationState>(
      listener: (context, state) {
        if (state.relaysAddingData == UpdatingState.success) {
          refreshController.loadComplete();
        } else if (state.relaysAddingData == UpdatingState.idle) {
          refreshController.loadNoData();
        }
      },
      builder: (context, state) {
        final searchTextField = TextField(
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: context.t.searchContentByTitle(
              type: state.isArticlesCuration
                  ? context.t.articles
                  : context.t.videos,
            ),
          ),
          controller: textEditingController,
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: (text) {
            context.read<WriteCurationCubit>().setSearchText(text);
          },
        );

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.40,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
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
            child: _curationColumn(scrollController, context, searchTextField),
          ),
        );
      },
    );
  }

  Column _curationColumn(ScrollController scrollController,
      BuildContext context, TextField searchTextField) {
    return Column(
      children: [
        const ModalBottomSheetHandle(),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        BlocBuilder<WriteCurationCubit, WriteCurationState>(
          builder: (context, state) {
            return CustomToggleButton(
              state: !state.selfContent,
              firstText: context.t.allRelays,
              secondText: state.isArticlesCuration
                  ? context.t.myArticles
                  : context.t.myVideos,
              onClicked: () async {
                context.read<WriteCurationCubit>().toggleView();
                context.read<WriteCurationCubit>().getItems(false);
                textEditingController.clear();
              },
            );
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Expanded(
          child: SmartRefresher(
            controller: refreshController,
            enablePullUp: true,
            scrollController: scrollController,
            header: MaterialClassicHeader(
              color: Theme.of(context).primaryColor,
            ),
            footer: const RefresherClassicFooter(),
            onLoading: () => context.read<WriteCurationCubit>().getMoreItems(),
            onRefresh: () => onRefresh(
              onInit: () => context.read<WriteCurationCubit>().getItems(false),
            ),
            child: CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _searchTextField(context, searchTextField),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    vertical: kDefaultPadding / 2,
                  ),
                  sliver: BlocBuilder<WriteCurationCubit, WriteCurationState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const SliverToBoxAdapter(
                          child: ArticleSkeleton(),
                        );
                      } else if (state.isArticlesCuration
                          ? state.articles.isEmpty
                          : state.videos.isEmpty) {
                        return _emptyList(context, state);
                      } else {
                        if (state.isArticlesCuration) {
                          return _articlesList(state);
                        } else {
                          return _videosList(state);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverPadding _videosList(WriteCurationState state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
      ),
      sliver: SliverList.builder(
        itemBuilder: (context, index) {
          final video = state.videos[index];

          if (state.searchText.trim().isNotEmpty &&
              !video.title
                  .trim()
                  .toLowerCase()
                  .contains(state.searchText.toLowerCase().trim())) {
            return const SizedBox.shrink();
          }

          final isAdding = state.activeVideos
              .where((activeVideo) => activeVideo.id == video.id)
              .isEmpty;

          return AddingCurationArticleContainer(
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 4,
            ),
            pubkey: video.pubkey,
            image: video.thumbnail,
            muteKind: 'video',
            placeholder: video.placeHolder,
            title: video.title,
            isAdding: isAdding,
            isActive: isAdding,
            isMuted: false,
            onDelete: () {
              if (isAdding) {
                context
                    .read<AddContentCubit>()
                    .setBottomNavigationBarState(false);
                context.read<WriteCurationCubit>().setVideoToActive(video);
              } else {
                context
                    .read<AddContentCubit>()
                    .setBottomNavigationBarState(false);
                context.read<WriteCurationCubit>().deleteActiveArticle(
                      video.id,
                    );
              }
            },
          );
        },
        itemCount: state.videos.length,
      ),
    );
  }

  SliverPadding _articlesList(WriteCurationState state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      sliver: SliverList.builder(
        itemBuilder: (context, index) {
          final article = state.articles[index];

          if (state.searchText.trim().isNotEmpty &&
              !article.title
                  .trim()
                  .toLowerCase()
                  .contains(state.searchText.toLowerCase().trim())) {
            return const SizedBox.shrink();
          }

          final isAdding = state.activeArticles
              .where((activeArticle) => activeArticle.id == article.id)
              .isEmpty;

          return AddingCurationArticleContainer(
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 4,
            ),
            pubkey: article.pubkey,
            image: article.image,
            muteKind: 'article',
            placeholder: article.placeholder,
            title: article.title,
            isAdding: isAdding,
            isActive: isAdding,
            isMuted: false,
            onDelete: () {
              if (isAdding) {
                context
                    .read<AddContentCubit>()
                    .setBottomNavigationBarState(false);
                context.read<WriteCurationCubit>().setArticleToActive(article);
              } else {
                context
                    .read<AddContentCubit>()
                    .setBottomNavigationBarState(false);
                context.read<WriteCurationCubit>().deleteActiveArticle(
                      article.id,
                    );
              }
            },
          );
        },
        itemCount: state.articles.length,
      ),
    );
  }

  SliverToBoxAdapter _emptyList(
      BuildContext context, WriteCurationState state) {
    return SliverToBoxAdapter(
      child: EmptyList(
        description: context.t.noContentCanBeFound(
          type:
              state.isArticlesCuration ? context.t.articles : context.t.videos,
        ),
        icon: FeatureIcons.contentOpen,
      ),
    );
  }

  SliverToBoxAdapter _searchTextField(
      BuildContext context, TextField searchTextField) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 2,
        ),
        child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
            ? Row(
                children: [
                  Expanded(
                    child: searchTextField,
                  ),
                ],
              )
            : Column(
                children: [
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  searchTextField,
                ],
              ),
      ),
    );
  }
}
