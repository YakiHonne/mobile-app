import 'package:flutter/material.dart';

import '../../../routes/app_router.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../desktop/desktop_home_sidebar.dart';
import 'detail_pane_scope.dart';

/// Maximum width of the detail pane; at smaller widths the two panes share
/// the available space evenly.
const double kDetailPaneWidth = 520;

double desktopDetailPaneWidth(double panelWidth) =>
    ((panelWidth - 1) / 2).clamp(0.0, kDetailPaneWidth);

/// The pane's own navigator. It remains mounted when hidden so an unfinished
/// composer and the rest of its navigation stack survive layout changes.
final GlobalKey<NavigatorState> detailPaneNavigatorKey =
    GlobalKey<NavigatorState>();

class DetailPaneObserver extends NavigatorObserver {
  Route<dynamic>? currentRoute;
  String? accountPubkey;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) {
      accountPubkey = currentSigner?.getPublicKey();
    }
    currentRoute = route;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      currentRoute = previousRoute;

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (identical(currentRoute, route)) {
      currentRoute = previousRoute;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (identical(currentRoute, oldRoute)) {
      currentRoute = newRoute;
    }
  }
}

final detailPaneObserver = DetailPaneObserver();

/// Tracks the *root* navigator's stack so [YNavigator] can ask the only
/// question that actually matters: is the main panel the content underneath
/// this push?
///
/// `Navigator.canPop()` was the obvious test and it is wrong. A modal sheet
/// that pops itself and pushes in the same frame (every fast-access sheet does:
/// profile_fast_access.dart:127) is still in the navigator's history while its
/// exit animation runs, so `canPop` reports true and the push escapes the pane.
/// `didPop` fires at pop *start*, so this tracker has already forgotten it.
///
/// Walking to the topmost opaque route is what discriminates: sheets and
/// dialogs are non-opaque and drop out of the test for free, while a
/// full-screen `ArticleView` is opaque — so a push from a sheet opened inside
/// one correctly stays full-screen.
class DetailPaneRouteTracker extends NavigatorObserver {
  // ponytail: registered unconditionally. It is a list append per push on every
  // platform, and it is only ever *read* when a pane exists — gating it would
  // add a way to break the pane by forgetting the gate.
  static final List<Route<dynamic>> _stack = [];

  static bool get isMainPanelUnderneath {
    for (final route in _stack.reversed) {
      if (route is ModalRoute && route.opaque) {
        return route.isFirst;
      }
    }
    return false;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute == null || newRoute == null) {
      return;
    }

    final index = _stack.indexOf(oldRoute);
    if (index != -1) {
      _stack[index] = newRoute;
    }
  }
}

/// A persistent detail area beside the main content panel.
///
/// It is a real nested [Navigator], not a single-widget slot, so pushes that
/// originate *inside* the pane (note -> thread -> profile) stack and pop within
/// it. Its bottom route is the persistent workspace base, which matters for more than looks:
/// `YNavigator.pop` falls through to `SystemNavigator.pop()` when `canPop` is
/// false (navigator.dart:40-44), so an unseeded pane would quit the app the
/// first time a back chevron was pressed. Seeded, `canPop` is always true at
/// content level and back lands on the base — which is also the close
/// affordance, so no view needs an `onClose` parameter.
class DetailPane extends StatelessWidget {
  const DetailPane({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ponytail: the pane is opaque. Each pushed view keeps the real scaffold
    // colour so it fully occludes the view underneath it during the push
    // animation instead of blending with it; the ColoredBox is the base layer
    // for the empty state and any transient gap.
    final paneBackground = Color.alphaBlend(
      theme.colorScheme.onSurface.withValues(alpha: 0.035),
      theme.scaffoldBackgroundColor,
    );

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: paneBackground,
        appBarTheme: theme.appBarTheme.copyWith(
          scrolledUnderElevation: 0,
        ),
      ),
      child: ColoredBox(
        color: paneBackground,
        child: DetailPaneScope(
          child: Navigator(
            key: detailPaneNavigatorKey,
            observers: [detailPaneObserver],
            onGenerateRoute: (settings) {
              if (settings.name == Navigator.defaultRouteName) {
                return PageRouteBuilder(
                  settings: settings,
                  pageBuilder: (context, _, __) => const DesktopHomeSidebar(),
                );
              }

              // Same route table as the root navigator, so pane-internal
              // `pushNamed` resolves here with no extra wiring.
              return onGenerateRoute(settings);
            },
          ),
        ),
      ),
    );
  }
}
