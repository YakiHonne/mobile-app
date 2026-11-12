import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../logic/main_cubit/main_cubit.dart';
import '../../../logic/notifications_cubit/notifications_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../routes/pages_router.dart';
import '../../../utils/theme/glass_settings.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/add_content_view.dart';
import '../../add_content_view/add_media_view.dart';
import '../../creators_subscriptions_view/creators_subscriptions_view.dart';
import '../../dashboard_view/dashboard_view.dart';
import '../../explore_packs_view/explore_packs_view.dart';
import '../../explore_relays_view/explore_relays_view.dart';
import '../../logify_view/logify_view.dart';
import '../../points_management_view/points_management_view.dart';
import '../../points_management_view/widgets/points_login_popup.dart';
import '../../profile_view/profile_view.dart';
import '../../search_view/search_view.dart';
import '../../settings_view/blossom_management_view.dart';
import '../../settings_view/settings_view.dart';
import '../../subscription_view/pricing/pricing_screen.dart';
import '../../subscription_view/subscription_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/modal_with_blur.dart';
import '../../widgets/nip05_component.dart';
import '../../widgets/profile_picture.dart';
import '../desktop/desktop_connection_status.dart';
import '../desktop/desktop_more_dialog.dart';
import '../desktop/desktop_rail_action.dart';
import '../desktop/desktop_smart_widgets_page.dart';
import 'accounts_manager.dart';
import 'feature_tour.dart';

/// Floating glass navigation rail for desktop. Replaces the bottom nav and the
/// hamburger drawer with persistent primary actions and a searchable More menu.
const double kDesktopSidebarWidth = 268;

/// Below this window width the labelled rail starves the content column, so it
/// collapses to icons with tooltips.
const double kDesktopSidebarCompactWidth = 72;
const double kSidebarCollapseWidth = 1450;
const double kDesktopCompactFooterSize = 43;

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.onScrollTop,
    required this.compact,
  });

  final VoidCallback onScrollTop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 1.5),
      child: SizedBox(
        width: compact ? kDesktopSidebarCompactWidth : kDesktopSidebarWidth,
        child: FluidBlurContainer(
          sigma: 20,
          borderRadius: kDefaultPadding * 1.75,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? kDefaultPadding / 4 : kDefaultPadding / 1.5,
            vertical: kDefaultPadding / 1.5,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                BlocBuilder<MainCubit, MainState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (constraints.maxHeight >= 550) ...[
                      _Brand(compact: compact),
                      const SizedBox(height: kDefaultPadding / 2),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        child: _navigation(context, state),
                      ),
                    ),
                    DesktopConnectionStatus(compact: compact),
                    DesktopComposeButton(compact: compact),
                    const SizedBox(height: kDefaultPadding / 4),
                    DesktopSettingsButton(
                      compact: compact,
                      label: context.t.settings.capitalizeFirst(),
                      onPressed: () => YNavigator.pushPage(
                        context,
                        (_) => SettingsView(),
                      ),
                    ),
                    const SizedBox(height: kDefaultPadding / 4),
                    _AccountFooter(compact: compact),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigation(BuildContext context, MainState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchField(key: TourKeys.search, compact: compact),
          _primaryDestinations(context, state),
          _item(
            icon: Icons.more_horiz,
            selectedIcon: Icons.more_horiz,
            title: context.t.more.capitalizeFirst(),
            isSelected: state.mainView == MainViews.articles ||
                state.mainView == MainViews.smartWidgets,
            onClicked: () => _openMore(context, state),
          ),
        ],
      );

  /// Injects [compact] so each destination below stays a one-liner.
  _RailItem _item({
    Key? key,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required bool isSelected,
    required VoidCallback onClicked,
    VoidCallback? onLongPress,
    bool showDot = false,
  }) =>
      _RailItem(
        key: key,
        icon: icon,
        selectedIcon: selectedIcon,
        title: title,
        isSelected: isSelected,
        onClicked: onClicked,
        onLongPress: onLongPress,
        showDot: showDot,
        compact: compact,
      );

  Widget _primaryDestinations(BuildContext context, MainState state) {
    void go(MainViews view, {VoidCallback? before}) {
      before?.call();
      if (state.mainView == view) {
        onScrollTop();
      }
      context.read<MainCubit>().updateIndex(view);
    }

    return Column(children: [
      _item(
        key: TourKeys.home,
        icon: FeatureIcons.home,
        selectedIcon: FeatureIcons.homeFilled,
        title: context.t.home.capitalizeFirst(),
        isSelected: state.mainView == MainViews.leading,
        onClicked: () => go(MainViews.leading),
      ),
      _item(
        key: TourKeys.media,
        icon: FeatureIcons.media,
        selectedIcon: FeatureIcons.mediaBold,
        title: context.t.media.capitalizeFirst(),
        isSelected: state.mainView == MainViews.media,
        onClicked: () => go(MainViews.media),
      ),
      BlocBuilder<DmsCubit, DmsState>(
        builder: (context, dmState) => _item(
          key: TourKeys.dms,
          icon: FeatureIcons.message,
          selectedIcon: FeatureIcons.messageFilled,
          title: context.t.privateMessages.capitalizeFirst(),
          isSelected: state.mainView == MainViews.dms,
          onLongPress: dmsCubit.markAllAsRead,
          showDot: canSign(),
          onClicked: () => go(MainViews.dms),
        ),
      ),
      BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, notiState) => _item(
          key: TourKeys.notifications,
          icon: FeatureIcons.notification,
          selectedIcon: FeatureIcons.notificationsFilled,
          title: context.t.notifications.capitalizeFirst(),
          isSelected: state.mainView == MainViews.notifications,
          showDot: !notiState.isRead && canSign(),
          onClicked: () => go(
            MainViews.notifications,
            before: notificationsCubit.markRead,
          ),
        ),
      ),
      _item(
        key: TourKeys.wallet,
        icon: FeatureIcons.wallet,
        selectedIcon: FeatureIcons.walletFilled,
        title: context.t.wallet.capitalizeFirst(),
        isSelected: state.mainView == MainViews.wallet,
        onClicked: () => go(
          MainViews.wallet,
          before: walletManagerCubit.requestBalance,
        ),
      ),
    ]);
  }

  Future<void> _openMore(BuildContext context, MainState state) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => DesktopMoreDialog(
        title: context.t.more.capitalizeFirst(),
        searchLabel: context.t.search.capitalizeFirst(),
        emptyLabel: context.t.noResults,
        entries: _moreDestinations(context, state),
      ),
    );
  }

  List<DesktopMoreEntry> _moreDestinations(
      BuildContext context, MainState state) {
    void go(MainViews view, {VoidCallback? before}) {
      before?.call();
      if (state.mainView == view) {
        onScrollTop();
      }
      context.read<MainCubit>().updateIndex(view);
    }

    final items = <_RailItem>[
      _item(
        icon: FeatureIcons.article,
        selectedIcon: FeatureIcons.articleFilled,
        title: context.t.articles.capitalizeFirst(),
        isSelected: state.mainView == MainViews.articles,
        onClicked: () => go(MainViews.articles),
      ),
      if (canSign())
        _item(
          icon: FeatureIcons.smartWidget,
          selectedIcon: FeatureIcons.smartWidget,
          title: context.t.smartWidget.capitalizeFirst(),
          isSelected: state.mainView == MainViews.smartWidgets,
          onClicked: () => YNavigator.pushPage(
            context,
            (_) => const DesktopSmartWidgetsPage(),
          ),
        ),
      _item(
        icon: FeatureIcons.discover,
        selectedIcon: FeatureIcons.discoverFilled,
        title: context.t.explore.capitalizeFirst(),
        isSelected: false,
        onClicked: () => YNavigator.pushPage(
          context,
          (context) => const ExplorePacksView(),
        ),
      ),
      _item(
        icon: FeatureIcons.relaysOrbit,
        selectedIcon: FeatureIcons.relaysOrbit,
        title: context.t.relayOrbits.capitalizeFirst(),
        isSelected: false,
        onClicked: () => YNavigator.pushPage(
          context,
          (context) => const ExploreRelaysView(),
        ),
      ),
      if (canSign()) ...[
        _item(
          icon: FeatureIcons.user,
          selectedIcon: FeatureIcons.user,
          title: context.t.profile.capitalizeFirst(),
          isSelected: false,
          onClicked: () => YNavigator.pushPage(
            context,
            (context) => ProfileView(pubkey: state.pubKey),
          ),
        ),
        _item(
          icon: FeatureIcons.dashboard2,
          selectedIcon: FeatureIcons.dashboard2,
          title: context.t.dashboard.capitalizeFirst(),
          isSelected: false,
          onClicked: () => YNavigator.pushPage(
            context,
            (context) => DashboardView(),
          ),
        ),
        _item(
          icon: FeatureIcons.walletAvailable,
          selectedIcon: FeatureIcons.walletAvailable,
          title: context.t.subscription.capitalizeFirst(),
          isSelected: false,
          onClicked: () => YNavigator.pushPage(
            context,
            (context) => const SubscriptionView(),
          ),
        ),
        _item(
          icon: LucideIcons.crown,
          selectedIcon: LucideIcons.crown,
          title: context.t.creatorsSubscriptions.capitalizeFirst(),
          isSelected: false,
          onClicked: () => YNavigator.pushPage(
            context,
            (context) => const CreatorsSubscriptionsView(),
          ),
        ),
        _item(
          icon: FeatureIcons.sats,
          selectedIcon: FeatureIcons.sats,
          title: context.t.pricing.capitalizeFirst(),
          isSelected: false,
          onClicked: () => YNavigator.pushPage(
            context,
            (context) => const PricingScreen(),
          ),
        ),
        _item(
          icon: FeatureIcons.storageCloud,
          selectedIcon: FeatureIcons.storageCloud,
          title: context.t.blossomStorage.capitalizeFirst(),
          isSelected: false,
          onClicked: () => YNavigator.pushPage(
            context,
            (context) => const BlossomManagementView(),
          ),
        ),
        _item(
          icon: FeatureIcons.favorite,
          selectedIcon: FeatureIcons.favorite,
          title: context.t.yakiPoints,
          isSelected: false,
          onClicked: () {
            if (pointsManagementCubit.state.isSystemLoggedIn) {
              YNavigator.pushNamed(context, PointsStatisticsView.routeName);
            } else {
              showBlurredModal(
                  context: context, view: const PointsLoginPopup());
            }
          },
        ),
        _item(
          icon: LucideIcons.badgeCheck,
          selectedIcon: LucideIcons.badgeCheck,
          title: context.t.yakiPro,
          isSelected: false,
          onClicked: () => openWebPage(
            url: 'https://pro.yakihonne.com/yakipro-mobile-app-links',
            openInternal: false,
          ),
        ),
      ],
    ];
    return items
        .map((item) => DesktopMoreEntry(
              label: item.title,
              icon: item.isSelected ? item.selectedIcon : item.icon,
              selected: item.isSelected,
              group: item.icon == FeatureIcons.article ||
                      item.icon == FeatureIcons.smartWidget
                  ? context.t.content
                  : item.icon == FeatureIcons.discover ||
                          item.icon == FeatureIcons.relaysOrbit
                      ? context.t.explore.capitalizeFirst()
                      : item.icon == FeatureIcons.user ||
                              item.icon == FeatureIcons.dashboard2 ||
                              item.icon == FeatureIcons.walletAvailable ||
                              item.icon == LucideIcons.crown ||
                              item.icon == FeatureIcons.sats
                          ? context.t.profile.capitalizeFirst()
                          : context.t.tools,
              onPressed: item.onClicked,
            ))
        .toList();
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: compact ? 0 : kDefaultPadding / 2,
        top: kDefaultPadding / 2,
      ),
      child: Align(
        alignment: compact ? Alignment.center : Alignment.centerLeft,
        child: SvgPicture.asset(
          compact ? LogosIcons.logoMark : LogosIcons.logo,
          height: 24,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Hoverable(
      builder: (context, _) => Tooltip(
        message: compact ? context.t.search.capitalizeFirst() : '',
        child: DesktopRailAction(
          label: context.t.search.capitalizeFirst(),
          onPressed: () =>
              YNavigator.pushPage(context, (context) => SearchView()),
          child: _CenterIfCompact(
            compact: compact,
            child: Container(
              height: compact ? 44 : 40,
              width: compact ? 44 : null,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : kDefaultPadding / 1.5,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.55),
                shape: compact ? BoxShape.circle : BoxShape.rectangle,
                borderRadius:
                    compact ? null : BorderRadius.circular(kDefaultPadding),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                spacing: kDefaultPadding / 2,
                children: [
                  AppIcon(
                    FeatureIcons.search,
                    size: 16,
                    color: Theme.of(context).highlightColor,
                  ),
                  if (!compact)
                    Expanded(
                      child: Text(
                        context.t.search.capitalizeFirst(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).highlightColor,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compose. The phone build opens a bubble anchored above the bottom bar; from
/// the rail that geometry does not apply, so desktop uses an anchored menu —
/// the native affordance here anyway.
class DesktopComposeButton extends StatefulWidget {
  const DesktopComposeButton({super.key, required this.compact});

  final bool compact;

  @override
  State<DesktopComposeButton> createState() => _DesktopComposeButtonState();
}

class _DesktopComposeButtonState extends State<DesktopComposeButton> {
  final _menu = GlassMenuController();
  final _triggerFocus = FocusNode();
  var _navigating = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  bool _handleKey(KeyEvent event) {
    if (_menu.isOpen &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _menu.close();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _triggerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = <(IconData, String, String, Widget Function())>[
      (
        FeatureIcons.note,
        context.t.note.capitalizeFirst(),
        context.t.quickPost,
        () => AddContentView(contentType: AppContentType.note)
      ),
      (
        FeatureIcons.article,
        context.t.article.capitalizeFirst(),
        context.t.longForm,
        () => AddContentView(contentType: AppContentType.article)
      ),
      (
        FeatureIcons.media,
        context.t.media.capitalizeFirst(),
        context.t.photoOrClip,
        () => AddMediaView()
      ),
      (
        FeatureIcons.smartWidget,
        context.t.widgets.capitalizeFirst(),
        context.t.smartEmbed,
        () => AddContentView(contentType: AppContentType.smartWidget)
      ),
    ];

    return GlassMenu(
      controller: _menu,
      settings: GlassSettings.menu(context),
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(kDefaultPadding / 2),
      menuWidth: 260,
      // A bounded, scrollable menu keeps all choices available in short windows
      // and enables the package's keyboard activation path.
      menuHeight: 200,
      onClose: () {
        if (!_navigating && mounted) {
          _triggerFocus.requestFocus();
        }
      },
      triggerBuilder: (context, toggleMenu) {
        void open() => doIfCanSign(func: toggleMenu, context: context);
        if (widget.compact) {
          return Tooltip(
            message: context.t.compose.capitalizeFirst(),
            child: Center(
              child: SizedBox(
                height: kDesktopCompactFooterSize,
                width: kDesktopCompactFooterSize,
                child: TextButton(
                  key: TourKeys.create,
                  focusNode: _triggerFocus,
                  onPressed: open,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: Semantics(
                    label: context.t.compose.capitalizeFirst(),
                    child: const AppIcon(FeatureIcons.addRaw,
                        size: 20, color: kWhite),
                  ),
                ),
              ),
            ),
          );
        }
        return SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: TextButton.icon(
              key: TourKeys.create,
              focusNode: _triggerFocus,
              onPressed: open,
              icon: const AppIcon(FeatureIcons.addRaw, size: 18, color: kWhite),
              label: Text(
                context.t.compose.capitalizeFirst(),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
      items: entries
          .map((entry) => GlassMenuItem(
                title: entry.$2,
                subtitle: entry.$3,
                height: 60,
                icon: AppIcon(entry.$1,
                    size: 22, color: Theme.of(context).primaryColorDark),
                titleStyle: Theme.of(context).textTheme.labelLarge,
                subtitleStyle:
                    Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                onTap: () {
                  _navigating = true;
                  _menu.close();
                  YNavigator.pushPage(context, (_) => entry.$4());
                  _navigating = false;
                },
              ))
          .toList(),
    );
  }
}

/// Fixed footer action with a centered icon in compact mode.
class DesktopSettingsButton extends StatelessWidget {
  const DesktopSettingsButton({
    super.key,
    required this.compact,
    required this.label,
    required this.onPressed,
  });

  final bool compact;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon =
        AppIcon(FeatureIcons.settings, size: 22, color: theme.primaryColorDark);
    return _CenterIfCompact(
      compact: compact,
      child: Tooltip(
        message: compact ? label : '',
        child: DesktopRailAction(
          label: label,
          onPressed: onPressed,
          child: Container(
            key: const ValueKey('desktop-settings-surface'),
            width: compact ? kDesktopCompactFooterSize : double.infinity,
            height: kDesktopCompactFooterSize,
            padding: compact
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.55),
              border: Border.all(color: theme.dividerColor, width: 0.5),
              shape: compact ? BoxShape.circle : BoxShape.rectangle,
              borderRadius:
                  compact ? null : BorderRadius.circular(kDefaultPadding),
            ),
            child: compact
                ? Center(child: icon)
                : Row(
                    children: [
                      icon,
                      const SizedBox(width: kDefaultPadding / 1.5),
                      Expanded(
                          child: Text(label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _AccountFooter extends StatelessWidget {
  const _AccountFooter({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (currentSigner == null) {
      void login() => YNavigator.push(
            context,
            OpacityAnimationPageRoute(
              builder: (context) => LogifyView(),
              settings: const RouteSettings(),
            ),
          );

      return Tooltip(
        message: compact ? context.t.login.capitalizeFirst() : '',
        child: compact
            ? Center(
                child: SizedBox(
                  height: kDesktopCompactFooterSize,
                  width: kDesktopCompactFooterSize,
                  child: TextButton(
                    onPressed: login,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: const AppIcon(
                      FeatureIcons.log,
                      size: 20,
                      color: kWhite,
                    ),
                  ),
                ),
              )
            : SizedBox(
                height: 42,
                child: TextButton.icon(
                  onPressed: login,
                  icon:
                      const AppIcon(FeatureIcons.log, size: 18, color: kWhite),
                  label: Text(context.t.login.capitalizeFirst()),
                ),
              ),
      );
    }

    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        void openAccounts() => showAdaptiveModal(
              context,
              dialogHeight: 560,
              builder: (_) => BlocProvider.value(
                value: context.read<MainCubit>(),
                child: AccountManager(scaffoldContext: context),
              ),
            );

        return _Hoverable(
          key: TourKeys.drawer,
          builder: (context, _) => _CenterIfCompact(
            compact: compact,
            child: DesktopAccountButton(
              compact: compact,
              label: context.t.switchAccounts.capitalizeFirst(),
              onPressed: openAccounts,
              child: Container(
                padding: EdgeInsets.all(
                  compact ? 0 : kDefaultPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: kTransparent,
                  shape: compact ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius:
                      compact ? null : BorderRadius.circular(kDefaultPadding),
                ),
                child: MetadataProvider(
                  pubkey: state.pubKey,
                  child: (metadata, isNip05) => Tooltip(
                    message: compact ? metadata.getName() : '',
                    child: Row(
                      mainAxisSize:
                          compact ? MainAxisSize.min : MainAxisSize.max,
                      spacing: kDefaultPadding / 2,
                      children: [
                        DesktopAccountAvatar(
                          size: compact ? kDesktopCompactFooterSize : 36,
                          image: metadata.picture,
                          pubkey: metadata.pubkey,
                          onPressed: openAccounts,
                        ),
                        if (!compact) ...[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  metadata.getName(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                Nip05Component(
                                  metadata: metadata,
                                  removeSpace: true,
                                ),
                              ],
                            ),
                          ),
                          AppIcon(
                            FeatureIcons.repost,
                            size: 18,
                            color: Theme.of(context).highlightColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A single keyboard and semantic action for the signed-in account footer.
class DesktopAccountButton extends StatelessWidget {
  const DesktopAccountButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
    this.compact = false,
  });

  final bool compact;
  final String label;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => DesktopRailAction(
        label: label,
        onPressed: onPressed,
        child: compact
            ? SizedBox.square(
                dimension: kDesktopCompactFooterSize,
                child: Center(child: child),
              )
            : child,
      );
}

/// The avatar shares the footer action rather than intercepting its tap.
class DesktopAccountAvatar extends StatelessWidget {
  const DesktopAccountAvatar({
    super.key,
    required this.image,
    required this.pubkey,
    required this.onPressed,
    this.size = 36,
  });

  final double size;
  final String image;
  final String pubkey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ProfilePicture2(
        size: size,
        image: image,
        pubkey: pubkey,
        padding: 0,
        strokeWidth: 0,
        strokeColor: kTransparent,
        onClicked: onPressed,
      );
}

/// A rail destination: rounded highlight when selected, softer one on hover.
class _RailItem extends StatelessWidget {
  const _RailItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.isSelected,
    required this.onClicked,
    required this.compact,
    this.onLongPress,
    this.showDot = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final bool isSelected;
  final VoidCallback onClicked;
  final VoidCallback? onLongPress;
  final bool showDot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
      ),
    );

    final iconWidget = AppIcon(
      isSelected ? selectedIcon : icon,
      size: 22,
      color: Theme.of(context).primaryColorDark,
    );

    return _Hoverable(
      builder: (context, _) => Tooltip(
        message: compact ? title : '',
        child: DesktopRailAction(
          label: title,
          selected: isSelected,
          onPressed: onClicked,
          onLongPress: onLongPress,
          child: _CenterIfCompact(
            compact: compact,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                bottom: compact ? kDefaultPadding / 4 : kDefaultPadding / 8,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : kDefaultPadding / 2,
                vertical: compact ? 0 : kDefaultPadding / 2.5,
              ),
              // Collapsed, the highlight is a circle around the icon rather than
              // a wide rounded bar with nothing in it.
              height: compact ? 44 : null,
              width: compact ? 44 : null,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).cardColor.withValues(alpha: 0.9)
                    : kTransparent,
                shape: compact ? BoxShape.circle : BoxShape.rectangle,
                borderRadius:
                    compact ? null : BorderRadius.circular(kDefaultPadding),
              ),
              child: compact
                  ? Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        iconWidget,
                        if (showDot) Positioned(top: 0, right: 0, child: dot),
                      ],
                    )
                  : Row(
                      spacing: kDefaultPadding / 1.5,
                      children: [
                        iconWidget,
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                          ),
                        ),
                        if (showDot) dot,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rail stretches its children to full width; collapsed, the round targets
/// need to sit centred in that width instead.
class _CenterIfCompact extends StatelessWidget {
  const _CenterIfCompact({required this.compact, required this.child});

  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) => compact ? Center(child: child) : child;
}

/// Supplies a pointer cursor without changing the control's appearance.
class _Hoverable extends StatelessWidget {
  const _Hoverable({super.key, required this.builder});

  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: builder(context, false),
    );
  }
}
