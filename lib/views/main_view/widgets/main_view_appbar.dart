// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../logic/main_cubit/main_cubit.dart';
import '../../../logic/notifications_cubit/notifications_cubit.dart';
import '../../../logic/unsent_events_cubit/unsent_events_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../utils/theme/glass_settings.dart';
import '../../../utils/utils.dart';
import '../../discover_view/discover_view.dart';
import '../../notifications_view/widgets/notifications_customization.dart';
import '../../search_view/search_view.dart';
import '../../wallet_cashu_view/widgets/cashu_history.dart';
import '../../wallet_cashu_view/widgets/cashu_restore_proofs.dart';
import '../../wallet_view/widgets/transactions_list.dart';
import '../../widgets/animated_components/animated_line.dart';
import '../../widgets/animated_flip_counter.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/unsent_events_view.dart';
import 'app_bar_widgets.dart';
import 'drawer_view.dart';
import 'feature_tour.dart';

mixin _AppBarHelpers on StatelessWidget {
  Function() get onClicked;
  bool get isConnected;
  List<ScrollController> get scrollControllers;

  GestureDetector _eventsCountRow(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showAppModalSheet(
          context: context,
          builder: (_) => const UnsentEventsView(),
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
                textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                enableAbbreviation: true,
              ),
              RotatedBox(
                quarterTurns: 1,
                child: AppIcon(
                  FeatureIcons.arrowUp,
                  size: 15,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Positioned _eventsCount(BuildContext context) {
    return Positioned(
      right: kDefaultPadding / 1.5,
      child: _eventsCountRow(context),
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
            context.t.reconnecting,
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

  Widget _offlineStatusRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      spacing: kDefaultPadding / 3,
      children: [
        SpinKitFadingCircle(
          color: Theme.of(context).primaryColor,
          size: 15,
        ),
        Expanded(
          child: Text(
            context.t.reconnecting,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ),
        _eventsCountRow(context),
      ],
    );
  }

  Widget _buildLeading(BuildContext context, MainState state) {
    return Center(
      child: GestureDetector(
        key: TourKeys.drawer,
        onTap: () => openMainDrawer(context),
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
                    openMainDrawer(context);
                    walletManagerCubit.getWalletBalanceInFiat();
                  },
                ),
                pubkey: state.pubKey,
              )
            : AppIcon(
                FeatureIcons.menu,
                size: kToolbarHeight / 2.2,
                color: Theme.of(context).primaryColorDark,
              ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, MainState state) {
    if (state.mainView == MainViews.leading ||
        state.mainView == MainViews.articles ||
        state.mainView == MainViews.media) {
      return SizedBox(
        key: TourKeys.title,
        width: min(50.w, 280),
        child: Center(
          child: SourceButton(
            viewType: state.mainView == MainViews.articles
                ? ViewDataTypes.articles
                : state.mainView == MainViews.leading
                    ? ViewDataTypes.notes
                    : ViewDataTypes.media,
            onSourceChanged: () {
              if (state.mainView == MainViews.leading) {
                leadingCubit.buildLeadingFeed(isAdding: false);
              } else if (state.mainView == MainViews.articles) {
                discoverCubit.buildDiscoverFeed(
                  exploreType: discoverCubit.exploreType,
                  isAdding: false,
                );
              } else if (state.mainView == MainViews.media) {
                scrollControllers[1].jumpTo(0);
                mediaCubit.buildMediaFeed(isAdding: false);
              }
            },
          ),
        ),
      );
    } else if (state.mainView == MainViews.wallet) {
      return const SelectedWalletContainer();
    } else if (state.mainView == MainViews.dms && canSign()) {
      return InboxTypes(scrollController: scrollControllers[3]);
    } else if (state.mainView == MainViews.notifications && canSign()) {
      return const NotificationTypes();
    } else {
      return FittedBox(
        fit: BoxFit.fitHeight,
        child: Text(
          _getTitle(state.mainView, context),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      );
    }
  }

  List<Widget> _buildActions(BuildContext context, MainState state) {
    final buttonBg =
        themeCubit.state.isFluid ? kTransparent : Theme.of(context).cardColor;
    return [
      if (state.mainView == MainViews.leading ||
          state.mainView == MainViews.articles ||
          state.mainView == MainViews.media) ...[
        FilterGlobalButton(
          viewType: state.mainView == MainViews.articles
              ? ViewDataTypes.articles
              : state.mainView == MainViews.leading
                  ? ViewDataTypes.notes
                  : ViewDataTypes.media,
        ),
      ] else if (state.mainView == MainViews.wallet && state.isCashuWallet) ...[
        BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
          builder: (context, state) {
            if (state.activeMint.isNotEmpty) {
              return CustomIconButton(
                onClicked: () {
                  showAppModalSheet(
                    context: context,
                    builder: (_) => CashuRestoreProofs(
                      mintUrl: state.activeMint,
                    ),
                  );
                },
                icon: FeatureIcons.restore,
                size: 20,
                borderColor: Theme.of(context).dividerColor,
                backgroundColor: buttonBg,
                vd: -1,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
      const SizedBox(width: kDefaultPadding / 8),
      if (state.mainView == MainViews.dms) ...[
        const DmOptionsButton(),
      ] else
        CustomIconButton(
          key: TourKeys.search,
          onClicked: () {
            if (state.mainView == MainViews.leading ||
                state.mainView == MainViews.articles ||
                state.mainView == MainViews.media) {
              YNavigator.pushPage(context, (context) => SearchView());
            } else if (state.mainView == MainViews.wallet) {
              doIfCanSign(
                func: () {
                  if (state.isCashuWallet) {
                    showAppModalSheet(
                      context: context,
                      builder: (context) => const CashuHistory(),
                    );
                  } else {
                    showAppModalSheet(
                      context: context,
                      builder: (_) => const TransactionsList(),
                    );
                  }
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
          borderColor:
              isFluid() ? kTransparent : Theme.of(context).dividerColor,
          backgroundColor: buttonBg,
          vd: -1,
        ),
      const SizedBox(width: kDefaultPadding / 2),
    ];
  }

  String _getTitle(MainViews mainView, BuildContext context) {
    if (mainView == MainViews.notifications) {
      return context.t.notifications.capitalizeFirst();
    } else if (mainView == MainViews.uncensoredNotes) {
      return context.t.verifyNotes.capitalizeFirst();
    } else if (mainView == MainViews.dms) {
      return context.t.inbox.capitalizeFirst();
    } else if (mainView == MainViews.leading) {
      return context.t.notes.capitalizeFirst();
    } else if (mainView == MainViews.articles) {
      return context.t.articles.capitalizeFirst();
    } else if (mainView == MainViews.media) {
      return context.t.media.capitalizeFirst();
    } else if (mainView == MainViews.wallet) {
      return context.t.wallet.capitalizeFirst();
    } else if (mainView == MainViews.smartWidgets) {
      return context.t.smartWidgets.capitalizeFirst();
    } else {
      return context.t.settings.capitalizeFirst();
    }
  }
}

// ==================================================
// GLASS variant — Positioned(top:0) in the body Stack
// ==================================================

class FluidMainViewAppBar extends StatelessWidget
    with _AppBarHelpers
    implements PreferredSizeWidget {
  @override
  final Function() onClicked;
  @override
  final bool isConnected;
  @override
  final List<ScrollController> scrollControllers;

  const FluidMainViewAppBar({
    super.key,
    required this.onClicked,
    required this.isConnected,
    required this.scrollControllers,
  });

  static const _toolbarHeight = 48.0;
  static const _buttonSize = 45.0;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        return GlassAppBar(
          toolbarHeight: _toolbarHeight,
          buttonSettings: GlassSettings.appBar(context),
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 1.5,
          ),
          // Profile picture — opens drawer
          leading: Padding(
            padding: const EdgeInsets.only(right: kDefaultPadding / 1.5),
            child: GlassButton.custom(
              key: TourKeys.drawer,
              width: _buttonSize,
              height: _buttonSize,
              onTap: () {
                openMainDrawer(context);
                walletManagerCubit.getWalletBalanceInFiat();
              },
              child: currentSigner != null
                  ? MetadataProvider(
                      child: (metadata, isNip05) => ProfilePicture2(
                        size: _buttonSize - 6,
                        image: metadata.picture,
                        pubkey: metadata.pubkey,
                        padding: 0,
                        strokeWidth: 0,
                        strokeColor: kTransparent,
                        onClicked: () {
                          openMainDrawer(context);
                          walletManagerCubit.getWalletBalanceInFiat();
                        },
                      ),
                      pubkey: state.pubKey,
                    )
                  : AppIcon(
                      FeatureIcons.menu,
                      size: 20,
                      color: Theme.of(context).primaryColorDark,
                    ),
            ),
          ),

          // Search bar — fills remaining width, or collapses to an icon-only
          // circle (with a network-status pill alongside) while offline.
          title: isConnected
              ? GestureDetector(
                  onTap: () {
                    YNavigator.pushPage(
                      context,
                      (context) => SearchView(),
                    );
                  },
                  behavior: HitTestBehavior.translucent,
                  child: FluidBlurContainer(
                    height: 45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: kDefaultPadding / 2,
                      children: [
                        AppIcon(
                          FeatureIcons.search,
                          size: 16,
                          color: Theme.of(context).highlightColor,
                        ),
                        Text(
                          context.t.search.capitalizeFirst(),
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: Theme.of(context).highlightColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              : Row(
                  spacing: kDefaultPadding / 4,
                  children: [
                    GestureDetector(
                      onTap: () {
                        YNavigator.pushPage(
                          context,
                          (context) => SearchView(),
                        );
                      },
                      behavior: HitTestBehavior.translucent,
                      child: FluidBlurContainer(
                        height: _buttonSize,
                        width: _buttonSize,
                        child: Center(
                          child: AppIcon(
                            FeatureIcons.search,
                            size: 16,
                            color: Theme.of(context).highlightColor,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: FluidBlurContainer(
                        height: _buttonSize,
                        padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding / 2,
                        ),
                        child: _offlineStatusRow(context),
                      ),
                    ),
                  ],
                ),
          actions: [
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, notiState) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppIconButton(
                      key: TourKeys.notifications,
                      iconSize: 22,
                      onClicked: () {
                        context
                            .read<MainCubit>()
                            .updateIndex(MainViews.notifications);
                        notificationsCubit.markRead();
                      },
                      icon: state.mainView == MainViews.notifications
                          ? FeatureIcons.notificationsFilled
                          : FeatureIcons.notification,
                    ),
                    if (!notiState.isRead && canSign())
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ==================================================
// NORMAL variant — used as Scaffold.appBar
// ==================================================

class MainViewAppBar extends StatelessWidget
    with _AppBarHelpers
    implements PreferredSizeWidget {
  @override
  final Function() onClicked;
  @override
  final bool isConnected;
  @override
  final List<ScrollController> scrollControllers;

  const MainViewAppBar({
    super.key,
    required this.onClicked,
    required this.isConnected,
    required this.scrollControllers,
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
                const SizedBox(width: double.infinity, height: 15),
                _offlineColumn(context),
                _eventsCount(context),
              ],
            ),
          BlocBuilder<MainCubit, MainState>(
            builder: (context, state) {
              return AppBar(
                elevation: _isNotElevated(state) ? 0 : null,
                scrolledUnderElevation: _isNotElevated(state) ? 0 : null,
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

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (isConnected ? 0 : kDefaultPadding * 1.5),
      );

  bool _isNotElevated(MainState state) {
    return state.mainView == MainViews.uncensoredNotes ||
        state.mainView == MainViews.dms ||
        state.mainView == MainViews.notifications ||
        state.mainView == MainViews.smartWidgets;
  }
}
