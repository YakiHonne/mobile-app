# Desktop Implementation Guide

Reference for shipping YakiHonne to macOS, Windows and Linux. All findings are sourced from
the current tree (branch `nc013`) — resolved dependency versions come from `pubspec.lock`,
platform support from each plugin's declared `flutter.platforms` key, not from documentation.

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

## Notes

- No desktop build has been run against this tree. The matrix above is static analysis of
  declared plugin support; step 2 is what converts it into fact.
- `md/DESIGN_GUIDELINES.md` and `md/GLASS_IMPLEMENTATION.md` remain the authority on visual
  language. Glass mode uses `BackdropFilter`, which is GPU-cheap on desktop — no concerns
  there, but it has not been visually verified at desktop window sizes.
