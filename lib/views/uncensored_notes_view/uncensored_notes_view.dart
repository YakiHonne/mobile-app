// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:numeral/numeral.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/uncensored_notes_cubit/uncensored_notes_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../logify_view/logify_view.dart';
import '../rewards_view/rewards_view.dart';
import '../search_view/search_view.dart';
import '../widgets/classic_footer.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/empty_list.dart';
import 'widgets/un_flashnews_container.dart';
import 'widgets/un_flashnews_details.dart';

class UncensoredNotesView extends StatelessWidget {
  const UncensoredNotesView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        nostrRepository.mainCubit.updateIndex(MainViews.leading);
      },
      child: BlocProvider(
        create: (context) => UncensoredNotesCubit(),
        lazy: false,
        child: DefaultTabController(
          length: 3,
          child: Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: CommunityWalletContainer(
                        isMainView: true,
                        onClicked: () {
                          if (canSign()) {
                            Navigator.pushNamed(
                              context,
                              RewardsView.routeName,
                              arguments: context.read<UncensoredNotesCubit>(),
                            );
                          } else {
                            YNavigator.pushPage(
                              context,
                              (context) => LogifyView(),
                            );
                          }
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: kDefaultPadding / 4,
                      ),
                    ),
                    _appbar(context),
                  ];
                },
                body: const UnList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _appbar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      elevation: 5,
      toolbarHeight: 50,
      floating: true,
      actions: const [SizedBox.shrink()],
      centerTitle: true,
      titleSpacing: kDefaultPadding / 2,
      title: SizedBox(
        width: double.infinity,
        height: 40,
        child: ScrollShadow(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            onTap: (selectedIndex) {
              context.read<UncensoredNotesCubit>().setIndex(selectedIndex);
            },
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            padding: EdgeInsets.zero,
            labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                  fontWeight: FontWeight.w600,
                ),
            unselectedLabelStyle:
                Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
            indicatorColor: Theme.of(context).primaryColor,
            dividerColor: Theme.of(context).dividerColor,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: context.t.newKey.capitalizeFirst()),
              Tab(
                text: context.t.needsYourHelp.capitalizeFirst(),
              ),
              Tab(
                text: context.t.ratedHelpful.capitalizeFirst(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunityWalletContainer extends StatelessWidget {
  const CommunityWalletContainer({
    super.key,
    required this.isMainView,
    required this.onClicked,
  });

  final bool isMainView;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        top: kDefaultPadding / 2,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          color: Theme.of(context).cardColor,
        ),
        child: Stack(
          children: [
            Positioned(
              left: -20,
              child: Transform.rotate(
                angle: 0.7,
                child: SvgPicture.asset(
                  FeatureIcons.reward,
                  width: 100,
                  height: 100,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark.withValues(alpha: 0.15),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            _communityWallet(context),
          ],
        ),
      ),
    );
  }

  Padding _communityWallet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.communityWallet.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).primaryColorDark,
                      ),
                ),
                _balance(),
              ],
            ),
          ),
          CustomIconButton(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            icon: isMainView ? FeatureIcons.reward : FeatureIcons.refresh,
            onClicked: onClicked,
            size: 22,
          ),
        ],
      ),
    );
  }

  BlocBuilder<UncensoredNotesCubit, UncensoredNotesState> _balance() {
    return BlocBuilder<UncensoredNotesCubit, UncensoredNotesState>(
      builder: (context, state) {
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: state.balance.numeral(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              TextSpan(
                text: ' Sats.',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                      fontWeight: FontWeight.w600,
                    ),
              )
            ],
          ),
        );
      },
    );
  }
}

class UnList extends StatefulWidget {
  const UnList({
    super.key,
  });

  @override
  State<UnList> createState() => _UnListState();
}

class _UnListState extends State<UnList> {
  final refreshController = RefreshController();

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocConsumer<UncensoredNotesCubit, UncensoredNotesState>(
      listener: (context, state) {
        if (state.addingFlashNewsStatus == UpdatingState.success) {
          refreshController.loadComplete();
        } else if (state.addingFlashNewsStatus == UpdatingState.idle) {
          refreshController.loadNoData();
        }
      },
      builder: (context, state) {
        if (state.loading) {
          return const SearchLoading();
        } else if (state.unNewFlashNews.isEmpty) {
          return EmptyList(
            description: context.t.noPaidNotesCanBeFound.capitalizeFirst(),
            icon: FeatureIcons.flashNews,
          );
        } else {
          Widget child;

          if (isMobile) {
            child = _itemsList(state);
          } else {
            child = _itemsGrid(state);
          }

          return SmartRefresher(
            controller: refreshController,
            enablePullDown: false,
            enablePullUp: true,
            header: const MaterialClassicHeader(
              color: kPurple,
            ),
            footer: const RefresherClassicFooter(),
            onLoading: () =>
                context.read<UncensoredNotesCubit>().addMoreUnFlashnews(),
            onRefresh: () => onRefresh(
              onInit: () => context.read<UncensoredNotesCubit>().setIndex(
                    state.index,
                  ),
            ),
            child: child,
          );
        }
      },
    );
  }

  MasonryGridView _itemsGrid(UncensoredNotesState state) {
    return MasonryGridView.builder(
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      mainAxisSpacing: kDefaultPadding / 2,
      crossAxisSpacing: kDefaultPadding / 2,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final unFlashNews = state.unNewFlashNews[index];

        return UnFlashNewsContainer(
          unNewFlashNews: unFlashNews,
          isBookmarked: state.bookmarks.contains(unFlashNews.flashNews.id),
          onRefresh: () {
            context.read<UncensoredNotesCubit>().setIndex(state.index);
          },
          onClicked: () {
            Navigator.pushNamed(
              context,
              UnFlashNewsDetails.routeName,
              arguments: unFlashNews,
            );
          },
        );
      },
      itemCount: state.unNewFlashNews.length,
    );
  }

  ListView _itemsList(UncensoredNotesState state) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final unFlashNews = state.unNewFlashNews[index];

        return UnFlashNewsContainer(
          unNewFlashNews: unFlashNews,
          isBookmarked: state.bookmarks.contains(unFlashNews.flashNews.id),
          onRefresh: () {
            context.read<UncensoredNotesCubit>().setIndex(state.index);
          },
          onClicked: () {
            Navigator.pushNamed(
              context,
              UnFlashNewsDetails.routeName,
              arguments: unFlashNews,
            );
          },
        );
      },
      separatorBuilder: (context, index) => const Divider(
        thickness: 0.5,
        height: kDefaultPadding * 1.5,
      ),
      itemCount: state.unNewFlashNews.length,
    );
  }
}
