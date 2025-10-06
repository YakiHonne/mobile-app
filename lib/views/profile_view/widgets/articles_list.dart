// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../utils/utils.dart';
import '../../article_view/article_view.dart';
import '../../widgets/article_container.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/empty_list.dart';

class ProfileArticles extends StatelessWidget {
  const ProfileArticles({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

    return Scrollbar(
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) =>
            previous.isArticlesLoading != current.isArticlesLoading ||
            previous.articles != current.articles ||
            previous.mutes != current.mutes ||
            previous.user != current.user ||
            previous.bookmarks != current.bookmarks,
        builder: (context, state) {
          if (state.isArticlesLoading) {
            return const SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                child: ContentPlaceholder(),
              ),
            );
          } else {
            if (state.articles.isEmpty) {
              return EmptyList(
                description: context.t
                    .userNoArticles(name: state.user.getName())
                    .capitalizeFirst(),
                icon: FeatureIcons.selfArticles,
              );
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

  ListView _itemsList(ProfileState state) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        height: kDefaultPadding * 1.5,
        thickness: 0.5,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding / 2,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final article = state.articles[index];

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
      itemCount: state.articles.length,
    );
  }

  MasonryGridView _itemsGrid(ProfileState state) {
    return MasonryGridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      crossAxisSpacing: kDefaultPadding,
      mainAxisSpacing: kDefaultPadding,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding,
      ),
      itemBuilder: (context, index) {
        final article = state.articles[index];

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
      itemCount: state.articles.length,
    );
  }
}
