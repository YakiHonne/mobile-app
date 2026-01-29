import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/cashu/models/mint_info.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';
import 'mint_details.dart';

class MintsList extends HookWidget {
  const MintsList({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 3);

    return Material(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(kDefaultPadding),
        topRight: Radius.circular(kDefaultPadding),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(kDefaultPadding),
            topRight: Radius.circular(kDefaultPadding),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          initialChildSize: 0.9,
          builder: (context, scrollController) {
            return BlocBuilder<CashuWalletManagerCubit,
                CashuWalletManagerState>(
              builder: (context, state) {
                final hasInactiveMintsWithBalance = state.mints.entries.any(
                    (e) =>
                        !state.walletMints.contains(e.key) &&
                        e.value.balance > 0);

                return Column(
                  children: [
                    const ModalBottomSheetHandle(),
                    TabBar(
                      controller: tabController,
                      dividerHeight: 0,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: Theme.of(context).primaryColor,
                      labelStyle:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                      tabs: [
                        Tab(
                          text: context.t.active,
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: kDefaultPadding / 4,
                            children: [
                              if (hasInactiveMintsWithBalance) ...[
                                const Icon(
                                  Icons.warning_rounded,
                                  size: 15,
                                  color: kYellow,
                                ),
                              ],
                              Text(context.t.inactive),
                            ],
                          ),
                        ),
                        Tab(
                          text: context.t.recommended,
                        ),
                      ],
                    ),
                    const SizedBox(height: kDefaultPadding / 2),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          _activeMintsList(
                            scrollController: scrollController,
                          ),
                          _inactiveMintsList(
                            scrollController: scrollController,
                          ),
                          _recommendedList(
                            scrollController: scrollController,
                          ),
                        ],
                      ),
                    )
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _activeMintsList({required ScrollController scrollController}) {
    return ActiveMintsList(scrollController: scrollController);
  }

  Widget _inactiveMintsList({required ScrollController scrollController}) {
    return InactiveMintsList(scrollController: scrollController);
  }

  Widget _recommendedList({required ScrollController scrollController}) {
    return BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
      builder: (context, state) {
        return ListView.separated(
          controller: scrollController,
          itemCount: state.recommendedMints.length,
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          separatorBuilder: (context, index) =>
              const SizedBox(height: kDefaultPadding / 3),
          itemBuilder: (context, index) {
            final mint = state.recommendedMints[index];

            return MintContainer(
              isActive: false,
              isAvailableInMintList: state.walletMints.contains(mint.mintURL),
              inActiveList: false,
              url: mint.mintURL,
              mintInfo: mint,
              onActionTap: () {
                cashuWalletManagerCubit.updateMintList(mint.mintURL);
              },
              onTap: () {
                YNavigator.pushPage(
                  context,
                  (context) => MintDetails(mintInfo: mint),
                );
              },
            );
          },
        );
      },
    );
  }
}

class InactiveMintsList extends HookWidget {
  const InactiveMintsList({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
      builder: (context, state) {
        final mints = state.mints.entries
            .where((e) =>
                !state.walletMints.contains(e.key) && e.value.balance > 0)
            .map((e) => e.value)
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: kDefaultPadding / 4,
                  children: [
                    Text(
                      context.t.inactiveMints,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      context.t.inactiveMintsDesc,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              if (mints.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyList(
                    description: context.t.noMintsAvailable,
                    icon: FeatureIcons.inactiveMints,
                  ),
                )
              else
                SliverList.separated(
                  itemCount: mints.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: kDefaultPadding / 3),
                  itemBuilder: (context, index) {
                    final mint = mints[index];

                    return MintContainer(
                      isAvailableInMintList: false,
                      isActive: state.activeMint == mint.mintURL,
                      url: mint.mintURL,
                      mintInfo: mint.info,
                      inActiveList: false,
                      balance: mint.balance,
                      onActionTap: () {
                        cashuWalletManagerCubit.updateMintList(mint.mintURL);
                      },
                      onTap: () {
                        YNavigator.pushPage(
                          context,
                          (context) => MintDetails(mintInfo: mint.info!),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class ActiveMintsList extends HookWidget {
  const ActiveMintsList({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final textEdittingController = useTextEditingController();
    final text = useState('');

    return BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
      builder: (context, state) {
        final mints = state.walletMints.toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSearchField(context, textEdittingController, text),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              if (mints.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyList(
                    description: context.t.noMintsAvailable,
                    icon: FeatureIcons.note,
                  ),
                )
              else
                _buildMintsList(state, mints),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kBottomNavigationBarHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField(
    BuildContext context,
    TextEditingController textEdittingController,
    ValueNotifier<String> text,
  ) {
    return TextFormField(
      controller: textEdittingController,
      onChanged: (value) {
        text.value = value;
      },
      decoration: InputDecoration(
        hintText: context.t.mintUrl,
        prefixIcon: SvgPicture.asset(
          FeatureIcons.search,
          width: 20,
          height: 20,
          fit: BoxFit.scaleDown,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        suffixIcon: text.value.isEmpty
            ? null
            : CustomIconButton(
                onClicked: () async {
                  HapticFeedback.mediumImpact();
                  final isSuccess =
                      await cashuWalletManagerCubit.updateMintList(
                    text.value,
                    checkBeforeUpdate: true,
                  );

                  if (isSuccess) {
                    textEdittingController.clear();
                    text.value = '';
                  }
                },
                icon: FeatureIcons.addRaw,
                size: 20,
                backgroundColor: kTransparent,
              ),
      ),
    );
  }

  Widget _buildMintsList(
    CashuWalletManagerState state,
    List<String> mints,
  ) {
    return SliverList.separated(
      itemCount: mints.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: kDefaultPadding / 3),
      itemBuilder: (context, index) {
        final wm = mints[index];
        final mint = state.mints[wm]!;

        return MintContainer(
          isAvailableInMintList: true,
          isActive: state.activeMint == mint.mintURL,
          inActiveList: true,
          url: mint.mintURL,
          balance: mint.balance,
          mintInfo: mint.info,
          onActionTap: () {
            cashuWalletManagerCubit.updateMintList(mint.mintURL);
          },
          onTap: () {
            context.read<CashuWalletManagerCubit>().setActiveMint(mint.mintURL);
            YNavigator.pop(context);
          },
        );
      },
    );
  }
}

class MintContainer extends StatelessWidget {
  const MintContainer({
    super.key,
    required this.isAvailableInMintList,
    required this.inActiveList,
    required this.isActive,
    required this.url,
    this.mintInfo,
    this.onActionTap,
    this.onTap,
    this.balance,
  });

  final bool isAvailableInMintList;
  final bool inActiveList;
  final bool isActive;
  final String url;
  final Function()? onTap;
  final MintInfo? mintInfo;
  final int? balance;
  final Function()? onActionTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.mediumImpact();
        }

        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: _buildItemDecoration(context, isActive),
        child: Row(
          spacing: kDefaultPadding / 2,
          children: [
            CommonThumbnail(
              image: mintInfo?.iconUrl ?? '',
              assetUrl: Images.cashu,
              width: 50,
              height: 50,
              radius: kDefaultPadding / 2,
              isRound: true,
            ),
            Expanded(
              child: _MintItemContent(
                mintInfo: mintInfo,
                url: url,
                balance: balance,
              ),
            ),
            if (!inActiveList)
              Row(
                spacing: kDefaultPadding / 4,
                children: [
                  if (mintInfo != null)
                    CustomIconButton(
                      onClicked: () {
                        HapticFeedback.mediumImpact();
                        YNavigator.pushPage(
                          context,
                          (context) => MintDetails(mintInfo: mintInfo!),
                        );
                      },
                      icon: FeatureIcons.informationRaw,
                      size: 20,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    ),
                  if (onActionTap != null)
                    CustomIconButton(
                      onClicked: () {
                        HapticFeedback.mediumImpact();
                        onActionTap!();
                      },
                      icon: isAvailableInMintList
                          ? FeatureIcons.trash
                          : FeatureIcons.addRaw,
                      size: 20,
                      iconColor: isAvailableInMintList
                          ? kRed
                          : Theme.of(context).primaryColorDark,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    ),
                ],
              )
            else
              PullDownButton(
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
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        cashuWalletManagerCubit.syncMintData(url);
                      },
                      title: context.t.syncData.capitalizeFirst(),
                      iconWidget: SvgPicture.asset(
                        FeatureIcons.restore,
                        height: 20,
                        width: 20,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
                      itemTheme: PullDownMenuItemTheme(
                        textStyle: textStyle,
                      ),
                    ),
                    PullDownMenuItem(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        YNavigator.pushPage(
                          context,
                          (context) => MintDetails(mintInfo: mintInfo!),
                        );
                      },
                      title: context.t.info.capitalizeFirst(),
                      iconWidget: SvgPicture.asset(
                        FeatureIcons.informationRaw,
                        height: 20,
                        width: 20,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
                      itemTheme: PullDownMenuItemTheme(
                        textStyle: textStyle,
                      ),
                    ),
                    const PullDownMenuDivider.large(),
                    PullDownMenuItem(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onActionTap!();
                      },
                      title: context.t.delete.capitalizeFirst(),
                      isDestructive: true,
                      iconWidget: SvgPicture.asset(
                        FeatureIcons.trash,
                        height: 20,
                        width: 20,
                        colorFilter: const ColorFilter.mode(
                          kRed,
                          BlendMode.srcIn,
                        ),
                      ),
                      itemTheme: PullDownMenuItemTheme(
                        textStyle: textStyle,
                      ),
                    ),
                  ];
                },
                buttonBuilder: (context, showMenu) => CustomIconButton(
                  size: 20,
                  backgroundColor: kTransparent,
                  onClicked: showMenu,
                  icon: FeatureIcons.more,
                ),
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildItemDecoration(BuildContext context, bool isActive) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      border: Border.all(
        color: isActive
            ? Theme.of(context).primaryColor
            : Theme.of(context).dividerColor,
        width: isActive ? 1 : 0.5,
      ),
      color: Theme.of(context).cardColor,
    );
  }
}

class _MintItemContent extends StatelessWidget {
  const _MintItemContent({
    required this.mintInfo,
    required this.url,
    this.balance,
  });

  final MintInfo? mintInfo;
  final String url;
  final int? balance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                mintInfo?.name ?? url,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (balance != null) ...[
              DotContainer(color: Theme.of(context).primaryColor),
              Text(
                '$balance sats',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ]
          ],
        ),
        if (mintInfo != null)
          Text(
            mintInfo!.description,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
