import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:pull_down_button/pull_down_button.dart';

/// Signature used by [FluidPullDownButton] to build the trigger button.
///
/// Mirrors [PullDownMenuButtonBuilder] but hands the caller a [VoidCallback]
/// so the same builder can drive both the pull-down route and the
/// [GlassMenu] morph trigger.
typedef FluidPullDownMenuButtonBuilder = Widget Function(
  BuildContext context,
  VoidCallback showMenu,
);

/// A [PullDownButton] that renders a [GlassMenu] on the fluid path and the
/// standard pull-down menu everywhere else.
///
/// The trigger button and the [PullDownMenuEntry] list are built exactly as
/// with [PullDownButton], so swapping a call site is a rename. On the fluid
/// path the entries are translated to their glass equivalents
/// ([PullDownMenuItem] → [GlassMenuItem], [PullDownMenuTitle] →
/// [GlassMenuLabel], [PullDownMenuDivider] → [GlassMenuDivider],
/// [PullDownMenuActionsRow] → its items flattened).
class FluidPullDownButton extends StatelessWidget {
  const FluidPullDownButton({
    super.key,
    required this.itemBuilder,
    required this.buttonBuilder,
    this.onCanceled,
    this.animationBuilder = PullDownButton.defaultAnimationBuilder,
    this.routeTheme,
    this.menuWidth = 220,
    this.menuPadding,
  });

  /// Lazily builds the menu entries, same contract as [PullDownButton.itemBuilder].
  final PullDownMenuItemBuilder itemBuilder;

  /// Builds the trigger button. Receives a [VoidCallback] that opens the menu.
  final FluidPullDownMenuButtonBuilder buttonBuilder;

  /// Called when the menu is dismissed without selecting an item.
  final PullDownMenuCanceled? onCanceled;

  /// Custom animation for the trigger button when the pull-down menu opens.
  ///
  /// Only used off the fluid path — the [GlassMenu] morph is its own animation.
  final PullDownButtonAnimationBuilder? animationBuilder;

  /// Theme of the route used to display the pull-down menu.
  ///
  /// Only used off the fluid path.
  final PullDownMenuRouteTheme? routeTheme;

  /// Width of the expanded [GlassMenu] on the fluid path.
  final double menuWidth;

  /// Edge margin of the expanded [GlassMenu] on the fluid path.
  final EdgeInsets? menuPadding;

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      itemBuilder: itemBuilder,
      buttonBuilder: (context, showMenu) => buttonBuilder(context, showMenu),
      onCanceled: onCanceled,
      animationBuilder: animationBuilder,
      routeTheme: routeTheme,
    );

    // if (!isFluid()) {}

    // final glassItems = _toGlassItems(context, itemBuilder(context));

    // if (glassItems.isEmpty) {
    //   return buttonBuilder(context, () {});
    // }

    // return GlassMenu(
    //   menuWidth: menuWidth,
    //   menuPadding: menuPadding ?? const EdgeInsets.all(kDefaultPadding / 2),
    //   autoAdjustToScreen: true,
    //   settings: GlassSettings.menu(context),
    //   triggerBuilder: (context, toggleMenu) =>
    //       buttonBuilder(context, toggleMenu),
    //   items: glassItems,
    // );
  }

  // List<Widget> _toGlassItems(
  //   BuildContext context,
  //   List<PullDownMenuEntry> entries,
  // ) {
  //   return entries.expand((entry) {
  //     if (entry is PullDownMenuItem) {
  //       return [_toGlassMenuItem(context, entry)];
  //     }
  //     if (entry is PullDownMenuActionsRow) {
  //       return entry.items
  //           .map((item) => _toGlassMenuItem(context, item))
  //           .toList();
  //     }
  //     if (entry is PullDownMenuTitle) {
  //       return [
  //         GlassMenuLabel(
  //           style: entry.titleStyle,
  //           child: entry.title,
  //         ),
  //       ];
  //     }
  //     if (entry is PullDownMenuDivider) {
  //       return const [GlassMenuDivider()];
  //     }
  //     return const <Widget>[];
  //   }).toList();
  // }

  // GlassMenuItem _toGlassMenuItem(BuildContext context, PullDownMenuItem item) {
  //   final selected = item.selected ?? false;
  //   final titleStyle = item.itemTheme?.textStyle;
  //   final checkColor = titleStyle?.color ?? Theme.of(context).primaryColorDark;

  //   return GlassMenuItem(
  //     title: item.title,
  //     subtitle: item.subtitle,
  //     enabled: item.enabled && item.onTap != null,
  //     isSelected: selected,
  //     isDestructive: item.isDestructive,
  //     titleStyle: titleStyle,
  //     iconColor: item.iconColor,
  //     icon: item.iconWidget ??
  //         (item.icon != null
  //             ? Icon(item.icon, size: 20, color: item.iconColor)
  //             : null),
  //     trailing: selected
  //         ? Icon(LucideIcons.check, size: 16, color: checkColor)
  //         : null,
  //     onTap: item.onTap ?? () {},
  //   );
  // }
}
