// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../logic/main_cubit/main_cubit.dart';
import '../../../logic/notifications_cubit/notifications_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/utils.dart';
import '../../widgets/buttons_containers_widgets.dart';

class MainViewBottomNavigationBar extends StatelessWidget {
  const MainViewBottomNavigationBar({
    super.key,
    required this.onClicked,
  });

  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        return Container(
          height: kBottomNavigationBarHeight +
              MediaQuery.of(context).padding.bottom,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(kDefaultPadding),
              topRight: Radius.circular(kDefaultPadding),
            ),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _homeButton(state, context),
              _discoverButton(state, context),
              _walletButton(state, context),
              _dmsButton(state),
              _notificationButton(state),
            ],
          ),
        );
      },
    );
  }

  Expanded _notificationButton(MainState state) {
    return Expanded(
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, notiState) {
          return Stack(
            children: [
              BottomNavBarItem(
                icon: FeatureIcons.notification,
                selectedIcon: FeatureIcons.notificationsFilled,
                isSelected: state.mainView == MainViews.notifications,
                onClicked: () {
                  if (state.mainView == MainViews.notifications) {
                    onClicked.call();
                  }
                  context
                      .read<MainCubit>()
                      .updateIndex(MainViews.notifications);
                  notificationsCubit.markRead();
                  HapticFeedback.mediumImpact();
                },
              ),
              if (canSign())
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 10),
                    child: DotContainer(
                      color: Colors.redAccent,
                      isNotMarging: true,
                      size: notiState.isRead ? 0 : 8,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Expanded _dmsButton(MainState state) {
    return Expanded(
      child: BlocBuilder<DmsCubit, DmsState>(
        builder: (context, dmState) {
          return Stack(
            children: [
              BottomNavBarItem(
                icon: FeatureIcons.message,
                selectedIcon: FeatureIcons.messageFilled,
                isSelected: state.mainView == MainViews.dms,
                onLongPress: dmsCubit.markAllAsRead,
                onClicked: () {
                  context.read<MainCubit>().updateIndex(MainViews.dms);
                  HapticFeedback.mediumImpact();
                },
              ),
              if (canSign())
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, bottom: 10),
                    child: FutureBuilder(
                      future: dmsCubit.gotMessages(),
                      builder: (context, snapshot) => DotContainer(
                        color: Colors.redAccent,
                        isNotMarging: true,
                        size: snapshot.hasData && snapshot.data! ? 8 : 0,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Expanded _walletButton(MainState state, BuildContext context) {
    return Expanded(
      child: BottomNavBarItem(
        icon: FeatureIcons.wallet,
        selectedIcon: FeatureIcons.walletFilled,
        isSelected: state.mainView == MainViews.wallet,
        onClicked: () {
          walletManagerCubit.requestBalance();
          context.read<MainCubit>().updateIndex(MainViews.wallet);
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }

  Expanded _discoverButton(MainState state, BuildContext context) {
    return Expanded(
      child: BottomNavBarItem(
        icon: FeatureIcons.discover,
        selectedIcon: FeatureIcons.discoverFilled,
        isSelected: state.mainView == MainViews.discover,
        onClicked: () {
          if (state.mainView == MainViews.discover) {
            onClicked.call();
          }
          context.read<MainCubit>().updateIndex(MainViews.discover);
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }

  Expanded _homeButton(MainState state, BuildContext context) {
    return Expanded(
      child: BottomNavBarItem(
        icon: FeatureIcons.home,
        selectedIcon: FeatureIcons.homeFilled,
        isSelected: state.mainView == MainViews.leading,
        onClicked: () {
          if (state.mainView == MainViews.leading) {
            onClicked.call();
          }

          context.read<MainCubit>().updateIndex(MainViews.leading);
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }
}

class RippleContainer extends HookWidget {
  const RippleContainer({
    super.key,
    required this.widget,
  });

  final Widget widget;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    useInterval(
      () {
        animationController
            .forward()
            .whenComplete(() => animationController.reverse())
            .whenComplete(
              () => animationController.forward().whenComplete(
                    () => animationController.reverse(),
                  ),
            );
      },
      const Duration(seconds: 5),
    );

    const regularSize = kToolbarHeight / 2;
    const addedSize = 5;

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return SizedBox(
          width: animationController.value * addedSize + regularSize,
          height: animationController.value * addedSize + regularSize,
          child: widget,
        );
      },
    );
  }
}

class BottomNavBarItem extends StatelessWidget {
  const BottomNavBarItem({
    super.key,
    required this.onClicked,
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
    this.color,
    this.onLongPress,
  });

  final Function() onClicked;
  final Function()? onLongPress;
  final bool isSelected;
  final String icon;
  final String selectedIcon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconAsset = SvgPicture.asset(
      isSelected ? selectedIcon : icon,
      width: kToolbarHeight / 2,
      height: kToolbarHeight / 2,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).primaryColorDark,
        BlendMode.srcIn,
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onClicked,
          onLongPress: onLongPress,
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              iconAsset,
              Center(
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  margin: EdgeInsets.only(top: isSelected ? 4 : 0),
                  width: isSelected ? 4 : 0,
                  height: isSelected ? 4 : 0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding),
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
