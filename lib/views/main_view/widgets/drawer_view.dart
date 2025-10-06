// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:numeral/numeral.dart';

import '../../../logic/main_cubit/main_cubit.dart';
import '../../../logic/points_management_cubit/points_management_cubit.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../routes/pages_router.dart';
import '../../../utils/utils.dart';
import '../../dashboard_view/dashboard_view.dart';
import '../../explore_relays_view/explore_relays_view.dart';
import '../../logify_view/logify_view.dart';
import '../../points_management_view/points_management_view.dart';
import '../../points_management_view/widgets/points_login_popup.dart';
import '../../profile_view/profile_view.dart';
import '../../settings_view/settings_view.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/modal_with_blur.dart';
import '../../widgets/nip05_component.dart';
import '../../widgets/profile_picture.dart';
import 'accounts_manager.dart';
import 'profile_share_view.dart';

class MainViewDrawer extends HookWidget {
  const MainViewDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        return Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding,
              vertical: kDefaultPadding / 1.5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                kDefaultPadding,
              ),
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
      },
    );
  }

  Column _items(BuildContext context, MainState state) {
    return Column(
      children: [
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
        if (currentSigner != null)
          _accountManager(context)
        else
          _login(context),
        if (canSign()) _walletManager(),
        const SizedBox(
          height: kBottomNavigationBarHeight / 2,
        ),
      ],
    );
  }

  BlocBuilder<WalletsManagerCubit, WalletsManagerState> _walletManager() {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, lightningState) {
        if (lightningState.wallets.isEmpty) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            context.read<MainCubit>().updateIndex(MainViews.wallet);
            Scaffold.of(context).closeDrawer();
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
                    const VerticalDivider(
                      thickness: 2,
                      color: kMainColor,
                      width: 0,
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 1.5,
                    ),
                    _walletInfo(lightningState, context),
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
  }

  Expanded _walletInfo(
      WalletsManagerState lightningState, BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  lightningState.isWalletHidden
                      ? '*****'
                      : '${lightningState.balance != -1 ? lightningState.balance : 'N/A'}',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 3,
              ),
              SvgPicture.asset(
                FeatureIcons.sats,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 8,
          ),
          Row(
            children: [
              Text(
                '~ \$${lightningState.isWalletHidden ? '*****' : lightningState.balanceInUSD == -1 ? 'N/A' : lightningState.balanceInUSD.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                ' USD',
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
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
                Scaffold.of(context).closeDrawer();
              }
            },
          );
        },
        icon: SvgPicture.asset(
          FeatureIcons.log,
          width: kToolbarHeight / 2.5,
          height: kToolbarHeight / 2.5,
          colorFilter: const ColorFilter.mode(
            kWhite,
            BlendMode.srcIn,
          ),
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
                icon: SvgPicture.asset(
                  FeatureIcons.qr,
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
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
          showModalBottomSheet(
            context: context,
            elevation: 0,
            builder: (_) {
              return BlocProvider.value(
                value: context.read<MainCubit>(),
                child: AccountManager(
                  scaffoldContext: context,
                ),
              );
            },
            isScrollControlled: true,
            useRootNavigator: true,
            useSafeArea: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        child: ListView(
          children: [
            if (canSign()) ...[
              _profileDrawerItem(state, context),
            ],
            _relaysOrbitDrawerItem(state, context),
            if (canSign()) ...[
              _smartWidgetDrawerItem(state, context),
              _dashboardDrawerItem(state, context),
            ],
            _settingDrawerItem(state, context),
          ],
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

        Scaffold.of(context).closeDrawer();
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

        Scaffold.of(context).closeDrawer();
      },
      icon: FeatureIcons.dashboard2,
      selectedIcon: FeatureIcons.propertiesFilled,
      title: context.t.dashboard.capitalizeFirst(),
    );
  }

  DrawerItem _smartWidgetDrawerItem(MainState state, BuildContext context) {
    return DrawerItem(
      isSelected: state.mainView == MainViews.smartWidgets,
      onClicked: () {
        context.read<MainCubit>().updateIndex(MainViews.smartWidgets);
        Scaffold.of(context).closeDrawer();
      },
      icon: FeatureIcons.smartWidget,
      selectedIcon: FeatureIcons.smartWidgetFilled,
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

        Scaffold.of(context).closeDrawer();
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

        Scaffold.of(context).closeDrawer();
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
        if (state.userGlobalStats != null) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              Scaffold.of(context).closeDrawer();
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
              Scaffold.of(context).closeDrawer();
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
              child: SvgPicture.asset(
                FeatureIcons.reward,
                width: 25,
                height: 25,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
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
            child: Row(
              children: [
                ProfilePicture2(
                  size: 45,
                  image: state.image,
                  pubkey: state.pubKey,
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
                              nostrRepository.currentMetadata.getName(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Nip05Component(
                              metadata: nostrRepository.currentMetadata,
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
                  color: kMainColor,
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
  final String icon;
  final String selectedIcon;
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
        leading: SvgPicture.asset(
          isSelected ? selectedIcon : icon,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
          width: 24,
          height: 24,
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
