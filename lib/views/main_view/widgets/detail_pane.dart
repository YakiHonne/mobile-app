import 'package:flutter/material.dart';

import '../../../routes/app_router.dart';
import '../../../utils/utils.dart';
import '../../widgets/empty_list.dart';

/// Panel width at or above which the detail pane is mounted. Reuses the
/// existing `DESKTOP` breakpoint start (main.dart:26) rather than inventing a
/// number — measured against the *panel*, not the window.
const double kDetailPaneMinPanelWidth = 1024;

/// ponytail: a chosen constant, not a derived one. 520 leaves >=504 for the
/// feed at the threshold, and both clear the ~500pt line where content cards
/// start cramping. Move it if it reads wrong.
const double kDetailPaneWidth = 520;

/// The named routes that open in the detail pane instead of over the whole
/// window. Opt-in on purpose: everything absent from this set — compose and
/// editor flows, video players, the gallery, settings, wallet, onboarding —
/// keeps its full-screen push.
const Set<String> kDetailPaneRoutes = {
  '/noteView',
  '/articleView',
  '/curationView',
  '/profileView',
  '/unFlashNewsDetails',
};

/// Widget type names that open in the pane when pushed via
/// [YNavigator.pushPage], which carries a builder rather than a route name.
/// `pushPage` already derives this string, so matching on it costs nothing.
const Set<String> kDetailPanePages = {
  'NoteView',
  'ArticleView',
  'CurationView',
  'ProfileView',
  'UnFlashNewsDetails',
};

/// The pane's own navigator. Non-null `currentState` is the single source of
/// truth for "a pane is mounted right now" — no parallel bool to keep in sync.
final GlobalKey<NavigatorState> detailPaneNavigatorKey =
    GlobalKey<NavigatorState>();

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
/// it. Its bottom route is the empty state, which matters for more than looks:
/// `YNavigator.pop` falls through to `SystemNavigator.pop()` when `canPop` is
/// false (navigator.dart:40-44), so an unseeded pane would quit the app the
/// first time a back chevron was pressed. Seeded, `canPop` is always true at
/// content level and back lands on the empty state — which is also the close
/// affordance, so no view needs an `onClose` parameter.
class DetailPane extends StatelessWidget {
  const DetailPane({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // One override for the whole pane instead of per-view opt-outs. The
    // scaffold and app bar themes are opaque in every variant, glass included,
    // so a nested Scaffold would otherwise punch a solid rectangle through
    // MainView's FluidBlurContainer. Doing it here keeps NoteView, ArticleView,
    // ProfileView, CurationView and UnFlashNewsDetails untouched.
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: kTransparent,
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: kTransparent,
          scrolledUnderElevation: 0,
        ),
      ),
      child: Navigator(
        key: detailPaneNavigatorKey,
        onGenerateRoute: (settings) {
          if (settings.name == Navigator.defaultRouteName) {
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, _, __) => const _DetailPaneEmpty(),
            );
          }

          // Same route table as the root navigator, so pane-internal
          // `pushNamed` resolves here with no extra wiring.
          return onGenerateRoute(settings);
        },
      ),
    );
  }
}

class _DetailPaneEmpty extends StatelessWidget {
  const _DetailPaneEmpty();

  @override
  Widget build(BuildContext context) {
    // Pane routes are deliberately transparent — the pane sits inside MainView's
    // FluidBlurContainer, and an opaque scaffold would punch a solid rectangle
    // through the glass. So the empty state gets out of the way instead of
    // getting covered: it stays on the stack (`YNavigator.pop` falls through to
    // `SystemNavigator.pop()` on an unseeded navigator and would quit the app)
    // but paints nothing while something is pushed above it. `isCurrent` comes
    // from `_ModalScopeStatus`, which notifies on change, so this rebuilds on
    // every push and pop for free.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
      return const SizedBox.shrink();
    }

    return Center(
      child: EmptyList(
        description: context.t.selectContentToView,
        icon: FeatureIcons.note,
      ),
    );
  }
}
