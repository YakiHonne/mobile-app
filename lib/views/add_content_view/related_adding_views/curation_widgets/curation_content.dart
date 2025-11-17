// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../../logic/write_curation_cubit/write_curation_cubit.dart';
import '../../../../models/article_model.dart';
import '../../../../models/video_model.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/common_thumbnail.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/data_providers.dart';
import '../../../widgets/empty_list.dart';
import '../../../widgets/muted_mark.dart';
import '../../../widgets/place_holders.dart';
import 'curation_articles_list.dart';

class CurationContent extends HookWidget {
  const CurationContent({
    super.key,
    required this.isAdding,
  });

  final bool isAdding;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<WriteCurationCubit, WriteCurationState>(
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.all(
            isTablet ? 15.w : kDefaultPadding / 2,
          ),
          children: [
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _textfield(state, context),
            if (isAdding) ...[
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              _curationType(context, state)
            ],
            const SizedBox(
              height: kDefaultPadding,
            ),
            if (ResponsiveBreakpoints.of(context).smallerOrEqualTo(MOBILE))
              Row(
                children: [
                  _type(),
                  _add(context),
                ],
              ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _curationItems(),
          ],
        );
      },
    );
  }

  BlocBuilder<WriteCurationCubit, WriteCurationState> _curationItems() {
    return BlocBuilder<WriteCurationCubit, WriteCurationState>(
      builder: (context, state) {
        if (state.isActiveLoading) {
          return const ArticleSkeleton();
        } else if (state.isArticlesCuration
            ? state.activeArticles.isEmpty
            : state.activeVideos.isEmpty) {
          return Center(
            child: EmptyList(
              description: context.t.noContentBelongToCuration(
                type: state.isArticlesCuration
                    ? context.t.articles
                    : context.t.videos,
              ),
              icon: FeatureIcons.contentOpen,
            ),
          );
        } else {
          return ResponsiveBreakpoints.of(context).largerThan(MOBILE)
              ? CurationAddedArticleGrid()
              : CurationAddedArticleList();
        }
      },
    );
  }

  CustomIconButton _add(BuildContext context) {
    return CustomIconButton(
      onClicked: () {
        context.read<WriteCurationCubit>().getItems(false);

        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return BlocProvider.value(
              value: context.read<AddContentCubit>(),
              child: BlocProvider.value(
                value: context.read<WriteCurationCubit>(),
                child: const SizedBox(
                  width: double.infinity,
                  child: CurationArticlesList(),
                ),
              ),
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      icon: FeatureIcons.addRaw,
      size: 18,
      vd: -1,
      backgroundColor: Theme.of(context).cardColor,
    );
  }

  BlocBuilder<WriteCurationCubit, WriteCurationState> _type() {
    return BlocBuilder<WriteCurationCubit, WriteCurationState>(
      builder: (context, state) {
        final type = state.isArticlesCuration
            ? context.t.articles.capitalize()
            : context.t.videos.capitalize();

        final length = state.isArticlesCuration
            ? state.activeArticles.length
            : state.activeVideos.length;

        return Expanded(
          child: Text(
            '$type ${length.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        );
      },
    );
  }

  Container _curationType(BuildContext context, WriteCurationState state) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          width: 0.5,
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.t.curationType.capitalize(),
            ),
          ),
          CurationTypeToggle(
            isArticlesCuration: state.isArticlesCuration,
            onToggle: () {
              context.read<WriteCurationCubit>().setCurationType();
            },
          ),
        ],
      ),
    );
  }

  TextFormField _textfield(WriteCurationState state, BuildContext context) {
    return TextFormField(
      initialValue: state.title,
      textCapitalization: TextCapitalization.sentences,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: context.t.title.capitalize(),
      ),
      onChanged: (title) => context.read<WriteCurationCubit>().setTitle(title),
    );
  }
}

class CurationAddedArticleList extends StatelessWidget {
  CurationAddedArticleList({
    super.key,
  });

  final _listViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WriteCurationCubit, WriteCurationState>(
      builder: (context, state) {
        if (state.isArticlesCuration) {
          return ReorderableListView.builder(
            key: _listViewKey,
            shrinkWrap: true,
            primary: false,
            onReorder: (oldIndex, newIndex) {
              final index = newIndex > oldIndex ? newIndex - 1 : newIndex;

              context
                  .read<WriteCurationCubit>()
                  .setArticlesNewOrder(oldIndex, index);
            },
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
            itemBuilder: (context, index) {
              final article = state.activeArticles[index];

              return AddingCurationArticleContainer(
                key: Key(article.id),
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 4,
                ),
                isMuted: state.mutes.contains(article.pubkey),
                pubkey: article.pubkey,
                image: article.image,
                muteKind: 'article',
                placeholder: article.placeholder,
                title: article.title,
                isAdding: false,
                isActive: true,
                onDelete: () {
                  context
                      .read<AddContentCubit>()
                      .setBottomNavigationBarState(false);
                  context
                      .read<WriteCurationCubit>()
                      .deleteActiveArticle(article.id);
                },
              );
            },
            itemCount: state.activeArticles.length,
          );
        } else {
          return ReorderableListView.builder(
            key: _listViewKey,
            shrinkWrap: true,
            primary: false,
            onReorder: (oldIndex, newIndex) {
              final index = newIndex > oldIndex ? newIndex - 1 : newIndex;

              context
                  .read<WriteCurationCubit>()
                  .setVideossNewOrder(oldIndex, index);
            },
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
            itemBuilder: (context, index) {
              final video = state.activeVideos[index];

              return AddingCurationArticleContainer(
                key: Key(video.id),
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 4,
                ),
                isMuted: state.mutes.contains(video.pubkey),
                pubkey: video.pubkey,
                image: video.thumbnail,
                muteKind: 'video',
                placeholder: video.placeHolder,
                title: video.title,
                isAdding: false,
                isActive: true,
                onDelete: () {
                  context
                      .read<AddContentCubit>()
                      .setBottomNavigationBarState(false);
                  context
                      .read<WriteCurationCubit>()
                      .deleteActiveArticle(video.id);
                },
              );
            },
            itemCount: state.activeVideos.length,
          );
        }
      },
    );
  }
}

class CurationAddedArticleGrid extends HookWidget {
  CurationAddedArticleGrid({
    super.key,
  });

  final _gridViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final gridScrollController = useScrollController();

    return BlocBuilder<WriteCurationCubit, WriteCurationState>(
      buildWhen: (previous, current) =>
          previous.activeArticles != current.activeArticles &&
          previous.activeVideos != current.activeVideos &&
          previous.mutes != current.mutes,
      builder: (context, state) {
        List<Widget> generatedChildren = [];
        if (state.isArticlesCuration) {
          generatedChildren = state.activeArticles.map((article) {
            return AddingCurationArticleContainer(
              key: Key(article.id),
              padding: const EdgeInsets.all(
                kDefaultPadding / 4,
              ),
              muteKind: 'article',
              pubkey: article.pubkey,
              image: article.image,
              placeholder: article.placeholder,
              title: article.title,
              isMuted: state.mutes.contains(article.pubkey),
              isAdding: false,
              isActive: true,
              onDelete: () {
                context
                    .read<AddContentCubit>()
                    .setBottomNavigationBarState(false);
                context
                    .read<WriteCurationCubit>()
                    .deleteActiveArticle(article.id);
              },
            );
          }).toList();
        } else {
          generatedChildren = state.activeVideos.map((video) {
            return AddingCurationArticleContainer(
              key: Key(video.id),
              padding: const EdgeInsets.all(
                kDefaultPadding / 4,
              ),
              pubkey: video.pubkey,
              image: video.thumbnail,
              muteKind: 'video',
              placeholder: video.placeHolder,
              title: video.title,
              isMuted: state.mutes.contains(video.pubkey),
              isAdding: false,
              isActive: true,
              onDelete: () {
                context
                    .read<WriteCurationCubit>()
                    .deleteActiveArticle(video.id);
              },
            );
          }).toList();
        }

        return ReorderableBuilder(
          scrollController: gridScrollController,
          enableLongPress: false,
          onReorder: (ReorderedListFunction reorderedListFunction) {
            if (state.isArticlesCuration) {
              final articles =
                  reorderedListFunction(state.articles) as List<Article>;
              context.read<WriteCurationCubit>().setArticleGrid(articles);
            } else {
              final videos =
                  reorderedListFunction(state.videos) as List<VideoModel>;
              context.read<WriteCurationCubit>().setVideosGrid(videos);
            }
          },
          builder: (children) => GridView.builder(
            itemBuilder: (context, index) {
              return children[index];
            },
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            itemCount: children.length,
            key: _gridViewKey,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 120,
              crossAxisSpacing: kDefaultPadding,
            ),
          ),
          children: generatedChildren,
        );
      },
    );
  }
}

class AddingCurationArticleContainer extends HookWidget {
  const AddingCurationArticleContainer({
    super.key,
    required this.image,
    required this.placeholder,
    required this.pubkey,
    required this.title,
    required this.muteKind,
    required this.onDelete,
    required this.isAdding,
    required this.isActive,
    required this.isMuted,
    required this.padding,
  });

  final String image;
  final String placeholder;
  final String pubkey;
  final String title;
  final String muteKind;
  final bool isAdding;
  final bool isActive;
  final bool isMuted;
  final EdgeInsetsGeometry padding;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    useMemoized(
      () {
        metadataCubit.requestMetadata(pubkey);
      },
    );

    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, nip05) {
        return Padding(
          padding: padding,
          child: Row(
            children: [
              Stack(
                children: [
                  CommonThumbnail(
                    image: image,
                    placeholder: placeholder,
                    width: 50,
                    height: 50,
                    isRound: true,
                    radius: kDefaultPadding / 1.5,
                  ),
                  if (isMuted) ...[
                    Positioned(
                      left: kDefaultPadding / 4,
                      top: kDefaultPadding / 4,
                      child: MutedMark(kind: muteKind),
                    ),
                  ]
                ],
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.t.byPerson(name: metadata.getName()),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              CustomIconButton(
                onClicked: onDelete,
                icon: isAdding ? FeatureIcons.addRaw : FeatureIcons.trash,
                backgroundColor: kTransparent,
                iconColor: isAdding ? kGreen : kRed,
                size: 20,
                vd: -2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class CurationTypeToggle extends StatelessWidget {
  const CurationTypeToggle({
    super.key,
    required this.isArticlesCuration,
    required this.onToggle,
  });

  final Function() onToggle;
  final bool isArticlesCuration;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 90,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Row(
              children: [
                if (isArticlesCuration)
                  const SizedBox(
                    width: 28,
                  ),
                Expanded(
                  child: Text(
                    isArticlesCuration
                        ? context.t.articles.capitalize()
                        : context.t.videos.capitalize(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: kWhite,
                        ),
                  ),
                ),
                if (!isArticlesCuration)
                  const SizedBox(
                    width: 28,
                  ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: 2,
            bottom: 2,
            left: isArticlesCuration ? 2 : 60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
              ),
              child: Center(
                child: SvgPicture.asset(
                  isArticlesCuration
                      ? FeatureIcons.selfArticles
                      : FeatureIcons.videoOcta,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
