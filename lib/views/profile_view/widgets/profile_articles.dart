import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../models/article_model.dart';
import '../../../utils/utils.dart';
import '../../article_view/article_view.dart';
import '../../widgets/article_container.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/empty_list.dart';

class ProfileArticles extends StatelessWidget {
  const ProfileArticles({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding,
      ),
      sliver: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const SliverToBoxAdapter(
              child: ContentPlaceholder(
                removePadding: true,
              ),
            );
          } else {
            if (state.content.isEmpty) {
              return SliverToBoxAdapter(
                  child: EmptyList(
                description: context.t
                    .userNoArticles(name: state.user.getName())
                    .capitalizeFirst(),
                icon: FeatureIcons.selfArticles,
              ));
            } else {
              if (isTablet && !useSingleColumn) {
                return _itemsGrid(state);
              } else {
                return _itemsList(state);
              }
            }
          }
        },
      ),
    );
  }

  SliverList _itemsList(ProfileState state) {
    return SliverList.separated(
      separatorBuilder: (context, index) => const Divider(
        height: kDefaultPadding * 1.5,
        thickness: 0.5,
      ),
      itemBuilder: (context, index) {
        final event = state.content[index];
        final article = Article.fromEvent(event);

        return ArticleContainer(
          isFollowing: false,
          article: article,
          highlightedTag: '',
          isBookmarked: state.bookmarks.contains(article.identifier),
          onClicked: () {
            Navigator.pushNamed(
              context,
              ArticleView.routeName,
              arguments: article,
            );
          },
        );
      },
      itemCount: state.content.length,
    );
  }

  SliverMasonryGrid _itemsGrid(ProfileState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      itemBuilder: (context, index) {
        final event = state.content[index];
        final article = Article.fromEvent(event);

        return ArticleContainer(
          isFollowing: false,
          article: article,
          highlightedTag: '',
          isBookmarked: state.bookmarks.contains(article.identifier),
          onClicked: () {
            Navigator.pushNamed(
              context,
              ArticleView.routeName,
              arguments: article,
            );
          },
        );
      },
      childCount: state.content.length,
    );
  }
}
