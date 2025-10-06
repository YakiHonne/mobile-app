import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../logic/suggestion_box_cubit/suggestions_box_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/utils.dart';
import 'donations.dart';
import 'interests.dart';
import 'related_content.dart';
import 'share.dart';
import 'trending_users_24.dart';

class MultiSuggestionBox extends StatelessWidget {
  const MultiSuggestionBox({
    super.key,
    this.tag,
    required this.index,
    required this.isLeading,
  });

  final String? tag;
  final int index;
  final bool isLeading;

  @override
  Widget build(BuildContext context) {
    const divider = Divider(
      thickness: 0.3,
      height: kDefaultPadding * 1.5,
    );

    return BlocBuilder<SuggestionsBoxCubit, SuggestionsBoxState>(
      builder: (context, state) {
        if (shouldSkip(state)) {
          return divider;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            divider,
            Row(
              children: [
                Expanded(
                  child: Text(
                    getTitle(context),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (index != 4 && index != 5) _pulldownButton(context),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            getAttachedWidget(),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            divider,
          ],
        );
      },
    );
  }

  PullDownButton _pulldownButton(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        return [
          PullDownMenuItem(
            title: context.t.hideSuggestions.capitalizeFirst(),
            onTap: hideSuggestedBox,
            itemTheme: PullDownMenuItemTheme(
              textStyle: Theme.of(context).textTheme.labelMedium,
            ),
            iconWidget: SvgPicture.asset(
              FeatureIcons.notVisible,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => RotatedBox(
        quarterTurns: 1,
        child: IconButton(
          onPressed: showMenu,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            visualDensity: const VisualDensity(
              horizontal: -4,
              vertical: -4,
            ),
            padding: EdgeInsets.zero,
          ),
          icon: Icon(
            Icons.more_vert_rounded,
            color: Theme.of(context).primaryColorDark,
            size: 18,
          ),
        ),
      ),
    );
  }

  void hideSuggestedBox() {
    final currentIndex = index - 1;

    if (currentIndex == 0) {
      nostrRepository.hideTrendingUsers();
    } else if (currentIndex == 1) {
      nostrRepository.hideRelatedContent();
    } else if (currentIndex == 2) {
      nostrRepository.hideInterests();
    } else if (currentIndex == 3) {
      nostrRepository.hideDonations();
    } else if (currentIndex == 4) {
      nostrRepository.hideShare();
    }
  }

  Widget getAttachedWidget() {
    final currentIndex = index - 1;

    if (currentIndex == 0) {
      return const SuggestedTrendingUsers24();
    } else if (currentIndex == 1) {
      return SuggestedRelatedContent(isLeading: isLeading);
    } else if (currentIndex == 2) {
      return const SuggestedInterests();
    } else if (currentIndex == 3) {
      return const SuggestedDonations();
    } else {
      return const SuggestedShare();
    }
  }

  bool shouldSkip(SuggestionsBoxState state) {
    final currentIndex = index - 1;
    final c = nostrRepository.currentAppCustomization;

    if (currentIndex == 0) {
      return state.trendingUsers24.isEmpty || !(c?.showTrendingUsers ?? true);
    } else if (currentIndex == 1) {
      return (isLeading ? state.articles.isEmpty : state.notes.isEmpty) ||
          !(c?.showRelatedContent ?? true);
    } else if (currentIndex == 2) {
      return !(c?.showSuggestedInterests ?? true);
    } else if (currentIndex == 3) {
      return !(c?.showDonationBox ?? true && canSign());
    } else {
      return !(c?.showShareBox ?? true && canSign());
    }
  }

  String getTitle(BuildContext context) {
    final currentIndex = index - 1;

    if (currentIndex == 0) {
      return context.t.peopleToFollow.capitalizeFirst();
    } else if (currentIndex == 1) {
      return tag == null
          ? isLeading
              ? context.t.articles.capitalizeFirst()
              : context.t.notes.capitalizeFirst()
          : context.t.inTag(name: tag ?? '').capitalizeFirst();
    } else if (currentIndex == 2) {
      return context.t.interests.capitalizeFirst();
    } else if (currentIndex == 3) {
      return context.t.donations.capitalizeFirst();
    } else {
      return context.t.share.capitalizeFirst();
    }
  }
}
