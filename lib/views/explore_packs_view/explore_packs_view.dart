import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/explore_packs_cubit/explore_packs_cubit.dart';
import '../../models/packs_model.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../profile_view/widgets/profile_fast_access.dart';
import '../widgets/classic_footer.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/content_manager/dicover_settings_views/relay_settings_view.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/empty_list.dart';
import '../widgets/tag_container.dart';
import 'widget/pack_feed_view.dart';
import 'widget/pack_info_view.dart';

class ExplorePacksView extends StatefulWidget {
  const ExplorePacksView({super.key});

  @override
  State<ExplorePacksView> createState() => _ExplorePacksViewState();
}

class _ExplorePacksViewState extends State<ExplorePacksView> {
  final refreshController = RefreshController();
  final scrollController = ScrollController();
  bool isStarterPack = true;

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider(
      create: (context) => ExplorePacksCubit(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.followPacks.capitalizeFirst(),
          description: context.t.followPacksDesc,
        ),
        body: Builder(builder: (context) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            child: SmartRefresher(
              controller: refreshController,
              enablePullUp: true,
              scrollController: scrollController,
              header: MaterialClassicHeader(
                color: Theme.of(context).primaryColor,
              ),
              footer: const RefresherClassicFooter(),
              onLoading: () => context
                  .read<ExplorePacksCubit>()
                  .getPacks(isAdding: true, isStarterPack: isStarterPack),
              onRefresh: () => onRefresh(
                onInit: () => context
                    .read<ExplorePacksCubit>()
                    .getPacks(isStarterPack: isStarterPack),
              ),
              child: BlocBuilder<ExplorePacksCubit, ExplorePacksState>(
                builder: (context, state) {
                  return CustomScrollView(
                    slivers: [
                      ExplorePacks(
                        onStarterPackSelected: (sp) {
                          setState(() {
                            isStarterPack = sp;
                          });
                        },
                      ),
                      if (state.isLoading)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(kDefaultPadding * 2),
                            child: SpinKitCircle(
                              color: Theme.of(context).primaryColor,
                              size: 30,
                            ),
                          ),
                        )
                      else if (state.packs.isEmpty)
                        SliverToBoxAdapter(
                          child: EmptyList(
                            description: context.t.noPacksFoundDesc,
                            title: context.t.noPacksFound,
                            icon: FeatureIcons.search,
                          ),
                        )
                      else if (isTablet)
                        buildMasonryGrid(state.packs)
                      else
                        buildSliverList(state.packs)
                    ],
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  SliverMasonryGrid buildMasonryGrid(List<PacksModel> packs) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: kDefaultPadding / 2,
      crossAxisSpacing: kDefaultPadding / 2,
      itemBuilder: (context, index) {
        final pack = packs[index];
        return PackCard(pack: pack, enableBrowse: true);
      },
      childCount: packs.length,
    );
  }

  SliverList buildSliverList(List<PacksModel> packs) {
    return SliverList.separated(
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 4,
      ),
      itemBuilder: (context, index) {
        final pack = packs[index];
        return PackCard(pack: pack, enableBrowse: true);
      },
      itemCount: packs.length,
    );
  }
}

class PackCard extends HookWidget {
  const PackCard({
    super.key,
    required this.pack,
    required this.enableBrowse,
    this.hasActions = false,
    this.onEdit,
    this.onDelete,
  });

  final PacksModel pack;
  final bool enableBrowse;
  final bool hasActions;
  final Function()? onEdit;
  final Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasActions
          ? null
          : () {
              showModalBottomSheet(
                context: context,
                elevation: 0,
                builder: (_) {
                  return BlocProvider.value(
                    value: context.read<ExplorePacksCubit>(),
                    child: PackInfoView(
                      pack: pack,
                    ),
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            _packHeader(context),
            const Divider(
              thickness: 0.5,
            ),
            _packFollows(),
            if (enableBrowse) ...[
              const Divider(
                thickness: 0.5,
              ),
              _browsePack(context),
            ]
          ],
        ),
      ),
    );
  }

  GestureDetector _browsePack(BuildContext context) {
    return GestureDetector(
      onTap: () {
        YNavigator.pushPage(
          context,
          (_) => BlocProvider.value(
            value: context.read<ExplorePacksCubit>(),
            child: PackFeedView(pack: pack),
          ),
        );
      },
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        child: Row(
          spacing: kDefaultPadding / 4,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.t.browsePack,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                  ),
            ),
            SvgPicture.asset(
              FeatureIcons.shareExternal,
              width: 15,
              height: 15,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _packFollows() {
    return CommonUsersRow(
      commonPubkeys: pack.pubkeys,
      useOthers: true,
    );
  }

  Row _packHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonThumbnail(
          image: pack.image,
          width: 10.w,
          height: 10.w,
          radius: kDefaultPadding / 2,
          isRound: true,
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pack.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                pack.description.isNotEmpty
                    ? pack.description
                    : context.t.noDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        if (hasActions) _buildActions(context) else _buildExpandButton(context),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelLarge;

        return [
          PullDownMenuItem(
            onTap: onEdit,
            title: context.t.edit.capitalizeFirst(),
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: SvgPicture.asset(
              FeatureIcons.editArticle,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
          PullDownMenuItem(
            onTap: onDelete,
            isDestructive: true,
            title: context.t.delete.capitalizeFirst(),
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: SvgPicture.asset(
              FeatureIcons.trash,
              colorFilter: const ColorFilter.mode(
                kRed,
                BlendMode.srcIn,
              ),
            ),
          ),
        ];
      },
      buttonBuilder: (context, open) => CustomIconButton(
        onClicked: open,
        icon: FeatureIcons.more,
        size: 20,
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
  }

  Container _buildExpandButton(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(kDefaultPadding / 3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: RotatedBox(
        quarterTurns: 4,
        child: SvgPicture.asset(
          FeatureIcons.arrowRight,
          width: 17,
          height: 17,
          colorFilter: ColorFilter.mode(
            Theme.of(context).highlightColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class CompactPackCard extends StatelessWidget {
  const CompactPackCard({
    super.key,
    required this.pack,
    required this.isSelected,
    required this.onTap,
  });

  final PacksModel pack;
  final bool isSelected;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: isSelected
              ? Theme.of(context).cardColor
              : Theme.of(context).scaffoldBackgroundColor,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                )
              : null,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 3,
          vertical: isSelected ? kDefaultPadding / 3 : 0,
        ),
        child: Row(
          children: [
            CommonThumbnail(
              image: pack.image,
              width: 10.w,
              height: 10.w,
              radius: kDefaultPadding / 2,
              isRound: true,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    pack.description.isNotEmpty
                        ? pack.description
                        : context.t.noDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            CustomIconButton(
              onClicked: () {
                showModalBottomSheet(
                  context: context,
                  elevation: 0,
                  builder: (_) {
                    return SharePackFeed(pack: pack);
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              icon: FeatureIcons.shareExternal,
              size: 17,
              vd: -4,
              backgroundColor: kTransparent,
            ),
          ],
        ),
      ),
    );
  }
}

class NoPacksAvailable extends StatelessWidget {
  const NoPacksAvailable({super.key, required this.viewType});

  final ViewDataTypes viewType;

  @override
  Widget build(BuildContext context) {
    return EmptyList(
      title: context.t.noPacksFound,
      description: context.t.noPacksFoundDesc,
      icon: FeatureIcons.search,
    );
  }
}

class ExplorePacks extends HookWidget {
  const ExplorePacks({super.key, required this.onStarterPackSelected});

  final Function(bool) onStarterPackSelected;

  @override
  Widget build(BuildContext context) {
    final types = useMemoized(
      () {
        return [
          context.t.starterPacks,
          context.t.mediaPacks,
        ];
      },
    );

    final selectedType = useState(types.first);

    return SliverAppBar(
      leading: const SizedBox.shrink(),
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      titleSpacing: 0,
      floating: true,
      title: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
        child: SizedBox(
          height: 36,
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => const SizedBox(
              width: kDefaultPadding / 4,
            ),
            itemBuilder: (context, index) {
              final type = types[index];

              return TagContainer(
                title: type.capitalizeFirst(),
                isActive: selectedType.value == type,
                style: Theme.of(context).textTheme.labelLarge,
                onClick: () {
                  selectedType.value = type;
                  final isStarterPack = type == context.t.starterPacks;
                  context
                      .read<ExplorePacksCubit>()
                      .getPacks(isStarterPack: isStarterPack);
                  onStarterPackSelected.call(isStarterPack);
                  HapticFeedback.lightImpact();
                },
              );
            },
            itemCount: types.length,
          ),
        ),
      ),
    );
  }
}
