// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/main_cubit/main_cubit.dart';
import '../../../logic/unsent_events_cubit/unsent_events_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../discover_view/discover_view.dart';
import '../../notifications_view/widgets/notifications_customization.dart';
import '../../search_view/search_view.dart';
import '../../wallet_view/widgets/transactions_list.dart';
import '../../widgets/animated_components/animated_line.dart';
import '../../widgets/animated_flip_counter.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/unsent_events_view.dart';
import 'app_bar_widgets.dart';

class MainViewAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function() onClicked;
  final bool isConnected;

  const MainViewAppBar({
    super.key,
    required this.onClicked,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isConnected)
            const SizedBox.shrink()
          else
            Stack(
              children: [
                const SizedBox(
                  width: double.infinity,
                  height: 15,
                ),
                _offlineColumn(context),
                _eventsCount(context),
              ],
            ),
          BlocBuilder<MainCubit, MainState>(
            builder: (context, state) {
              return AppBar(
                elevation: isNotElevated(state) ? 0 : null,
                scrolledUnderElevation: isNotElevated(state) ? 0 : null,
                titleSpacing: 0,
                leading: _buildLeading(context, state),
                title: _buildTitle(context, state),
                centerTitle: true,
                actions: _buildActions(context, state),
              );
            },
          ),
        ],
      ),
    );
  }

  Positioned _eventsCount(BuildContext context) {
    return Positioned(
      right: kDefaultPadding / 1.5,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (_) {
              return const UnsentEventsView();
            },
            isScrollControlled: true,
            useRootNavigator: true,
            useSafeArea: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        },
        behavior: HitTestBehavior.translucent,
        child: BlocBuilder<UnsentEventsCubit, UnsentEventsState>(
          builder: (context, state) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: kDefaultPadding / 8,
              children: [
                AnimatedFlipCounter(
                  value: state.events.length,
                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: kMainColor,
                      ),
                  enableAbbreviation: true,
                ),
                RotatedBox(
                  quarterTurns: 1,
                  child: SvgPicture.asset(
                    FeatureIcons.arrowUp,
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(
                      kMainColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Align _offlineColumn(BuildContext context) {
    return Align(
      child: Column(
        key: const ValueKey('offline'),
        mainAxisSize: MainAxisSize.min,
        spacing: kDefaultPadding / 4,
        children: [
          Text(
            context.t.waitingForNetwork,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).highlightColor,
                  height: 1,
                ),
          ),
          RepaintBoundary(
            child: SizedBox(
              width: 50.w,
              child: const AnimatedPulseLine(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeading(BuildContext context, MainState state) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Scaffold.of(context).openDrawer();
        },
        child: currentSigner != null
            ? MetadataProvider(
                child: (metadata, isNip05) => ProfilePicture2(
                  size: 35,
                  image: metadata.picture,
                  pubkey: metadata.pubkey,
                  padding: 0,
                  strokeWidth: 0,
                  strokeColor: kTransparent,
                  onClicked: () {
                    Scaffold.of(context).openDrawer();
                    walletManagerCubit.getWalletBalanceInFiat();
                  },
                ),
                pubkey: state.pubKey,
              )
            : SvgPicture.asset(
                FeatureIcons.menu,
                height: kToolbarHeight / 2.2,
                width: kToolbarHeight / 2.2,
                fit: BoxFit.scaleDown,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, MainState state) {
    if (state.mainView == MainViews.leading ||
        state.mainView == MainViews.discover) {
      return SizedBox(
        width: 50.w,
        child: Center(
          child: SourceButton(
            isDiscover: state.mainView == MainViews.discover,
            onSourceChanged: () {
              if (state.mainView == MainViews.leading) {
                leadingCubit.buildLeadingFeed(isAdding: false);
              } else {
                discoverCubit.buildDiscoverFeed(
                  exploreType: discoverCubit.exploreType,
                  isAdding: false,
                );
              }
            },
          ),
        ),
      );
    } else if (state.mainView == MainViews.wallet &&
        walletManagerCubit.state.wallets.isNotEmpty) {
      return const SelectedWalletContainer();
    } else if (state.mainView == MainViews.dms && canSign()) {
      return const InboxTypes();
    } else if (state.mainView == MainViews.notifications && canSign()) {
      return const NotificationTypes();
    } else {
      return FittedBox(
        fit: BoxFit.fitHeight,
        child: Text(
          getTitle(state.mainView, context),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      );
    }
  }

  List<Widget> _buildActions(BuildContext context, MainState state) {
    return [
      if (state.mainView == MainViews.leading ||
          state.mainView == MainViews.discover) ...[
        FilterGlobalButton(isDiscover: state.mainView == MainViews.discover),
      ],
      const SizedBox(width: kDefaultPadding / 8),
      if (state.mainView == MainViews.dms) ...[
        const DmOptionsButton(),
      ] else
        CustomIconButton(
          onClicked: () {
            if (state.mainView == MainViews.leading ||
                state.mainView == MainViews.discover) {
              YNavigator.pushPage(context, (context) => SearchView());
            } else if (state.mainView == MainViews.wallet) {
              doIfCanSign(
                func: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const TransactionsList(),
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                context: context,
              );
            } else if (state.mainView == MainViews.notifications) {
              doIfCanSign(
                func: () {
                  YNavigator.pushPage(
                    context,
                    (context) => const NotificationsCustomization(),
                  );
                },
                context: context,
              );
            }
          },
          icon: state.mainView == MainViews.wallet
              ? FeatureIcons.transactions
              : state.mainView == MainViews.notifications
                  ? FeatureIcons.settings
                  : FeatureIcons.search,
          size: 20,
          borderColor: Theme.of(context).dividerColor,
          backgroundColor: Theme.of(context).cardColor,
          vd: -1,
        ),
      const SizedBox(width: kDefaultPadding / 2),
    ];
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (isConnected ? 0 : kDefaultPadding * 1.5),
      );

  bool isNotElevated(MainState state) {
    return state.mainView == MainViews.uncensoredNotes ||
        state.mainView == MainViews.dms ||
        state.mainView == MainViews.notifications ||
        state.mainView == MainViews.smartWidgets;
  }

  String getTitle(MainViews mainView, BuildContext context) {
    if (mainView == MainViews.notifications) {
      return context.t.notifications.capitalizeFirst();
    } else if (mainView == MainViews.uncensoredNotes) {
      return context.t.verifyNotes.capitalizeFirst();
    } else if (mainView == MainViews.dms) {
      return context.t.inbox.capitalizeFirst();
    } else if (mainView == MainViews.leading) {
      return context.t.notes.capitalizeFirst();
    } else if (mainView == MainViews.discover) {
      return context.t.discover.capitalizeFirst();
    } else if (mainView == MainViews.wallet) {
      return context.t.wallet.capitalizeFirst();
    } else if (mainView == MainViews.smartWidgets) {
      return context.t.smartWidgets.capitalizeFirst();
    } else {
      return context.t.settings.capitalizeFirst();
    }
  }
}
