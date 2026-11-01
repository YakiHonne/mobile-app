// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../logic/main_cubit/main_cubit.dart';
import '../../../logic/notifications_cubit/notifications_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../utils/theme/glass_settings.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/add_content_view.dart';
import '../../add_content_view/add_media_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons_containers_widgets.dart';
import 'feature_tour.dart';

const double kMaxBottomBarWidth = 480;

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxBottomBarWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _homeButton(state, context),
                  _mediaButton(state, context),
                  _walletButton(state, context),
                  _dmsButton(state),
                  _notificationsButton(state, context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Expanded _notificationsButton(MainState state, BuildContext context) {
    return Expanded(
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, notiState) {
          return Stack(
            children: [
              BottomNavBarItem(
                key: TourKeys.notifications,
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
              if (!notiState.isRead && canSign())
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: 15, bottom: 10),
                    child: DotContainer(
                      color: Colors.redAccent,
                      isNotMarging: true,
                      size: 8,
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
                key: TourKeys.dms,
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
        key: TourKeys.wallet,
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

  Expanded _mediaButton(MainState state, BuildContext context) {
    return Expanded(
      child: BottomNavBarItem(
        key: TourKeys.media,
        icon: FeatureIcons.media,
        selectedIcon: FeatureIcons.mediaBold,
        isSelected: state.mainView == MainViews.media,
        onClicked: () {
          if (state.mainView == MainViews.media) {
            onClicked.call();
          }
          context.read<MainCubit>().updateIndex(MainViews.media);
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }

  Expanded _homeButton(MainState state, BuildContext context) {
    return Expanded(
      child: BottomNavBarItem(
        key: TourKeys.home,
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

const kGlassNavCollapsedPillWidth = kBottomNavigationBarHeight;

class LiquidGlassBottomNavigationBar extends StatefulWidget {
  const LiquidGlassBottomNavigationBar({
    super.key,
    required this.onClicked,
    this.scrollController,
    this.isCollapsed,
  });

  final VoidCallback onClicked;

  final ScrollController? scrollController;

  final ValueNotifier<bool>? isCollapsed;

  @override
  State<LiquidGlassBottomNavigationBar> createState() =>
      _LiquidGlassBottomNavigationBarState();
}

class _LiquidGlassBottomNavigationBarState
    extends State<LiquidGlassBottomNavigationBar> {
  static const _views = [
    MainViews.leading,
    MainViews.media,
    MainViews.wallet,
    MainViews.dms,
  ];

  OverlayEntry? _overlayEntry;

  final GlobalKey _barKey = GlobalKey();

  bool _isMini = false;

  double? _lastScrollPixels;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebaseline());
  }

  void _rebaseline() {
    if (!mounted) {
      return;
    }

    final controller = widget.scrollController;
    if (controller != null && controller.positions.length == 1) {
      _lastScrollPixels = controller.position.pixels;
    }
  }

  @override
  void didUpdateWidget(LiquidGlassBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
      _lastScrollPixels = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _rebaseline());
    }
  }

  static const _scrollDeltaThreshold = 12.0;

  void _onScroll() {
    final controller = widget.scrollController;
    if (controller == null || controller.positions.length != 1) {
      return;
    }

    final position = controller.position;
    final pixels = position.pixels;
    final previous = _lastScrollPixels;
    _lastScrollPixels = pixels;

    if (previous == null || position.outOfRange) {
      return;
    }

    final delta = pixels - previous;
    if (delta >= _scrollDeltaThreshold) {
      _setMini(true);
    } else if (delta <= -_scrollDeltaThreshold) {
      _setMini(false);
    }
  }

  void _setMini(bool mini) {
    if (mini == _isMini || !mounted) {
      return;
    }
    setState(() => _isMini = mini);
    widget.isCollapsed?.value = mini;
  }

  void _openPicker(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const barHeight = kBottomNavigationBarHeight + kDefaultPadding / 2;
    final pillSize = _isMini ? kBottomNavigationBarHeight : barHeight;

    final barBox = _barKey.currentContext!.findRenderObject()! as RenderBox;
    final pillTopY = barBox.localToGlobal(Offset(0, barBox.size.height)).dy -
        kDefaultPadding -
        pillSize;
    final bottomOffset = size.height - pillTopY + kDefaultPadding / 2;

    final pillCenterX = barBox
        .localToGlobal(
            Offset(barBox.size.width - kDefaultPadding - pillSize / 2, 0))
        .dx;

    final barLeftX = barBox.localToGlobal(Offset.zero).dx;
    final bubbleLeft = barLeftX + kDefaultPadding;
    final bubbleRight =
        size.width - (barLeftX + barBox.size.width) + kDefaultPadding;
    final bubbleWidth = size.width - bubbleLeft - bubbleRight;
    final tipOffset = pillCenterX - (bubbleLeft + bubbleWidth / 2);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _PickerOverlay(
        parentContext: context,
        bottomOffset: bottomOffset,
        bubbleLeft: bubbleLeft,
        bubbleRight: bubbleRight,
        tipOffset: tipOffset,
        onDismissed: () {
          entry.remove();
          _overlayEntry = null;
        },
      ),
    );
    _overlayEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _overlayEntry?.remove();
    super.dispose();
  }

  Widget _dmsIcon() {
    const icon = AppIcon(FeatureIcons.dms);

    if (!canSign()) {
      return icon;
    }

    return BlocBuilder<DmsCubit, DmsState>(
      builder: (context, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          PositionedDirectional(
            top: -1,
            end: -1,
            child: FutureBuilder(
              future: dmsCubit.gotMessages(),
              builder: (context, snapshot) => DotContainer(
                color: Theme.of(context).primaryColor,
                isNotMarging: true,
                size: snapshot.data ?? false ? 7 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barsListenable = mainBarsVisible;

    if (barsListenable == null) {
      return _buildBody(context, forcedExpanded: false);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: barsListenable,
      builder: (context, barsVisible, _) =>
          _buildBody(context, forcedExpanded: barsVisible),
    );
  }

  Widget _buildBody(BuildContext context, {required bool forcedExpanded}) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        final index = _views.indexOf(state.mainView);
        final hasSelection = index >= 0;

        final selectedIndex = hasSelection ? index : 0;
        final tabs = [
          const GlassTab(icon: AppIcon(FeatureIcons.home)),
          const GlassTab(icon: AppIcon(FeatureIcons.camera)),
          const GlassTab(icon: AppIcon(FeatureIcons.wallet)),
          GlassTab(icon: _dmsIcon()),
        ];

        return GlassTabBar.searchable(
          key: _barKey,
          selectedIndex: selectedIndex,
          isSearchActive: _isMini && !forcedExpanded,
          barHeight: kBottomNavigationBarHeight + kDefaultPadding / 2,
          searchBarHeight: kBottomNavigationBarHeight,
          showIndicator: hasSelection,
          settings: GlassSettings.bottomBar(context),
          quality: themeCubit.state.glassQuality,
          iconSize: 25,
          onTabSelected: (i) {
            final view = _views[i];
            if (state.mainView == view) {
              widget.onClicked.call();
            }

            if (view == MainViews.wallet) {
              walletManagerCubit.requestBalance();
            }
            context.read<MainCubit>().updateIndex(view);
            HapticFeedback.mediumImpact();
            _setMini(false);
          },
          searchConfig: GlassSearchBarConfig(
            expandWhenActive: false,
            showsCancelButton: false,
            collapsedTabWidth: kBottomNavigationBarHeight,
            searchIcon: const AppIcon(FeatureIcons.addRaw, size: 25),
            onSearchToggle: (isComposeTap) {
              HapticFeedback.mediumImpact();
              if (isComposeTap) {
                doIfCanSign(
                  func: () => _openPicker(context),
                  context: context,
                );
                return;
              }
              _setMini(false);
            },
            collapsedLogoBuilder: (context) => Center(
              child: IconTheme.merge(
                data: IconThemeData(color: Theme.of(context).primaryColorDark),
                child: hasSelection
                    ? tabs[index].icon!
                    : const AppIcon(FeatureIcons.home),
              ),
            ),
          ),
          tabs: tabs,
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
    this.isGlass = false,
  });

  final Function() onClicked;
  final Function()? onLongPress;
  final bool isSelected;
  final bool isGlass;
  final IconData icon;
  final IconData selectedIcon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).primaryColorDark;

    final iconAsset = AppIcon(
      isSelected ? selectedIcon : icon,
      size: 25,
      color: iconColor,
    );

    if (isGlass) {
      return GestureDetector(
        onTap: onClicked,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.translucent,
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).cardColor.withValues(alpha: 0.85)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconAsset,
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 4 : 0,
                  height: isSelected ? 4 : 0,
                  margin: EdgeInsets.only(top: isSelected ? 3 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                  duration: const Duration(milliseconds: 200),
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

class _PickerOverlay extends StatefulWidget {
  const _PickerOverlay({
    required this.parentContext,
    required this.bottomOffset,
    required this.tipOffset,
    required this.onDismissed,
    this.bubbleLeft = kDefaultPadding,
    this.bubbleRight = kDefaultPadding,
  });

  final BuildContext parentContext;
  final double bottomOffset;

  final double bubbleLeft;
  final double bubbleRight;

  final double tipOffset;
  final VoidCallback onDismissed;

  @override
  State<_PickerOverlay> createState() => _PickerOverlayState();
}

class _PickerOverlayState extends State<_PickerOverlay>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 180),
  )..forward();

  late final _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  );
  late final _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.4, curve: Curves.easeOut),
    reverseCurve: Curves.easeIn,
  );

  void _dismiss() => _controller.reverse().whenComplete(widget.onDismissed);

  Alignment _growFrom(double bubbleWidth) {
    final x = bubbleWidth <= 0
        ? 0.0
        : (2 * widget.tipOffset / bubbleWidth).clamp(-1.0, 1.0);
    return Alignment(x, 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: (themeCubit.isDark ? kBlack : Colors.white)
                    .withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        Positioned(
          left: widget.bubbleLeft,
          right: widget.bubbleRight,
          bottom: widget.bottomOffset,
          child: GestureDetector(
            onTap: () {},
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                alignment: _growFrom(
                  MediaQuery.sizeOf(context).width -
                      widget.bubbleLeft -
                      widget.bubbleRight,
                ),
                child: _ContentTypePicker(
                  parentContext: widget.parentContext,
                  tipOffset: widget.tipOffset,
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContentTypePicker extends StatelessWidget {
  const _ContentTypePicker({
    required this.parentContext,
    required this.tipOffset,
    required this.onDismiss,
  });

  final BuildContext parentContext;
  final double tipOffset;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        FeatureIcons.note,
        context.t.note.capitalizeFirst(),
        context.t.quickPost,
        () {
          onDismiss();
          doIfCanSign(
            func: () => YNavigator.pushPage(
              parentContext,
              (_) => AddContentView(contentType: AppContentType.note),
            ),
            context: parentContext,
          );
        },
      ),
      (
        FeatureIcons.article,
        context.t.article.capitalizeFirst(),
        context.t.longForm,
        () {
          onDismiss();
          doIfCanSign(
            func: () => YNavigator.pushPage(
              parentContext,
              (_) => AddContentView(contentType: AppContentType.article),
            ),
            context: parentContext,
          );
        },
      ),
      (
        FeatureIcons.media,
        context.t.media.capitalizeFirst(),
        context.t.photoOrClip,
        () {
          onDismiss();
          doIfCanSign(
            func: () => YNavigator.pushPage(
              parentContext,
              (_) => AddMediaView(),
            ),
            context: parentContext,
          );
        },
      ),
      (
        FeatureIcons.smartWidget,
        context.t.widgets.capitalizeFirst(),
        context.t.smartEmbed,
        () {
          onDismiss();
          doIfCanSign(
            func: () => YNavigator.pushPage(
              parentContext,
              (_) => AddContentView(contentType: AppContentType.smartWidget),
            ),
            context: parentContext,
          );
        },
      ),
    ];

    const vTipWidth = 24.0;
    const vTipHeight = 10.0;
    const radius = kDefaultPadding * 1.5;

    return ClipPath(
      clipper: _BubbleClipper(
        radius: radius,
        vTipWidth: vTipWidth,
        vTipHeight: vTipHeight,
        tipOffset: tipOffset,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: CustomPaint(
          painter: _BubblePainter(
            fillColor: Theme.of(context)
                .scaffoldBackgroundColor
                .withValues(alpha: 0.55),
            borderColor: Theme.of(context).dividerColor,
            radius: radius,
            vTipWidth: vTipWidth,
            vTipHeight: vTipHeight,
            tipOffset: tipOffset,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kDefaultPadding / 2,
              kDefaultPadding,
              kDefaultPadding / 2,
              kDefaultPadding + vTipHeight,
            ),
            child: Row(
              spacing: kDefaultPadding / 4,
              children: items.map((item) {
                final (icon, title, subtitle, onTap) = item;
                return Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.translucent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: kDefaultPadding / 4,
                      children: [
                        AppIcon(
                          icon,
                          size: 25,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 8,
                        ),
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(fontWeight: FontWeight.w700, height: 1),
                        ),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: Theme.of(context).highlightColor,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleClipper extends CustomClipper<Path> {
  const _BubbleClipper({
    required this.radius,
    required this.vTipWidth,
    required this.vTipHeight,
    required this.tipOffset,
  });

  final double radius;
  final double vTipWidth;
  final double vTipHeight;
  final double tipOffset;

  @override
  Path getClip(Size size) =>
      _buildPath(size, radius, vTipWidth, vTipHeight, tipOffset);

  @override
  bool shouldReclip(_BubbleClipper old) =>
      old.radius != radius ||
      old.vTipWidth != vTipWidth ||
      old.vTipHeight != vTipHeight ||
      old.tipOffset != tipOffset;
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({
    required this.fillColor,
    required this.borderColor,
    required this.radius,
    required this.vTipWidth,
    required this.vTipHeight,
    required this.tipOffset,
  });

  final Color fillColor;
  final Color borderColor;
  final double radius;
  final double vTipWidth;
  final double vTipHeight;
  final double tipOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size, radius, vTipWidth, vTipHeight, tipOffset);

    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.fillColor != fillColor ||
      old.borderColor != borderColor ||
      old.radius != radius ||
      old.vTipWidth != vTipWidth ||
      old.vTipHeight != vTipHeight ||
      old.tipOffset != tipOffset;
}

Path _buildPath(Size size, double radius, double vTipWidth, double vTipHeight,
    double tipOffset) {
  final cx = size.width / 2 + tipOffset;
  final bodyBottom = size.height - vTipHeight;

  return Path()
    ..moveTo(radius, 0)
    ..lineTo(size.width - radius, 0)
    ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius))
    ..lineTo(size.width, bodyBottom - radius)
    ..arcToPoint(Offset(size.width - radius, bodyBottom),
        radius: Radius.circular(radius))
    ..lineTo(cx + vTipWidth / 2, bodyBottom)
    ..quadraticBezierTo(cx, bodyBottom, cx, size.height)
    ..quadraticBezierTo(cx, bodyBottom, cx - vTipWidth / 2, bodyBottom)
    ..lineTo(radius, bodyBottom)
    ..arcToPoint(Offset(0, bodyBottom - radius),
        radius: Radius.circular(radius))
    ..lineTo(0, radius)
    ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
    ..close();
}
