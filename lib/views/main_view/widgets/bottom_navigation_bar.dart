// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../logic/main_cubit/main_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/add_content_view.dart';
import '../../add_content_view/add_media_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/fluid_blur_container.dart';
import 'feature_tour.dart';

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
              _mediaButton(state, context),
              _walletButton(state, context),
              _dmsButton(state),
              _notificationsButton(state, context),
            ],
          ),
        );
      },
    );
  }

  Expanded _notificationsButton(MainState state, BuildContext context) {
    return Expanded(
      child: BottomNavBarItem(
        key: TourKeys.notifications,
        icon: FeatureIcons.notification,
        selectedIcon: FeatureIcons.notificationsFilled,
        isSelected: state.mainView == MainViews.notifications,
        onClicked: () {
          if (state.mainView == MainViews.notifications) {
            onClicked.call();
          }
          context.read<MainCubit>().updateIndex(MainViews.notifications);
          notificationsCubit.markRead();
          HapticFeedback.mediumImpact();
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

class FluidBottomNavigationBar extends StatefulWidget {
  const FluidBottomNavigationBar({
    super.key,
    required this.onClicked,
  });

  final VoidCallback onClicked;

  @override
  State<FluidBottomNavigationBar> createState() =>
      _FluidBottomNavigationBarState();
}

class _FluidBottomNavigationBarState extends State<FluidBottomNavigationBar> {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;

  void _openPicker(BuildContext context) {
    final box =
        TourKeys.create.currentContext!.findRenderObject()! as RenderBox;
    final buttonTopY = box.localToGlobal(Offset.zero).dy;
    final bottomOffset =
        MediaQuery.of(context).size.height - buttonTopY + kDefaultPadding / 1.5;

    setState(() => _isOpen = true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _PickerOverlay(
        parentContext: context,
        bottomOffset: bottomOffset,
        onDismissed: () {
          entry.remove();
          _overlayEntry = null;
          if (mounted) {
            setState(() => _isOpen = false);
          }
        },
      ),
    );
    _overlayEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        return FluidBlurContainer(
          sigma: 20,
          borderRadius: kDefaultPadding * 2,
          height: kBottomNavigationBarHeight + kDefaultPadding / 2,
          width: 90.w,
          padding: const EdgeInsets.all(kDefaultPadding / 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _homeButton(state, context),
              _mediaButton(state, context),
              _plusButton(context),
              _walletButton(state, context),
              _dmsButton(state),
            ],
          ),
        );
      },
    );
  }

  Widget _plusButton(BuildContext context) {
    return GestureDetector(
      key: TourKeys.create,
      onTap: () {
        HapticFeedback.mediumImpact();
        doIfCanSign(
          func: () => _openPicker(context),
          context: context,
        );
      },
      child: Container(
        width: kBottomNavigationBarHeight - kDefaultPadding / 2,
        height: kBottomNavigationBarHeight - kDefaultPadding / 2,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 100),
            child: const AppIcon(
              FeatureIcons.addRaw,
              size: 22,
              color: kWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dmsButton(MainState state) {
    return BlocBuilder<DmsCubit, DmsState>(
      builder: (context, dmState) {
        return Stack(
          children: [
            BottomNavBarItem(
              key: TourKeys.dms,
              icon: FeatureIcons.dms,
              selectedIcon: FeatureIcons.dms,
              isSelected: state.mainView == MainViews.dms,
              isGlass: true,
              onLongPress: dmsCubit.markAllAsRead,
              onClicked: () {
                context.read<MainCubit>().updateIndex(MainViews.dms);
                HapticFeedback.mediumImpact();
              },
            ),
            if (canSign())
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: kDefaultPadding * 2,
                    bottom: kDefaultPadding,
                  ),
                  child: FutureBuilder(
                    future: dmsCubit.gotMessages(),
                    builder: (context, snapshot) => DotContainer(
                      color: Theme.of(context).primaryColor,
                      isNotMarging: true,
                      size: snapshot.hasData && snapshot.data! ? 8 : 0,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _walletButton(MainState state, BuildContext context) {
    return BottomNavBarItem(
      key: TourKeys.wallet,
      icon: FeatureIcons.wallet,
      selectedIcon: FeatureIcons.wallet,
      isSelected: state.mainView == MainViews.wallet,
      isGlass: true,
      onClicked: () {
        walletManagerCubit.requestBalance();
        context.read<MainCubit>().updateIndex(MainViews.wallet);
        HapticFeedback.mediumImpact();
      },
    );
  }

  Widget _mediaButton(MainState state, BuildContext context) {
    return BottomNavBarItem(
      key: TourKeys.media,
      icon: FeatureIcons.camera,
      selectedIcon: FeatureIcons.camera,
      isSelected: state.mainView == MainViews.media,
      isGlass: true,
      onClicked: () {
        if (state.mainView == MainViews.media) {
          widget.onClicked.call();
        }
        context.read<MainCubit>().updateIndex(MainViews.media);
        HapticFeedback.mediumImpact();
      },
    );
  }

  Widget _homeButton(MainState state, BuildContext context) {
    return BottomNavBarItem(
      key: TourKeys.home,
      icon: FeatureIcons.home,
      selectedIcon: FeatureIcons.home,
      isSelected: state.mainView == MainViews.leading,
      isGlass: true,
      onClicked: () {
        if (state.mainView == MainViews.leading) {
          widget.onClicked.call();
        }
        context.read<MainCubit>().updateIndex(MainViews.leading);
        HapticFeedback.mediumImpact();
      },
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

// Full-screen overlay entry: dims the background and animates the bubble
// in from the + button's position with a bounce.
class _PickerOverlay extends StatefulWidget {
  const _PickerOverlay({
    required this.parentContext,
    required this.bottomOffset,
    required this.onDismissed,
  });

  final BuildContext parentContext;
  final double bottomOffset;
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
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
        ),
        Positioned(
          left: kDefaultPadding,
          right: kDefaultPadding,
          bottom: widget.bottomOffset,
          child: GestureDetector(
            // Prevent taps on the picker itself from dismissing.
            onTap: () {},
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                alignment: Alignment.bottomCenter,
                child: _ContentTypePicker(
                  parentContext: widget.parentContext,
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
    required this.onDismiss,
  });

  final BuildContext parentContext;
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
      clipper: const _BubbleClipper(
        radius: radius,
        vTipWidth: vTipWidth,
        vTipHeight: vTipHeight,
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
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kDefaultPadding / 2,
              kDefaultPadding,
              kDefaultPadding / 2,
              kDefaultPadding + vTipHeight,
            ),
            child: Row(
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

// Clips the widget into a rounded rect with a centered V-tip at the bottom.
class _BubbleClipper extends CustomClipper<Path> {
  const _BubbleClipper({
    required this.radius,
    required this.vTipWidth,
    required this.vTipHeight,
  });

  final double radius;
  final double vTipWidth;
  final double vTipHeight;

  @override
  Path getClip(Size size) => _buildPath(size, radius, vTipWidth, vTipHeight);

  @override
  bool shouldReclip(_BubbleClipper old) =>
      old.radius != radius ||
      old.vTipWidth != vTipWidth ||
      old.vTipHeight != vTipHeight;
}

// Fills and strokes the same bubble shape so the border matches the clip.
class _BubblePainter extends CustomPainter {
  const _BubblePainter({
    required this.fillColor,
    required this.borderColor,
    required this.radius,
    required this.vTipWidth,
    required this.vTipHeight,
  });

  final Color fillColor;
  final Color borderColor;
  final double radius;
  final double vTipWidth;
  final double vTipHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size, radius, vTipWidth, vTipHeight);

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
      old.vTipHeight != vTipHeight;
}

// Shared path: rounded rect with a centered downward V-tip at the bottom.
Path _buildPath(Size size, double radius, double vTipWidth, double vTipHeight) {
  final cx = size.width / 2;
  final bodyBottom = size.height - vTipHeight;

  return Path()
    ..moveTo(radius, 0)
    ..lineTo(size.width - radius, 0)
    ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius))
    ..lineTo(size.width, bodyBottom - radius)
    ..arcToPoint(Offset(size.width - radius, bodyBottom),
        radius: Radius.circular(radius))
    ..lineTo(cx + vTipWidth / 2, bodyBottom)
    ..lineTo(cx, size.height)
    ..lineTo(cx - vTipWidth / 2, bodyBottom)
    ..lineTo(radius, bodyBottom)
    ..arcToPoint(Offset(0, bodyBottom - radius),
        radius: Radius.circular(radius))
    ..lineTo(0, radius)
    ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
    ..close();
}
