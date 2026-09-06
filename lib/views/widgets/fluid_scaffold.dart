import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../repositories/nostr_data_repository.dart';
import '../../utils/theme/glass_settings.dart';
import '../../utils/utils.dart';
import 'buttons_containers_widgets.dart';
import 'custom_app_bar.dart';

/// Top inset a [FluidScaffold] body needs so its first item clears the app bar.
///
/// `GlassScaffold` runs `extendBody: true` — that is the whole point, content
/// has to pass *behind* the bar for the fade to read — so the body starts at
/// y=0 and nothing is reserved. Add this to the **scroll view's own
/// `padding`**, never to a `Padding` around it: inside the scroll view the
/// first item clears the bar and later items still travel under it, which is
/// the effect; outside it, the whole list is pushed down and nothing ever
/// goes behind anything.
///
/// Returns 0 off the fluid path, so `padding + fluidScaffoldTopInset(context)`
/// is safe to write unconditionally.
double fluidScaffoldTopInset(BuildContext context) => isFluid()
    ? MediaQuery.paddingOf(context).top +
        _kGlassAppBarHeight +
        kDefaultPadding / 2
    : 0;

/// Height of the glass bottom nav bar's floating pill: the expanded
/// `barHeight` plus the package `verticalPadding` the pill floats above the
/// bar's bottom edge.
const double kGlassBottomBarHeight =
    kBottomNavigationBarHeight + kDefaultPadding / 2;

/// Bottom inset a floating element needs to clear the glass bottom nav bar,
/// measured from a Stack whose bottom edge reaches the screen's — a
/// `GlassScaffold` `body` (it runs `extendBody: true`) or `bodyOverlay`.
///
/// `GlassScaffold` wraps its bottom bar in `SafeArea(bottom: android)`, so on
/// Android the bar's pill sits `padding.bottom` above the screen's bottom edge
/// while body content does not; that offset is added back here, then the pill's
/// float ([kDefaultPadding]) and height ([kGlassBottomBarHeight]). [above]
/// adds extra clearance past the bar's top edge.
///
/// Returns 0 off the fluid path, so `bottom: X + fluidBottomBarInset(context)`
/// is safe to write unconditionally.
double fluidBottomBarInset(BuildContext context, {double above = 0}) =>
    isFluid()
        ? (defaultTargetPlatform == TargetPlatform.android
                ? MediaQuery.paddingOf(context).bottom
                : 0) +
            kDefaultPadding +
            kGlassBottomBarHeight +
            above
        : 0;

/// GlassAppBar.toolbarHeight's default. FluidScaffold never overrides it.
const double _kGlassAppBarHeight = 44.0;

/// How far past the bar the top fade reaches. `GlassScaffold` defaults to 20,
/// which lands the gradient's tail right on the bar's edge and reads as a hard
/// line; 44 pulls it a bar-height lower so content dissolves instead.
/// Gradient only — it does not move layout, so [fluidScaffoldTopInset] is
/// unaffected.
const double _kTopEdgeFadeExtent = 44.0;

/// Bottom bar for a [FluidScaffold]. A drop-in for `BottomAppBar`, which
/// cannot be used here: it calls `Scaffold.of` / `Scaffold.geometryOf` in
/// `didChangeDependencies`, and the fluid path's `GlassScaffold` is a
/// `CupertinoPageScaffold` with no `Scaffold` ancestor, so it throws.
///
/// Same nesting M3's BottomAppBar uses (colour → SafeArea → height → padding),
/// minus the FAB-notch geometry nothing here asks for. The `Material` also
/// gives the bar subtree the ancestor `FluidScaffold` only wraps `body` in.
///
/// [height] must match the `bottomBarHeight` passed to the scaffold — that is
/// what insets the body and sizes the bottom fade. The safe area sits *below*
/// it, added by both paths, so it is not part of [height].
class FluidBottomBar extends StatelessWidget {
  const FluidBottomBar({
    super.key,
    required this.child,
    this.height = 80,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.color,
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Pushed-view scaffold. Fluid mode gets a [GlassScaffold] with the body
/// scrolling behind a transparent [GlassAppBar]; every other theme gets
/// today's `Scaffold` + [CustomAppBar], unchanged.
///
/// The parameters are [CustomAppBar]'s plus a body, so converting a view is a
/// one-line rename — see GLASS_IMPLEMENTATION.md Phase 9.
///
/// **The glass does not come from [GlassAppBar].** That widget is a
/// transparent layout row (Phase 2). It comes from [GlassScaffold]: the body
/// extends behind the bar and `GlassScrollEdgeEffect` fades content out under
/// it. A `GlassAppBar` inside a plain `Scaffold` would look flat.
///
/// Note `GlassScaffold` also wraps the bar in
/// `GlassIsolationScope(defaultQuality: premium)`, but that hint never fires
/// here: it sits below the theme quality in the package's resolution order
/// (`glass_theme_helpers.dart:216`), and the app always sets one from the
/// user's Glass quality setting. Bars render at whatever the user picked.
class FluidScaffold extends StatelessWidget {
  const FluidScaffold({
    super.key,
    required this.body,
    this.title,
    this.description,
    this.actions,
    this.onBackClicked,
    this.onLogoClicked,
    this.notElevated,
    this.appBarColor,
    this.bottomBar,
    this.bottomBarHeight,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.titleWidget,
    this.leading,
  });

  final Widget body;
  final String? title;
  final String? description;
  final List<Widget>? actions;
  final Function()? onBackClicked;
  final Function()? onLogoClicked;
  final bool? notElevated;
  final Color? appBarColor;

  /// Maps to `Scaffold.bottomNavigationBar` / `GlassScaffold.bottomBar`.
  /// [bottomBarHeight] is only read on the fluid path, where the scaffold
  /// needs it to inset the body and size the bottom edge fade.
  final Widget? bottomBar;
  final double? bottomBarHeight;

  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;

  /// Normal path only. `GlassScaffold` always runs `extendBody: true`, so the
  /// fluid path already does this and ignores the flag. A view that sets it
  /// draws its own content behind the bar and should **not** also add
  /// [fluidScaffoldTopInset].
  final bool extendBodyBehindAppBar;

  /// Replaces the [title]/[description] column and takes the bar's full width
  /// — not centred, no leading gap — so a whole row (avatar, name, trailing
  /// button) can live in the title slot. Wins over [title] when both are
  /// given. Both paths honour it; see [CustomAppBar.titleWidget].
  final Widget? titleWidget;

  /// Replaces the default back chevron. `SizedBox.shrink()` gives a bar with
  /// no leading affordance, for screens that dismiss some other way.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    if (!isFluid()) {
      return Scaffold(
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: CustomAppBar(
          title: title,
          description: description,
          titleWidget: titleWidget,
          leading: leading,
          actions: actions,
          onBackClicked: onBackClicked,
          onLogoClicked: onLogoClicked,
          notElevated: notElevated,
          color: appBarColor,
        ),
        body: body,
        bottomNavigationBar: bottomBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
      );
    }

    return GlassScaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      // Sampling off: the edge fade then paints the scaffold colour directly
      // (fadeColor fallback) instead of a captured texture frozen at the old
      // theme, so it updates the moment the theme changes. Backgrounds here
      // are solid colours, where the two paths render identically.
      enableBackgroundSampling: false,
      bottomBar: bottomBar,
      bottomBarHeight: bottomBarHeight,
      topEdgeFadeExtent: _kTopEdgeFadeExtent,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: GlassAppBar(
        // GlassAppBar has no automaticallyImplyLeading — the back button is
        // ours to supply or the view loses it.
        buttonSettings: GlassSettings.innerAppBar(context),
        leading: leading ??
            AppIconButton(
              icon: LucideIcons.chevronLeft,
              onClicked: onBackClicked ?? () => Navigator.pop(context),
            ),
        // A title widget owns the full width, so it must not be centred.
        centerTitle: titleWidget == null,
        title: titleWidget ??
            (title != null || description != null ? _title(context) : null),

        actions: actions ?? [_logo(context)],
      ),
      // GlassScaffold is a CupertinoPageScaffold, so unlike Scaffold it
      // supplies no Material ancestor — InkWell, TextField, ListTile and
      // Tooltip all assert without one. Given unconditionally rather than
      // audited per view, same call as ModalSheetContainer in Phase 5.
      body: Material(
        type: MaterialType.transparency,
        child: body,
      ),
    );
  }

  Widget _title(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // The bar is transparent and content travels behind it, so the title has
    // to carry its own contrast. A halo in the scaffold colour knocks back
    // whatever is passing underneath without painting a bar background, which
    // would defeat the whole effect.
    final halo = [
      Shadow(
        blurRadius: 12,
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      Shadow(
        blurRadius: 4,
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(
            title!,
            style: textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
              shadows: halo,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (description != null)
          Text(
            description!,
            style: textTheme.labelSmall!.copyWith(
              color: Theme.of(context).highlightColor,
              shadows: halo,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  /// Mirrors CustomAppBar's default action: tap the logo, pop to the root and
  /// tell the home feed to reset.
  Widget _logo(BuildContext context) {
    return GlassIconButton(
      onPressed: onLogoClicked ??
          () {
            Navigator.popUntil(context, (route) => route.isFirst);
            context.read<NostrDataRepository>().homeViewController.add(true);
          },
      icon: SvgPicture.asset(
        LogosIcons.logoMarkPurple,
        height: kToolbarHeight / 2,
        fit: BoxFit.scaleDown,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
