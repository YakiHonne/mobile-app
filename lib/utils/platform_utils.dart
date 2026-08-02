import 'dart:io';

import 'package:flutter/widgets.dart';

/// Platform predicates for gating mobile-only features on desktop.
/// See md/DESKTOP_IMPLEMENTATION.md — the risk is `isIOS / else` branches
/// silently taking the Android path on desktop.
final bool isMobilePlatform = Platform.isAndroid || Platform.isIOS;
final bool isDesktopPlatform =
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

/// Height of the macOS titlebar strip the Flutter view now spans — see
/// `macos/Runner/MainFlutterWindow.swift`. `main.dart` adds it to the root
/// `MediaQuery` top padding, so every `SafeArea` and `AppBar` clears the traffic
/// lights while the strip itself stays painted by the app.
///
/// ponytail: a constant, not a live query — it is the standard titlebar height.
/// The one case where it is wrong is native fullscreen, where the lights hide
/// and this leaves a 28pt gap; fixing that needs an NSWindow delegate plus a
/// channel, so add it only if fullscreen becomes a normal way to use the app.
final double kMacTitlebarInset = Platform.isMacOS ? 28 : 0;

/// Columns for a feed masonry grid. Reads the *panel* width, not the window —
/// `MainView`'s desktop branch re-scopes `MediaQuery` to the content panel, so
/// this stays correct as the rail expands and collapses.
///
/// 2 is the floor, which is what every feed grid used before, so phones and
/// narrow windows are unchanged.
int feedGridColumns(BuildContext context) {
  // ponytail: a plain threshold, not a min-extent grid — masonry needs a fixed
  // count, and one breakpoint is cheaper than reworking the call sites.
  // 990 keeps each of the 3 cards at ~330pt, which is where they stop
  // wrapping badly. Measured, not guessed.
  return MediaQuery.of(context).size.width >= 990 ? 3 : 2;
}

/// Columns for the media (photo / video) quilted grid. Wider than
/// [feedGridColumns] on purpose — media tiles carry no text, so they tolerate
/// being small in a way a note card does not.
///
/// 3 is the floor, which is what the grid used before, so phones are unchanged.
/// The caller must feed the same value to both `crossAxisCount` and
/// [mediaGridLargeTileOffset] — see `MediaGrid`.
int mediaGridColumns(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width >= 1250) {
    return 5;
  }

  return width >= 900 ? 4 : 3;
}

/// Where the large (2×1) tile lands inside the *inverted* half of the media
/// grid's repeat pattern, for a grid of [columns] columns.
///
/// The pattern is one `(2, 1)` tile plus `2 * columns - 2` `(1, 1)` tiles, which
/// fills exactly two rows. `QuiltedGridRepeatPattern.inverted` re-emits that
/// block by central inversion, which the package implements as a reverse scan
/// collecting each tile's first appearance — so the second row's small tiles come
/// out first (`columns - 1` of them) and only then the large tile. Hence
/// `tileCount + columns - 1`, i.e. `3 * columns - 2`.
///
/// One full cycle is `2 * (2 * columns - 1)` tiles, and the large tiles sit at
/// offset `0` and this one. For 3 columns that is 10 and 7 — the hand-derived
/// constants this replaces.
int mediaGridLargeTileOffset(int columns) => 3 * columns - 2;

/// Tiles in one full (normal + inverted) repetition of the media grid pattern.
int mediaGridCycle(int columns) => 4 * columns - 2;
