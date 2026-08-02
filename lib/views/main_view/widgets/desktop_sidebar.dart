import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../logic/main_cubit/main_cubit.dart';
import '../../../logic/notifications_cubit/notifications_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../routes/pages_router.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/add_content_view.dart';
import '../../add_content_view/add_media_view.dart';
import '../../dashboard_view/dashboard_view.dart';
import '../../explore_packs_view/explore_packs_view.dart';
import '../../explore_relays_view/explore_relays_view.dart';
import '../../logify_view/logify_view.dart';
import '../../profile_view/profile_view.dart';
import '../../search_view/search_view.dart';
import '../../settings_view/settings_view.dart';
import '../../subscription_view/subscription_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/nip05_component.dart';
import '../../widgets/profile_picture.dart';
import 'accounts_manager.dart';
import 'feature_tour.dart';

/// Floating glass navigation rail for desktop. Replaces the bottom nav and the
/// hamburger drawer at once — desktop has permanent horizontal space, so both
/// sets of destinations live here, always visible.
const double kDesktopSidebarWidth = 268;

/// Below this window width the labelled rail starves the content column, so it
/// collapses to icons with tooltips.
const double kDesktopSidebarCompactWidth = 72;
const double kSidebarCollapseWidth = 1080;

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
          child: BlocBuilder<MainCubit, MainState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Brand(compact: compact),
                  const SizedBox(height: kDefaultPadding),
                  _SearchField(compact: compact),
                  const SizedBox(height: kDefaultPadding / 2),
                  Expanded(child: _destinations(context, state)),
                  const SizedBox(height: kDefaultPadding / 2),
                  _ComposeButton(compact: compact),
                  const SizedBox(height: kDefaultPadding / 2),
                  _AccountFooter(compact: compact),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Injects [compact] so each destination below stays a one-liner.
  Widget _item({
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

  Widget _destinations(BuildContext context, MainState state) {
    void go(MainViews view, {VoidCallback? before}) {
      before?.call();
      if (state.mainView == view) {
        onScrollTop();
      }
      context.read<MainCubit>().updateIndex(view);
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _item(
            icon: FeatureIcons.home,
            selectedIcon: FeatureIcons.homeFilled,
            title: context.t.home.capitalizeFirst(),
            isSelected: state.mainView == MainViews.leading,
            onClicked: () => go(MainViews.leading),
          ),
          _item(
            icon: FeatureIcons.media,
            selectedIcon: FeatureIcons.mediaBold,
            title: context.t.media.capitalizeFirst(),
            isSelected: state.mainView == MainViews.media,
            onClicked: () => go(MainViews.media),
          ),
          _item(
            icon: FeatureIcons.article,
            selectedIcon: FeatureIcons.articleFilled,
            title: context.t.articles.capitalizeFirst(),
            isSelected: state.mainView == MainViews.articles,
            onClicked: () => go(MainViews.articles),
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
          if (canSign())
            _item(
              icon: FeatureIcons.smartWidget,
              selectedIcon: FeatureIcons.smartWidget,
              title: context.t.smartWidget.capitalizeFirst(),
              isSelected: state.mainView == MainViews.smartWidgets,
              onClicked: () => go(MainViews.smartWidgets),
            ),
          const Divider(height: kDefaultPadding, indent: kDefaultPadding / 2),
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
          ],
          _item(
            icon: FeatureIcons.settings,
            selectedIcon: FeatureIcons.propertiesFilled,
            title: context.t.settings.capitalizeFirst(),
            isSelected: false,
            onClicked: () => YNavigator.pushPage(
              context,
              (context) => SettingsView(),
            ),
          ),
        ],
      ),
    );
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
  const _SearchField({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Hoverable(
      builder: (context, hovered) => Tooltip(
        message: compact ? context.t.search.capitalizeFirst() : '',
        child: GestureDetector(
          onTap: () => YNavigator.pushPage(context, (context) => SearchView()),
          child: _CenterIfCompact(
            compact: compact,
            child: Container(
              height: compact ? 44 : 40,
              width: compact ? 44 : null,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : kDefaultPadding / 1.5,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .cardColor
                    .withValues(alpha: hovered ? 0.85 : 0.55),
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
                    Text(
                      context.t.search.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).highlightColor,
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
class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    void open() => doIfCanSign(
          func: () => _openMenu(context),
          context: context,
        );

    if (compact) {
      return Tooltip(
        message: context.t.compose.capitalizeFirst(),
        child: Center(
          child: SizedBox(
            height: 44,
            width: 44,
            child: TextButton(
              key: TourKeys.create,
              onPressed: open,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child:
                  const AppIcon(FeatureIcons.addRaw, size: 20, color: kWhite),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: TextButton.icon(
        key: TourKeys.create,
        onPressed: open,
        icon: const AppIcon(FeatureIcons.addRaw, size: 18, color: kWhite),
        label: Text(context.t.compose.capitalizeFirst()),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);

    final entries = <(IconData, String, String, Widget Function())>[
      (
        FeatureIcons.note,
        context.t.note.capitalizeFirst(),
        context.t.quickPost,
        () => AddContentView(contentType: AppContentType.note),
      ),
      (
        FeatureIcons.article,
        context.t.article.capitalizeFirst(),
        context.t.longForm,
        () => AddContentView(contentType: AppContentType.article),
      ),
      (
        FeatureIcons.media,
        context.t.media.capitalizeFirst(),
        context.t.photoOrClip,
        () => AddMediaView(),
      ),
      (
        FeatureIcons.smartWidget,
        context.t.widgets.capitalizeFirst(),
        context.t.smartEmbed,
        () => AddContentView(contentType: AppContentType.smartWidget),
      ),
    ];

    final selected = await showMenu<Widget Function()>(
      context: context,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height + kDefaultPadding / 4,
        overlay.size.width - origin.dx - box.size.width,
        0,
      ),
      items: entries
          .map(
            (e) => PopupMenuItem<Widget Function()>(
              value: e.$4,
              child: Row(
                spacing: kDefaultPadding / 1.5,
                children: [
                  AppIcon(
                    e.$1,
                    size: 22,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.$2,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        e.$3,
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: Theme.of(context).highlightColor,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );

    if (selected != null && context.mounted) {
      YNavigator.pushPage(context, (_) => selected());
    }
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
                  height: 44,
                  width: 44,
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
        return _Hoverable(
          builder: (context, hovered) => _CenterIfCompact(
            compact: compact,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => showAdaptiveModal(
                context,
                dialogHeight: 560,
                builder: (_) => BlocProvider.value(
                  value: context.read<MainCubit>(),
                  child: AccountManager(scaffoldContext: context),
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(
                  compact ? kDefaultPadding / 4 : kDefaultPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: hovered
                      ? Theme.of(context).cardColor.withValues(alpha: 0.85)
                      : kTransparent,
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
                        ProfilePicture2(
                          size: 36,
                          image: metadata.picture,
                          pubkey: metadata.pubkey,
                          padding: 0,
                          strokeWidth: 0,
                          strokeColor: kTransparent,
                          onClicked: () {},
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
      builder: (context, hovered) => Tooltip(
        message: compact ? title : '',
        child: GestureDetector(
          onTap: onClicked,
          onLongPress: onLongPress,
          behavior: HitTestBehavior.translucent,
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
                    : hovered
                        ? Theme.of(context).cardColor.withValues(alpha: 0.5)
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

/// Hover state + pointer cursor. The app's custom gesture targets were built
/// for touch and give no feedback under a mouse.
class _Hoverable extends StatefulWidget {
  const _Hoverable({required this.builder});

  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered),
    );
  }
}
