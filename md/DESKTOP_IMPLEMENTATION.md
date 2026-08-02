# Desktop Implementation Guide

Reference for shipping YakiHonne to macOS, Windows and Linux. All findings are sourced from
the current tree (branch `nc013`) — resolved dependency versions come from `pubspec.lock`,
platform support from each plugin's declared `flutter.platforms` key, not from documentation.

**For what is done and what is left, jump to the [Implementation tracker](#implementation-tracker).**
Everything before it is the original analysis, which still holds.

---

## Verdict

**Ship macOS first. Windows second. Cut Linux from scope until macOS ships.**

The three targets are not equally viable and treating them as one project is the main risk.
macOS is close to working today. Linux has no webview, no video and no audio — three separate
rewrites, not a config change.

**The plugin work is the small half.** Dependencies, database and signing are largely already
solved (see below). The real project is **reconstructing the UI** — the app currently has no
concept of a window being too wide, and its navigation shell is built around a bottom bar and
a hamburger drawer that neither belong on desktop. Budget accordingly: see
[Design](#design).

| Target  | Status                     | Blocking work before first run              |
| ------- | -------------------------- | ------------------------------------------- |
| macOS   | Viable, close              | Debug entitlement fix (1 line)              |
| Windows | Viable minus media         | Replace video + audio stack                 |
| Linux   | Not viable yet             | Webview, video, audio all missing           |

---

## What is already done

Desktop folders are scaffolded **and committed** — 59 files tracked across `macos/`,
`windows/`, `linux/`. This is not a from-scratch port.

| Item                | State                                                          |
| ------------------- | -------------------------------------------------------------- |
| `macos/`            | Full Xcode project + CocoaPods (`Podfile.lock` present)         |
| `windows/`          | CMake runner, `BINARY_NAME` = `yakihonne`                       |
| `linux/`            | CMake + GTK runner, `APPLICATION_ID` = `com.yakihonne.yakihonne` |
| macOS deploy target | 10.15 (`macos/Podfile`, `MACOSX_DEPLOYMENT_TARGET`)             |

### The database is not a problem

The single item that could have blocked the whole port. `CLAUDE.md` describes the data layer
as "SharedPreferences + SQLite", which normally means mobile-only `sqflite`. It does not:
`nostr_core_enhanced` uses **`drift` 2.33.0 + `drift_flutter` 0.3.0**, which run natively on
all three desktops. `sqflite` 2.3.3+1 appears in `pubspec.lock` only as a transitive dep.

**No data-layer work is required.**

### Remote signing already exists

Desktop cannot use `amberflutter` (NIP-55 is Android-by-definition). The desktop path is
NIP-46 remote signer — and `nostr_core_enhanced` already implements it:

- `../nostr_core_enhanced/lib/nostr/event_signer/remote_event_signer.dart`
- referenced from `core/nostr_core_repository.dart` and `utils/static_properties.dart`

The biggest "we would have to build it" item is already built. Desktop login needs to surface
the existing NIP-46 path in the UI, not implement signing.

---

## Compatibility matrix

Resolved versions from `pubspec.lock`, platform support read from each package's
`flutter.platforms` declaration.

### Core infrastructure — all green

| Package                  | Version   | macOS | Windows | Linux |
| ------------------------ | --------- | ----- | ------- | ----- |
| `drift_flutter`          | 0.3.0     | ✅    | ✅      | ✅    |
| `shared_preferences`     | 2.5.3     | ✅    | ✅      | ✅    |
| `path_provider`          | 2.1.5     | ✅    | ✅      | ✅    |
| `connectivity_plus`      | 6.1.4     | ✅    | ✅      | ✅    |
| `device_info_plus`       | 11.5.0    | ✅    | ✅      | ✅    |
| `url_launcher`           | 6.3.2     | ✅    | ✅      | ✅    |
| `share_plus`             | 12.0.1    | ✅    | ✅      | ✅    |
| `flutter_secure_storage` | 10.0.0    | ✅    | ✅      | ✅ ¹  |
| `image_picker`           | 1.2.1     | ✅    | ✅      | ✅    |
| `emoji_picker_flutter`   | 4.3.0     | ✅    | ✅      | ✅    |
| `pasteboard`             | 0.4.0     | ✅    | ✅      | ✅    |

¹ Linux requires `libsecret-1-dev` installed at build time.

### Blockers

| Package                | Version | macOS | Windows | Linux | Impact                          |
| ---------------------- | ------- | ----- | ------- | ----- | ------------------------------- |
| `flutter_inappwebview` | 6.1.5   | ✅    | ✅      | ❌    | Pomegranate Google Sign-In      |
| `webview_flutter`      | 4.13.0  | ✅    | ❌      | ❌    | `app_view.dart` webview         |
| `video_player`         | 2.10.1  | ✅    | ❌      | ❌    | feed video, `chewie`            |
| `just_audio`           | 0.10.5  | ✅    | ❌      | ❌    | audio playback                  |
| `in_app_purchase`      | 3.3.0   | ✅    | ❌      | ❌    | subscriptions / points purchase |

`chewie` and `pull_to_refresh` declare no `platforms` key (pure-Dart wrappers) — they inherit
the limits of whatever they wrap, so `chewie` follows `video_player`.

### Mobile-only — feature-flag off, do not port

| Package                    | Platforms     | Desktop replacement                            |
| -------------------------- | ------------- | ---------------------------------------------- |
| `unifiedpush` 5.0.2        | Android only  | None needed — see note below                   |
| `share_handler`            | Android / iOS | Receive-share is a mobile concept; drop        |
| `qr_code_scanner`          | Android / iOS | Drop scanning; keep QR **display**             |
| `image_gallery_saver_plus` | Android / iOS | `flutter_file_saver` (macOS) / file dialog     |
| `video_thumbnail`          | Android / iOS | `fc_native_video_thumbnail` (macOS + Windows)  |
| `camera`                   | Android / iOS | Drop                                           |
| `sensors_plus`             | Android / iOS | Drop                                           |
| `open_filex` 4.7.0         | Android / iOS | `url_launcher` on a `file://` URI — already a dep |
| `amberflutter`             | Android only  | NIP-46 remote signer (already implemented)     |

**Push notifications**: `unifiedpush` is Android-only, but a desktop client holds live relay
websockets for as long as the window is open. Push is arguably *unnecessary* on desktop rather
than missing. `awesome_notifications` 0.10.1 declares all six platforms for local
notifications — treat that as **unverified** until it actually runs on each target.

---

## Per-target work

### macOS

**Blocker — debug entitlements.** `macos/Runner/Release.entitlements` correctly has
`com.apple.security.network.client`, so relay websockets work in release.
`macos/Runner/DebugProfile.entitlements` has `network.server` but is **missing
`network.client`**. Every relay connection fails in debug while release works — a confusing
afternoon if you do not know to look for it. Add:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

Everything else on macOS is green: webview, video, audio, secure storage, IAP.

`permission_handler` 12.0.1 declares no macOS support, but it is **not imported anywhere in
`lib/`** — it is a transitive dependency only. Not a blocker.

### Windows

No video, no audio. If media playback in the feed is core (it is), Windows needs
**`media_kit`** — real desktop support, replaces both `video_player` and `just_audio`.
Budget this as the main Windows work item.

`flutter_inappwebview` supports Windows, so the Pomegranate sign-in flow survives, but
`webview_flutter` (used in `app_view.dart`) does not — those call sites need to move to
`flutter_inappwebview` or be gated.

### Linux

Three independent holes: **no webview of any kind** (neither `webview_flutter` nor
`flutter_inappwebview` support Linux), no video, no audio. The missing webview kills the
Pomegranate Google Sign-In flow outright with no drop-in replacement.

Recommendation: do not target Linux until macOS has shipped and the media stack has been
replaced for Windows anyway.

---

## Platform guard audit

25 `Platform.is*` checks in `lib/` — 16 `isIOS`, 9 `isAndroid`, 1 `isMacOS`. The risk is not
the checks themselves but their **`else` branches**: code written as "iOS or else Android"
silently takes the Android path on desktop.

Sites that need review before first desktop run:

| Location                                                                        | Issue                                                        |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| [initializers.dart:231](../lib/initializers.dart#L231)                            | `Platform.isAndroid && Amberflutter().isAppInstalled()` — safe, short-circuits |
| [push_core.dart:23-28](../lib/common/notifications/push_core.dart#L23-L28)        | `if isIOS / else if isAndroid` — no-ops on desktop, safe     |
| [functions_set.dart:316](../lib/common/functions/functions_set.dart#L316)         | `if (!Platform.isIOS) return originalPath;` — safe           |
| [app_view.dart:298](../lib/views/app_view/app_view.dart#L298)                     | builds `system` string, empty on desktop — verify downstream |
| [umami_tracker.dart:37-45](../lib/common/tracker/umami_tracker.dart#L37-L45)      | analytics platform string — add desktop cases                |
| [subscription_section.dart](../lib/views/subscription_view/widgets/subscription_section.dart) | 5 sites, IAP-gated — must hide on Windows/Linux |
| [pricing_screen.dart](../lib/views/subscription_view/pricing/pricing_screen.dart) | 4 sites, same                                                |

Most existing guards happen to fail safe. The IAP-related ones do not and need explicit
desktop handling.

---

## Design

### Breakpoints already exist

[main.dart:23-29](../lib/main.dart#L23-L29) already defines the full desktop range:

```dart
Breakpoint(start: 0,    end: 719,               name: MOBILE),
Breakpoint(start: 720,  end: 1023,              name: TABLET),
Breakpoint(start: 1024, end: 1439,              name: DESKTOP),
Breakpoint(start: 1440, end: 1919,              name: 'DESKTOP_LARGE'),
Breakpoint(start: 1920, end: double.infinity,   name: '4K'),
```

74 files use `ResponsiveBreakpoints.of(context).largerThan(MOBILE)`. On desktop these all
resolve to the tablet branch — a **free, reasonable starting layout**. This is a positive
finding: the app will not look broken on first run, just under-used.

### The core problem: the app has no concept of "too wide"

**There are 5 `maxWidth` constraints in the entire `lib/` tree, and only one is a real layout
cap** (`feature_tour.dart:170`, `maxWidth: 340`). Every view is written to fill whatever width
it is handed. On a phone that is correct and invisible. On a 2560px monitor it means a feed
where each note stretches edge to edge, avatars sit 2000px from their own timestamps, and
line lengths run 4–5× past comfortable reading measure.

This is the single most important design finding in the document. It is not a bug in any one
view — it is a global assumption that width is scarce, and desktop inverts it. Compatibility
work makes the app *run* on desktop; this is what makes it *feel* like a desktop app.

The fix is not per-view. It is one constrained shell applied at the layout root, so every
existing view inherits a sane measure without being individually edited.

### Reconstructing the shell

The current shell is phone-shaped in a specific, load-bearing way:

| Element               | File                                            | Desktop problem                       |
| --------------------- | ----------------------------------------------- | ------------------------------------- |
| 6-tab bottom nav      | `widgets/bottom_navigation_bar.dart` (829 lines) | Bottom nav is a thumb affordance      |
| 10-item hamburger drawer | `widgets/drawer_view.dart` (813 lines)        | Hidden nav wastes permanent space     |
| Scroll-to-hide bars   | `main_view.dart:98-132` (`barsVisible`)          | Chrome should not move on desktop     |
| `IndexedStack` body   | `main_view.dart:160-195`                         | Single-column only, one view at a time |

**The target shape is a persistent left sidebar.** Desktop has permanent horizontal space;
using it for navigation removes both the bottom bar and the hamburger drawer at once. The
6 bottom-nav destinations and the 10 drawer items merge into one always-visible rail — which
is *fewer* total components than today, not more.

Critically, this does not touch the 7 views inside `IndexedStack`. `MainViews` (`enums.dart:20`)
and `MainCubit.updateIndex()` stay exactly as they are; only the widget that *renders* the
chosen destination changes. The state machine is already correct for desktop — it is the
chrome around it that is phone-shaped.

**Retire `barsVisible` on desktop.** The scroll-hide system exists to reclaim vertical pixels
on a phone. On desktop it makes the UI twitch while scrolling with a wheel. Gate it to mobile
rather than deleting it.

### Multi-column: where desktop width actually pays off

A constrained single column stops the app looking broken. Multi-column is what makes desktop
*better* than mobile rather than merely tolerable. The highest-value candidates, in order:

1. **DMs** (`dm_view/`) — conversation list + open thread side by side. This is the most
   obviously wrong view on desktop as a single column, and the most standard fix.
2. **Notes / threads** (`note_view/`, `threads_view/`) — feed on the left, selected note
   detail on the right, instead of a full-screen push.
3. **Notifications** (`notifications_view/`) — list + selected item detail.
4. **Feed + sidebar** (`leading_view/`, `discover_view/`) — trending / relays / suggestions
   in the right-hand gutter that a constrained centre column frees up.

These are genuine rebuilds, not responsive tweaks, and they are the reason to do the port at
all. Scope them individually and ship them after the shell lands — the constrained shell
already makes each of these views acceptable in the meantime.

### Navigation depth: 292 pushes

**292 `pushPage`/`Navigator.push` call sites across 67 files.** On mobile, drilling into a
note replaces the whole screen and back returns you. On desktop, full-screen push navigation
in a 2560px window is jarring — the standard pattern is a detail pane or a dialog, with the
list staying put.

Do not attempt to convert 292 sites. The realistic approach:

- Leave push navigation as the default everywhere; it is not *broken* on desktop, just
  unidiomatic.
- Convert only the 3–4 flows that become side-by-side panes (above). Those pushes become
  selection state instead.
- Everything else keeps pushing, and gets a constrained width so it does not sprawl.

### Bottom sheets: 91 direct call sites

92 files use bottom sheets, but only 2 funnel through `functions_set.dart` — the other **91
call `showModalBottomSheet` / `showCupertinoModalBottomSheet` directly**. A sheet sliding up
from the bottom edge of a large window is a phone gesture with no desktop meaning; the
equivalent is a centered dialog.

Lazy approach: add one wrapper that picks sheet-vs-dialog on width, then find-replace the 91
call sites to use it. Still touches 91 files, but the logic lives in one place and the
per-site edit is mechanical.

### `sizer`: 209 call sites

**106 files, 209 call sites (156 `.w`, 53 `.h`).** These are percentages of the *window*, not
the screen. On a 2560px window `40.w` is 1024px, and values recompute live while the user
drags the resize handle — so type and spacing visibly breathe during a resize.

Do **not** rewrite 209 call sites. The constrained shell above fixes most of this for free:
once the content column is capped, `.w` is computed against a bounded width and stops
tracking the monitor. Audit only the sites that sit *outside* the constrained column.

### Input model

The app assumes touch throughout. Desktop users expect:

- **Hover states** on every interactive element — custom `GestureDetector` areas built for
  touch give no feedback under a cursor.
- **Right-click context menus** where long-press is the current trigger.
- **Keyboard**: shortcuts for compose/search/navigation, focus traversal, Esc to close
  sheets and dialogs, Enter to send.
- **Scroll wheel** on custom scroll areas.
- **Text selection** — desktop users expect to select and copy note text with the mouse.
- **Pull-to-refresh is meaningless with a mouse** — `pull_to_refresh` is used throughout;
  every one of those needs a visible refresh affordance instead.

### Density

Mobile spacing is tuned for thumbs — `kDefaultPadding = 20` throughout (see
`md/DESIGN_GUIDELINES.md`). Desktop with a mouse tolerates and expects tighter density and
smaller hit targets. Consider a density multiplier applied at the theme level rather than
per-widget, so the existing derived spacing scale keeps working.

### Glass mode

`BackdropFilter` is GPU-cheap on desktop, so no performance concern. But glass mode's design
assumes floating chrome over a phone-sized surface (see `md/GLASS_IMPLEMENTATION.md`). A
persistent sidebar changes what "floating" means — glass on desktop needs its own visual pass,
not an automatic carry-over.

### Desktop UX items greps cannot surface

- **Window sizing** — minimum window size, and remembering geometry between launches.
- **Deep links** — `nostr:` scheme registration is per-platform. `app_links` 6.4.0 supports
  all three desktops, but needs an `Info.plist` `CFBundleURLTypes` entry on macOS, a registry
  entry on Windows, and a `.desktop` file on Linux.
- **Pull-to-refresh is meaningless with a mouse** — `pull_to_refresh` is used throughout;
  desktop needs an explicit refresh button/affordance.
- **Hover states** — custom gesture areas built for touch have no hover feedback.
- **Scroll wheel** — verify custom scroll areas and the MainView scroll-hide system respond to
  wheel events, not just drag gestures.
- **Keyboard** — shortcuts, focus traversal, Esc-to-close on sheets and dialogs.
- **Right-click** — context menus where long-press is currently the trigger.

---

## Packaging

| Target  | Requirements                                                     |
| ------- | ---------------------------------------------------------------- |
| macOS   | Developer ID signing + **notarization**; sandbox entitlements     |
| Windows | Code signing (unsigned binaries hit SmartScreen); MSIX for Store  |
| Linux   | `.deb` / Flatpak; `libsecret-1-dev` build dep for secure storage  |

---

## Suggested order

**Phase 1 — make it run (small, days)**

1. Fix `DebugProfile.entitlements` (1 line).
2. `flutter build macos --debug` — surfaces `MissingPluginException` risks that no amount of
   static analysis can reach. **Run this before planning anything further.**
3. Gate the mobile-only feature set behind platform checks.
4. Surface NIP-46 remote signer in the desktop login flow.
5. Window sizing, geometry persistence, deep links.

**Phase 2 — make it not look broken (the highest value-per-hour work)**

6. Constrained content shell with a max content width. This is the single change with the
   largest visual payoff and it also defuses most of the 209 `sizer` sites.
7. Persistent left sidebar; retire bottom nav + hamburger drawer on desktop. Gate
   `barsVisible` scroll-hide to mobile.
8. Bottom-sheet → dialog wrapper, then the 91 call sites.
9. Hover states, keyboard handling, right-click, explicit refresh affordances.

**Phase 3 — make it genuinely desktop (per-view rebuilds)**

10. Multi-column DMs, then notes/threads, then notifications, then feed sidebars.
11. Density pass; glass mode visual pass for the sidebar shell.

**Phase 4 — second platform**

12. Windows, starting with `media_kit` to replace `video_player` + `just_audio`.

Phases 1 and 2 are separable: phase 1 gets a running macOS build, phase 2 is what makes it
shippable. **Phase 2 and 3 together are the larger half of this project** — compatibility is
mostly already solved, the UI is not.

---

## Implementation tracker

Live state of the port, audited against the tree on 2026-07-30 (branch `DESKTOP`, everything
uncommitted). This section supersedes [Suggested order](#suggested-order) as the working list —
that one is the original plan, this is what actually happened.

`[x]` done and seen working — on screen, or covered by a test · `[c]` code complete, **never seen
running**: analyze and tests say nothing about it · `[~]` partially done, the rest named inline ·
`[ ]` not started.

Tree state behind this audit: `flutter analyze` clean; `flutter test` = 16 passing,
1 pre-existing failure (`test/widget_test.dart`, the stock counter smoke test, untouched since the
initial commit — it pumps the real app and always fails). Neither command proves a plugin exists
at runtime or that a layout ever rendered.

### Phase 1 — make it run (macOS)

- [x] `DebugProfile.entitlements` gets `network.client` (both entitlement files carry it now), so
      relays connect in debug.
- [x] macOS debug build runs. This is what turned the compatibility matrix above from static
      analysis into fact for macOS.
- [x] `lib/utils/platform_utils.dart` — `isMobilePlatform` / `isDesktopPlatform` are the single
      gate vocabulary. Every new gate uses them, not raw `Platform.is*`.
- [x] Window shape (`macos/Runner/MainFlutterWindow.swift`): `minSize` 720×600 (below 720 the
      layout falls into MOBILE), geometry persisted via AppKit's `setFrameAutosaveName` — no
      plugin — and a transparent full-size-content titlebar the app's own glass shows through,
      with `kMacTitlebarInset` keeping Dart content clear of the traffic lights.
- [x] `sizer` measures the right axis on desktop: `SizerUtil.setScreenSize(constraints,
      Orientation.portrait)` at main.dart:233. sizer swaps width/height in landscape, which is
      every normal desktop window — without this all 210 sites read the wrong axis and flipped
      when the window crossed square.
- [x] Umami user-agent has a macOS case (`umami_tracker.dart:37-49`). Windows and Linux still
      report `Unknown Device`.
- [~] Mobile-only feature gating. Done: camera init (`initializers.dart:162`), receive-share
      (`main_cubit.dart:195`), flip-to-share wrapper, the iOS-only path rewrite
      (`functions_set.dart:312`). **Left:** QR *scanner* entry points
      (`wallet_view/send_view/qr_code_scanner.dart`, `widgets/general_qr_code_scanner.dart`,
      `widgets/qr_scanner_modal.dart` — `qr_code_scanner` is Android/iOS, QR *display* is fine),
      `media_handler.dart` (`image_gallery_saver_plus`, `video_thumbnail`), `open_filex` call
      sites, and the unifiedpush surfaces in settings (the `Platform.isAndroid` guards in
      `push_core.dart` / `up_functions.dart` fail safe, but the UI still offers the feature).
- [ ] IAP platform strings are wrong on desktop, not just on Windows/Linux:
      `pricing_screen.dart:143` computes `Platform.isIOS ? 'ios' : 'android'` and
      `subscription_section.dart:211,974,980` render "Google Play" — on macOS, where
      `in_app_purchase` *does* work, the receipt platform and the store label are both wrong.
      Needs a macOS branch, not just a desktop hide.
- [c] Deep links. `Info.plist` registers `nostr`, `nostrwalletconnect` and `nostr+walletconnect`;
      `app_links` is wired in `MainCubit.initUniLinks` (`main_cubit.dart:226-253`) with no
      platform gate, so it should work as-is. Never exercised on macOS.
- [~] NIP-46 remote signer in the desktop login flow: `bunker://` / `nostrconnect://` paths exist
      in `signin_view.dart` and `fluid_logify_view.dart` already. Unverified on desktop, and
      unverified whether the Amber-only affordances are hidden there.
- [x] The 7-row [platform guard audit](#platform-guard-audit) above is walked. Resolved:
      `functions_set.dart:312` (now `!isDesktopPlatform`), `umami_tracker.dart` (macOS case).
      Confirmed fail-safe as written: `initializers.dart:234` (`Platform.isAndroid && …`
      short-circuits), `push_core.dart:23-28` (no-ops), and `app_view.dart:296-304`, which builds
      an empty `system` string on desktop and is guarded by `if (system.isNotEmpty)` — the JS
      injection is skipped, not misapplied. Still open: the two IAP files, tracked as their own
      item above.

### Phase 2 — the shell

- [x] `DesktopSidebar` (`main_view/widgets/desktop_sidebar.dart`, 779 lines) replaces the 6-tab
      bottom nav and the 10-item hamburger drawer at once: brand, search field, compose button,
      rail items, account footer. Collapses to icon-only below `kSidebarCollapseWidth` = 1080.
      Hover feedback via its own `_Hoverable`.
- [x] `barsVisible` scroll-hide gated off desktop (`main_view.dart:120`) — docked chrome has
      nothing to hide, and a wheel made it twitch.
- [x] Panel-scoped `MediaQuery` (`_PanelScope`): each column measures its own width, so
      `largerThan(MOBILE)` sites inside the feed stop reading the whole window. Feed and media
      grids pick their column count from the panel (`feedGridColumns`, `mediaGridColumns`).
- [~] Bottom sheets → dialogs. `showAdaptiveModal` (`functions_set.dart:297`) is the wrapper:
      byte-identical `showModalBottomSheet` on mobile, centered `Dialog` on desktop, with a
      focus-independent Escape handler and an `isCurrent` guard so nested sub-sheets pop one at a
      time. **101 call sites across 45 files converted; 84 raw
      `showModalBottomSheet` / `showCupertinoModalBottomSheet` calls remain.**
- [c] Escape-to-close on those dialogs has never been seen working — `cliclick` keystrokes do not
      reach the Flutter window, so only the user can confirm it.
- [ ] **No content max-width cap.** The original plan's centrepiece is still missing. Confirmed by
      grep across `leading_view`, `discover_view`, `media_view` and `main_view`: the only
      `maxWidth` in the whole panel path is `feature_tour.dart:170` (340pt, a tour card). The rail
      and the 520pt detail pane absorb width, but at 1920 the feed column is still ~1300pt and at
      2560 it is ~1900pt. Decide between a hard cap on the feed column and filling the surplus
      with a right-hand gutter (below) — one of the two, not neither.
- [~] `sizer`: axis is correct now, but **157 raw `.w` and 53 `.h`** still measure the *window*,
      not the panel — a re-scoped `MediaQuery` does not reach them. They need explicit gating
      site by site; the ones inside the detail pane and the DM columns are the visible offenders.
- [ ] Refresh affordance. 20 files drive `SmartRefresher` / `pull_to_refresh`; pull-to-refresh is
      meaningless with a wheel and not one of them has a desktop refresh button yet.
- [~] Hover states: the sidebar's own `_Hoverable`, plus whatever the ~10 files using `InkWell` /
      `MouseRegion` get for free. Feed cards, avatars, and the custom `GestureDetector` areas
      throughout give a cursor no feedback.
- [ ] Right-click context menus where long-press is the trigger today — exactly one
      `onSecondaryTap` in the tree (`widgets/custom_icon_buttons.dart`).
- [ ] Keyboard: no app-level shortcuts (compose, search, switch destination), no focus-traversal
      pass, no Enter-to-send audit. Escape is handled only inside `showAdaptiveModal`.
- [~] Text selection: 5 files use `SelectionArea` / `SelectableText` (article, curation, content
      renderer, raw event, smart widgets). Note bodies in the feed are still unselectable.
- [ ] Density pass — `kDefaultPadding = 20` is thumb-tuned. Wants a theme-level multiplier, not
      per-widget edits.
- [ ] Glass visual pass for the desktop chrome. The rail and panel are glass and *look* right, but
      `md/GLASS_IMPLEMENTATION.md` was written for floating phone chrome and has not been revised
      for a docked rail.

### Phase 3 — multi-column

- [x] **DMs**: conversation list beside the open thread (`dm_view.dart:115`), with the pane
      dropped and route-pushing restored below the threshold. Verified working on screen.
- [x] **Detail pane** (`main_view/widgets/detail_pane.dart`): nested `Navigator` seeded with the
      empty state, sharing the root `onGenerateRoute` so pane-internal pushes stack inside it.
      Mounts when the *panel* is ≥ 1024pt (window ≈ 1306px+), 520pt wide, not on DMs. One `Theme`
      override at the pane root keeps the five content views unedited. Allowlisted via
      `kDetailPaneRoutes` / `kDetailPanePages`; 47 call sites converted to `YNavigator.pushNamed`,
      `pushPage` intercepts its 36 for free. Verified working on screen.
- [c] Pane: pushed content no longer blends with the empty state. `_DetailPaneEmpty` returns
      `SizedBox.shrink()` when `ModalRoute.of(context)?.isCurrent` is false — the route stays
      seeded (an unseeded pane would quit the app, `navigator.dart:41-45`) and no opaque scaffold
      is introduced, which would have punched a hole through the glass. No test covers appearance.
- [x] Pane: pushes from a modal sheet reach the pane. The discriminator was
      `!Navigator.of(context).canPop()`, and a sheet that pops itself and pushes in the same frame
      (`profile_fast_access.dart:127`, every fast-access button) is still in `_history` — so the
      push escaped to full screen. Now `DetailPaneRouteTracker`, a `NavigatorObserver` mirroring
      the root stack, answers "is the main panel the content underneath?" by walking to the
      topmost `opaque` route and returning `route.isFirst`. Sheets and dialogs are non-opaque and
      drop out of the test; a full-screen route is opaque, so pushes from a sheet opened inside
      one stay full-screen. Covered by `test/detail_pane_route_tracker_test.dart` — the only check
      that fails if the discriminator loosens — but not yet seen on screen.
- [ ] **Notifications**: list + selected item detail. Not started.
- [ ] **Feed gutter**: trending / relays / suggestions in the space a capped centre column frees.
      Not started, and coupled to the max-width decision above.
- [ ] Pane stack is discarded when switching to DMs and back (accepted, documented).
- [ ] Threads: the pane covers note→thread→profile drilling, but `threads_view` itself has no
      desktop layout of its own.

### Phase 4 — Windows and Linux

Nothing started. Ordered by what blocks a first run:

- [ ] `media_kit` replacing `video_player` + `just_audio` (Windows and Linux both).
- [ ] `webview_flutter` call sites in `app_view.dart` → `flutter_inappwebview` or gated (Windows).
- [ ] Hide IAP entirely on Windows/Linux (see the Phase 1 item — same call sites).
- [ ] Deep-link registration: Windows registry entry, Linux `.desktop` file.
- [ ] Umami UA cases for Windows/Linux.
- [ ] Linux has no webview at all — Pomegranate Google Sign-In has no path there. Decide whether
      Linux ships without it or does not ship.
- [ ] Packaging: Developer ID signing + notarization (macOS), code signing + MSIX (Windows),
      `.deb`/Flatpak + `libsecret-1-dev` (Linux).

### Verification debt

- [ ] `test/` holds 6 files. Two are desktop-port work — `media_grid_pattern_test.dart` (grid
      pattern arithmetic) and `detail_pane_route_tracker_test.dart` (pane discriminator); three
      predate it (`dm_redeem_code`, `pomegranate_crypto`, `logic/`); one is the stock
      `widget_test.dart`, which fails and always has. The shell, the sidebar, the DM columns and
      `showAdaptiveModal` have no coverage at all.
- [ ] Delete or fix `test/widget_test.dart` — it makes `flutter test` red, which is how a real
      regression gets ignored.
- [ ] `MissingPluginException` sweep on macOS — nothing static can find these. Exercise, in this
      order: QR scan, save-media-to-gallery, video thumbnail, local notifications
      (`awesome_notifications`, still unverified on any desktop), IAP purchase, file open.
- [ ] Everything marked `[c]`, cumulative: Escape-to-close on dialogs, deep-link handling, both
      pane fixes above, and the glass appearance of the rail at 1440+ widths.
- [ ] Agent-side tooling limits worth knowing before planning verification: `cliclick`
      keystrokes do not reach the Flutter window (Escape and shortcuts are unverifiable without
      the user), `SIGUSR1` triggers hot reload, and the debug instance is not logged in.

---

## Notes

- The macOS debug build now runs, so the matrix is fact for macOS. Windows and Linux remain
  static analysis of declared plugin support.
- **[Implementation tracker](#implementation-tracker) is the live state of the port.** The
  phase list below the matrix is the original plan and is kept for its reasoning, not its status.
- `md/DESIGN_GUIDELINES.md` and `md/GLASS_IMPLEMENTATION.md` remain the authority on visual
  language. Glass mode uses `BackdropFilter`, which is GPU-cheap on desktop — no concerns
  there, but it has not been visually verified at desktop window sizes.
