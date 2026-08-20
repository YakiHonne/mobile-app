// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:numeral/numeral.dart';

import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../logic/main_cubit/main_cubit.dart';
import '../../../logic/points_management_cubit/points_management_cubit.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../routes/pages_router.dart';
import '../../../utils/utils.dart';
import '../../creators_subscriptions_view/creators_subscriptions_view.dart';
import '../../dashboard_view/dashboard_view.dart';
import '../../explore_packs_view/explore_packs_view.dart';
import '../../explore_relays_view/explore_relays_view.dart';
import '../../logify_view/logify_view.dart';
import '../../points_management_view/points_management_view.dart';
import '../../points_management_view/widgets/points_login_popup.dart';
import '../../profile_view/profile_view.dart';
import '../../settings_view/blossom_management_view.dart';
import '../../settings_view/settings_view.dart';
import '../../subscription_view/subscription_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/modal_with_blur.dart';
import '../../widgets/nip05_component.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/upgrade_banner.dart';
import 'accounts_manager.dart';
import 'profile_share_view.dart';

/// GlassScaffold has no drawer slot, so fluid mode drives the drawer by hand:
/// MainView parks it behind the body and slides the body aside on open.
/// ponytail: no swipe-to-open — add a horizontal drag if it's missed.
final mainDrawerOpen = ValueNotifier(false);

/// Standard Material drawer width — how far the body is pushed in fluid mode.
const kMainDrawerWidth = 304.0;

/// Lets callers close the drawer from a context that isn't under the main
/// Scaffold (modal sheets, post-pop callbacks) where `Scaffold.of` throws.
final mainScaffoldKey = GlobalKey<ScaffoldState>();

void openMainDrawer(BuildContext context) {
  if (isFluid()) {
    mainDrawerOpen.value = true;
  } else {
    Scaffold.of(context).openDrawer();
  }
}

void closeMainDrawer(BuildContext context) {
  if (isFluid()) {
    mainDrawerOpen.value = false;
  } else {
    mainScaffoldKey.currentState?.closeDrawer();
  }
}

class MainViewDrawer extends HookWidget {
  const MainViewDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isGlass = themeCubit.state.isFluid;

    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        if (!isGlass) {
          return Drawer(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 1.5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding),
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: _items(context, state),
            ),
          );
        }

        // Glass mode: bare items, a hairline marking the seam with the body.
        return Container(
          width: kMainDrawerWidth,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kDefaultPadding,
            bottom: MediaQuery.of(context).padding.bottom + kDefaultPadding,
            left: kDefaultPadding / 1.5,
            right: kDefaultPadding / 1.5,
          ),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: _items(context, state),
        );
      },
    );
  }

  Column _items(BuildContext context, MainState state) {
    return Column(
      children: [
        if (!isFluid())
          const SizedBox(
            height: kToolbarHeight / 1.2,
          ),
        if (currentSigner == null)
          SvgPicture.asset(
            LogosIcons.logoBlack,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          )
        else
          _userRow(state),
        const SizedBox(
          height: kDefaultPadding,
        ),
        _drawerItems(context, state),
        const UpgradeBanner(),
        if (currentSigner != null)
          _accountManager(context)
        else
          _login(context),
        if (canSign()) _walletManager(state),
        if (!isFluid())
          const SizedBox(
            height: kBottomNavigationBarHeight / 2,
          ),
      ],
    );
  }

  Widget _walletManager(MainState mainState) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, lightningState) {
        return BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
          builder: (context, cashuState) {
            final isCashu = mainState.isCashuWallet;

            if (!isCashu && lightningState.wallets.isEmpty) {
              return const SizedBox.shrink();
            }

            final rate =
                walletManagerCubit.btcInFiat[lightningState.activeCurrency];
            final cashuFiat = (cashuState.balance != -1 && rate != null)
                ? (cashuState.balance / 100000000) * rate
                : -1.0;

            final balance =
                isCashu ? cashuState.balance : lightningState.balance;
            final balanceInFiat =
                isCashu ? cashuFiat : lightningState.balanceInFiat;
            final isHidden = lightningState.isWalletHidden;
            final activeCurrency = lightningState.activeCurrency;

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                context.read<MainCubit>().updateIndex(MainViews.wallet);
                closeMainDrawer(context);
              },
              child: Column(
                children: [
                  const Divider(
                    height: kDefaultPadding / 2,
                    indent: kDefaultPadding / 2,
                    endIndent: kDefaultPadding / 2,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        const SizedBox(
                          width: kDefaultPadding / 2,
                        ),
                        VerticalDivider(
                          thickness: 2,
                          color: Theme.of(context).primaryColor,
                          width: 0,
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 1.5,
                        ),
                        _walletInfo(
                          balance,
                          balanceInFiat,
                          activeCurrency,
                          isHidden,
                          context,
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 1.5,
                        ),
                        CustomIconButton(
                          onClicked: () {
                            walletManagerCubit.toggleWallet();
                          },
                          icon: !lightningState.isWalletHidden
                              ? FeatureIcons.notVisible
                              : FeatureIcons.visible,
                          size: 22,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Expanded _walletInfo(
    int balance,
    double balanceInFiat,
    String activeCurrency,
    bool isHidden,
    BuildContext context,
  ) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  isHidden ? '*****' : '${balance != -1 ? balance : 'N/A'}',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 3,
              ),
              AppIcon(
                FeatureIcons.sats,
                size: 20,
                color: Theme.of(context).primaryColorDark,
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 8,
          ),
          Row(
            spacing: kDefaultPadding / 4,
            children: [
              Text(
                '${currenciesSymbols[activeCurrency]}${isHidden ? '*****' : balanceInFiat == -1 ? 'N/A' : balanceInFiat.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                activeCurrency.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          )
        ],
      ),
    );
  }

  SizedBox _login(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          YNavigator.push(
            context,
            OpacityAnimationPageRoute(
              builder: (context) => LogifyView(),
              settings: const RouteSettings(),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500)).then(
            (value) {
              if (context.mounted) {
                closeMainDrawer(context);
              }
            },
          );
        },
        icon: const AppIcon(
          FeatureIcons.log,
          size: kToolbarHeight / 2.5,
          color: kWhite,
        ),
        label: Text(
          context.t.login.capitalizeFirst(),
        ),
      ),
    );
  }

  Row _accountManager(BuildContext context) {
    return Row(
      children: [
        _manageAccounts(context),
        _profileShareView(),
      ],
    );
  }

  Builder _profileShareView() {
    return Builder(
      builder: (context) {
        void onClick() {
          Navigator.push(
            context,
            createViewFromBottom(
              BlocProvider.value(
                value: context.read<MainCubit>(),
                child: ConnectedUserProfileShareView(),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: onClick,
          behavior: HitTestBehavior.translucent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onClick,
                style: IconButton.styleFrom(
                  visualDensity: const VisualDensity(
                    horizontal: -3,
                    vertical: -3,
                  ),
                ),
                icon: AppIcon(
                  FeatureIcons.qr,
                  size: 25,
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Expanded _manageAccounts(BuildContext context) {
    return Expanded(
      child: DrawerItem(
        isSelected: false,
        onClicked: () {
          showAppModalSheet(
            context: context,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            builder: (_) => BlocProvider.value(
              value: context.read<MainCubit>(),
              child: AccountManager(
                scaffoldContext: context,
              ),
            ),
          );
        },
        icon: FeatureIcons.repost,
        selectedIcon: FeatureIcons.repost,
        title: context.t.manageAccounts.capitalizeFirst(),
      ),
    );
  }

  Expanded _drawerItems(BuildContext context, MainState state) {
    return Expanded(
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ScrollShadow(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            children: [
              if (canSign()) ...[
                _profileDrawerItem(state, context),
              ],
              _articlesDrawerItem(state, context),
              _exploreDrawerItem(state, context),
              _relaysOrbitDrawerItem(state, context),
              if (canSign()) ...[
                _smartWidgetDrawerItem(state, context),
                _dashboardDrawerItem(state, context),
                _subscriptionDrawerItem(state, context),
                _blossomDrawerItem(state, context),
                // Store rules forbid surfacing external paid subscriptions in
                // IAP builds.
                if (!kIapEnabled)
                  _creatorsSubscriptionsDrawerItem(state, context),
              ],
              _settingDrawerItem(state, context),
            ],
          ),
        ),
      ),
    );
  }

  DrawerItem _settingDrawerItem(MainState state, BuildContext context) {
    return DrawerItem(
      isSelected: state.mainView == MainViews.hidden,
      onClicked: () {
        YNavigator.pushPage(
          context,
          (context) => SettingsView(),
        );

        closeMainDrawer(context);
      },
      icon: FeatureIcons.settings,
      selectedIcon: FeatureIcons.propertiesFilled,
      title: context.t.settings.capitalizeFirst(),
    );
  }

  DrawerItem _dashboardDrawerItem(MainState state, BuildContext context) {
    return DrawerItem(
      isSelected: state.mainView == MainViews.hidden,
      onClicked: () {
        YNavigator.pushPage(
          context,
          (context) => DashboardView(),
        );

        closeMainDrawer(context);
      },
      icon: FeatureIcons.dashboard2,
      selectedIcon: FeatureIcons.propertiesFilled,
      title: context.t.dashboard.capitalizeFirst(),
    );
  }

  DrawerItem _subscriptionDrawerItem(MainState state, BuildContext context) {
    return DrawerItem(
      isSelected: state.mainView == MainViews.hidden,
      onClicked: () {
        YNavigator.pushPage(
          context,
          (context) => const SubscriptionView(),
        );

        closeMainDrawer(context);
      },
      icon: FeatureIcons.walletAvailable,
      selectedIcon: FeatureIcons.walletAvailable,
      title: context.t.subscription.capitalizeFirst(),
    );
  }

  DrawerItem _blossomDrawerItem(MainState state, BuildContext context) {
    return DrawerItem(
      isSelected: state.mainView == MainViews.hidden,
      onClicked: () {
        YNavigator.pushPage(
          context,
          (context) => const BlossomManagementView(),
        );

        closeMainDrawer(context);
      },
      icon: FeatureIcons.media,
      selectedIcon: FeatureIcons.media,
      title: context.t.blossomStorage.capitalizeFirst(),
    );
  }

  DrawerItem _creatorsSubscriptionsDrawerItem(
    MainState state,
    BuildContext context,
  ) {
    return DrawerItem(
      isSelected: false,
      onClicked: () {
        YNavigator.pushPage(
          context,
          (context) => const CreatorsSubscriptionsView(),
        );

        closeMainDrawer(context);
      },
      icon: LucideIcons.crown,
      selectedIcon: LucideIcons.crown,
      title: context.t.creatorsSubscriptions.capitalizeFirst(),
    );
  }

  DrawerItem _articlesDrawerItem(MainState state, BuildContext context) {
    return DrawerItem(
      isSelected: state.mainView == MainViews.articles,
      onClicked: () {
        context.read<MainCubit>().updateIndex(MainViews.articles);
        closeMainDrawer(context);
      },
      icon: FeatureIcons.article,
      selectedIcon: FeatureIcons.articleFilled,
      title: context.t.articles.capitalizeFirst(),
    );
  }

  DrawerItem _exploreDrawerItem(MainState state, BuildContext context) {
    return DrawerItem(
      isSelected: false,
      onClicked: () {
        YNavigator.pushPage(
          context,
          (context) => const ExplorePacksView(),
        );

        closeMainDrawer(context);
      },
      icon: FeatureIcons.discover,
      selectedIcon: FeatureIcons.discoverFilled,
      title: context.t.explore.capitalizeFirst(),
    );
  }

  DrawerItem _smartWidgetDrawerItem(MainState state, BuildContext context) {
    return DrawerItem(
      isSelected: state.mainView == MainViews.smartWidgets,
      onClicked: () {
        context.read<MainCubit>().updateIndex(MainViews.smartWidgets);
        closeMainDrawer(context);
      },
      icon: FeatureIcons.smartWidget,
      selectedIcon: FeatureIcons.smartWidget,
      title: context.t.smartWidget.capitalizeFirst(),
    );
  }

  DrawerItem _relaysOrbitDrawerItem(MainState state, BuildContext context) {
    return DrawerItem(
      isSelected: state.mainView == MainViews.hidden,
      onClicked: () {
        YNavigator.pushPage(
          context,
          (context) => const ExploreRelaysView(),
        );

        closeMainDrawer(context);
      },
      icon: FeatureIcons.relaysOrbit,
      selectedIcon: FeatureIcons.relaysOrbit,
      title: context.t.relayOrbits.capitalizeFirst(),
    );
  }

  DrawerItem _profileDrawerItem(MainState state, BuildContext context) {
    return DrawerItem(
      isSelected: state.mainView == MainViews.hidden,
      onClicked: () {
        YNavigator.pushPage(
          context,
          (context) => ProfileView(
            pubkey: state.pubKey,
          ),
        );

        closeMainDrawer(context);
      },
      icon: FeatureIcons.user,
      selectedIcon: FeatureIcons.user,
      title: context.t.profile.capitalizeFirst(),
    );
  }

  Row _userRow(MainState state) {
    return Row(
      children: [
        _profileRow(state),
        if (canSign()) _pointsSystem(),
      ],
    );
  }

  BlocBuilder<PointsManagementCubit, PointsManagementState> _pointsSystem() {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        if (state.isSystemLoggedIn) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              closeMainDrawer(context);
              Navigator.pushNamed(
                context,
                PointsStatisticsView.routeName,
              );
            },
            child: PointsPercentage(
              currentXp: state.currentXp,
              nextLevelXp: state.nextLevelXp,
              additionalXp: state.additionalXp,
              currentLevelXp: state.currentLevelXp,
              currentLevel: state.currentLevel,
              percentage: state.percentage,
              backgroundColor:
                  Theme.of(context).highlightColor.withValues(alpha: 0.1),
            ),
          );
        } else {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              closeMainDrawer(context);
              showBlurredModal(
                context: context,
                view: const PointsLoginPopup(),
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
              ),
              alignment: Alignment.center,
              child: AppIcon(
                FeatureIcons.reward,
                size: 25,
                color: Theme.of(context).primaryColorDark,
              ),
            ),
          );
        }
      },
    );
  }

  Expanded _profileRow(MainState state) {
    return Expanded(
      child: Builder(
        builder: (context) {
          void f() {
            openProfileFastAccess(
              context: context,
              pubkey: state.pubKey,
            );
          }

          return GestureDetector(
            onTap: f,
            behavior: HitTestBehavior.translucent,
            child: MetadataProvider(
              pubkey: state.pubKey,
              child: (metadata, isNip05) => Row(
                children: [
                  ProfilePicture2(
                    size: 45,
                    image: metadata.picture,
                    pubkey: metadata.pubkey,
                    padding: 0,
                    strokeWidth: 0,
                    strokeColor: kTransparent,
                    onClicked: f,
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metadata.getName(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Nip05Component(
                                metadata: metadata,
                                removeSpace: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PointsPercentage extends HookWidget {
  const PointsPercentage({
    super.key,
    required this.currentXp,
    required this.nextLevelXp,
    required this.additionalXp,
    required this.currentLevelXp,
    required this.currentLevel,
    required this.percentage,
    this.backgroundColor,
  });

  final int currentXp;
  final int nextLevelXp;
  final int additionalXp;
  final int currentLevelXp;
  final int currentLevel;
  final double percentage;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(seconds: 1),
    );

    final animation = Tween<double>(begin: 0, end: percentage).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    useEffect(
      () {
        animationController.forward();
        return;
      },
      [animationController],
    );

    return SizedBox(
      width: 55,
      height: 55,
      child: Stack(
        children: [_animatedCircle(animation), _xpColumn(context)],
      ),
    );
  }

  Positioned _animatedCircle(Animation<double> animation) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => CircularProgressIndicator(
          strokeWidth: 3,
          value: animation.value,
          color: getPercentageColor(animation.value * 100),
          strokeCap: StrokeCap.round,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }

  Center _xpColumn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${currentXp.numeral(digits: 1)} xp',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  height: 1,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 8,
          ),
          Text(
            'LVL $currentLevel',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  const DrawerItem({
    super.key,
    required this.isSelected,
    required this.onClicked,
    required this.icon,
    required this.selectedIcon,
    required this.title,
  });

  final bool isSelected;
  final Function() onClicked;
  final IconData icon;
  final IconData selectedIcon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: kTransparent,
      ),
      child: ListTile(
        onTap: onClicked,
        contentPadding: const EdgeInsets.only(left: kDefaultPadding / 4),
        horizontalTitleGap: kDefaultPadding / 2,
        visualDensity: const VisualDensity(vertical: -1),
        splashColor: kTransparent,
        leading: AppIcon(
          isSelected ? selectedIcon : icon,
          color: Theme.of(context).primaryColorDark,
          size: 24,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
        trailing: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 4 : 0,
          height: isSelected ? 4 : 0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).primaryColorDark,
          ),
        ),
      ),
    );
  }
}
