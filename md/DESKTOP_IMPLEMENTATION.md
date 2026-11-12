## 2026-11-11 — user shell and account checks

The user reports successful navigation and return, DM switching, draft and
same-account refresh, side-pane recovery, and compose/settings checks. During
account switching an open note draft stayed in the editor; closing and reopening
the editor cleared it, which the user considers correct. The user confirmed the
open draft remains visible while the second account is active; an open draft is
therefore not isolated across accounts. The active signing identity and other
account-scoped data were not explicitly verified. Exact routes and offline
scenarios were not enumerated.

## 2026-11-11 — user desktop verification and divider highlight

The user reported that pane dragging and reset, window behavior, VoiceOver,
appearance and language checks, and media checks worked. The exact build,
display configuration and individual theme/language cases were not specified;
this is user-reported verification rather than a complete recorded test matrix.
At their request, the divider's visible focus highlight was removed. Keyboard
resizing and semantics remain available, but keyboard focus on the divider no
longer has a visible indicator. The user subsequently confirmed that the
highlight is gone in the native app.

## 2026-11-11 — isolated current-code pane and media checks

A separate macOS debug fixture was built from a copy of the current source,
with a distinct bundle identifier and preferences and the production
`MainFlutterWindow` implementation. It used synthetic notes and an asset image,
the actual divider, interest cards and hidden-video placeholder. At a
1440-point-wide window, keyboard resizing reached both 400-point pane limits;
the interest cards remained laid out with 1.5× text and RTL direction. A
fullscreen round trip returned to the window. Home reset the side pane to 520
points. The fixture used generic light/dark themes and English labels, not the
actual feed, full sidebar, app theme variants, video player or live data.
Automated pointer dragging again produced no visible resize. VoiceOver, the
native minimum-window resize and restoration of an old frame, physical display
changes, actual translated native screens and real playback remain unverified.

A 320×180 widget fixture found that the desktop hidden-video placeholder
overflowed at 1.5× text. It now scrolls when necessary. English, French and
Arabic fixtures exercise the label at that size across all eight app themes,
including scrolling to the final label and checking icon-to-card contrast.
This is a focused widget check, not a complete theme or contrast audit. The
`desktop*_test.dart` selection passed 148 tests after the fix; full Flutter
analysis passed, and the isolated debug build succeeded with plugin warnings.
No signed-in account, live relay content or financial operation was used.

## 2026-11-11 — pane validation continuation

On macOS 26.6.2, the previously built isolated `yaki_pane_fixture` (separate
bundle and preferences, synthetic content) opened at a constrained width with
350-point panes. Entering fullscreen produced 626/713-point panes; focusing
the divider and pressing Left changed them to 606/733. Two automated pointer
drag attempts produced no observable change, so native dragging remains
unverified; this observation alone does not establish a divider defect. The
fixture was closed without using the signed-in app. VoiceOver, real feed and
sidebar content, production window restoration and physical display changes
were not checked. The 400-point minimum remains provisional.

The current checkout's splitter and real DM/interest-card widget tests passed
(8 tests) with Puro `pipress`, Flutter 3.44.9 and Dart 3.12.2. The sandboxed
Dart VM crashed on startup; the test ran outside the sandbox. These widget
tests are not a substitute for native real-content or accessibility checks.

## 2026-11-08 — pane-local sizing audit

Completed the source audit of pane-route window sizing and fixed confirmed
desktop issues across feed and media grids, editor previews, forms, dialogs,
wallet surfaces and onboarding-related controls. Desktop grids now adapt to
local width and text scale; short dialogs scroll where needed. Mobile layout
branches remain in place. Fixtures exercise resizing, draft and scroll-state
retention, large text, media patterns and representative wallet and dialog
layouts using disposable data. The desktop regression suite passed 162 tests.

This completes the source and widget-test audit, not native visual validation
of every real-data flow. Native window and accessibility checks, localization,
real content and phone/tablet visual checks remain on the Phase 2 list. No
signed-in session or financial operation was used for this verification.

## 2026-11-05 — Cashu payment and amount forms

Desktop Cashu deposit input, Lightning payment, eCash send, swap and nutzap
forms use the available dialog height and can scroll through their controls
and actions in short windows. SATS and fiat labels wrap on desktop when needed;
phone and tablet retain the prior row and sizing paths. Disposable 320×350
fixtures cover all five forms at 1.5× and 2× text in LTR and RTL, including
amount entry, draft retention while scrolling and the Lightning-address amount
step. They use empty wallet state and a placeholder recipient, and do not make
payments, create tokens or swap funds. Thirty-eight grouped wallet, dialog and
no-hover tests passed. Native appearance, real wallets and mint selectors,
translated labels, actual payment operations and phone/tablet visuals remain
unverified. The signed-in session was not touched.

## 2026-11-05 — checker and Cashu dialog sizing

The desktop Smart Widget checker selects its two-column layout from pane width;
its narrow sliding preview uses pane-relative positions, and the empty preview
scrolls. A narrow preview remains accessible in view mode and resizing to the
wide layout does not leave the component list blocked. A disposable 1.5× text
fixture checks 320–800–400-point resizing and the slide state, without loading
a real Smart Widget.

The desktop Cashu deposit dialog fills its available height, bounds its invoice
QR to local width and scrolls invoice content. Desktop send and receive choice
sheets also scroll in short dialogs. A mocked, non-payable deposit quote and
320-point fixtures at 1.5× text cover the invoice and both choice sheets; no
payment or wallet operation is performed. Eighteen grouped layout, wallet and
no-hover tests and full analysis passed. The running session was not touched.
Real invoices, payment and deposit actions, Smart Widget data, RTL, translated
labels, native visuals and phone/tablet visual regression remain unverified.
The wider pane-sizing audit remains open.

## 2026-11-05 — Cashu operation result sizing

Desktop Cashu operation results now scroll in short windows, use bounded
success-animation sizes, and keep the token QR square within local width with a
320-point cap. Phone and tablet retain their existing layout. A disposable,
non-redeemable placeholder fixture renders the actual sheet at 320×350 points
with 1.5× text and scrolls to Close. Ten wallet, modal and no-hover tests and
full analysis passed. No token was created or redeemed; native visuals, real
QR scanning and phone/tablet visuals remain unverified. The running signed-in
session was not touched.

## 2026-11-05 — zap invoice dialog and amount dividers

Desktop zap invoice dialogs use a locally bounded square QR and scroll in short
windows. The desktop send, receive and zap amount screens also cap their divider
widths; phone and tablet paths retain their prior dimensions. A non-payable
placeholder fixture checks the QR dialog at 380×300 points and 1.5× text.
Ten wallet, modal and no-hover tests and full analysis passed. The fixture does
not create or pay an invoice; real scanning and native visuals remain open. The
signed-in session was not touched.

## 2026-11-05 — desktop feed media

Desktop inline videos now have a 720-point width cap and an explicit gallery
action; single images and multi-item galleries also expose a gallery action.
Hidden desktop videos show a neutral placeholder before activation, and hidden
video gallery tiles do not generate thumbnails. The existing image bounds,
video aspect-ratio handling and autoplay setting are retained. Mobile and tablet
paths remain unchanged. Twenty-two disposable feed-media, gallery, playback
coordination and no-hover tests and full analysis passed. The tests do not play
real media or exercise native video decoding; current-build native rendering,
playback and sensitive-media visuals remain open. No user media was used, and
the signed-in session was not touched.

## 2026-11-05 — Home sidebar density

The existing desktop density setting now also controls the section and heading
gaps in the current Home side pane. Comfortable retains the previous spacing;
compact reduces gaps without changing card or control dimensions. The
non-desktop suggestion layout retains its existing spacing. A disposable
interest-section fixture checks both settings and restoration at 1.5× text;
seven density, pane and no-hover tests and full analysis passed. Native theme,
contrast, live content and hit-target checks remain open. The signed-in session
was not touched.

## 2026-11-05 — invoice QR pane sizing

Desktop receive-invoice and zap-invoice QR codes now use a shared square bound
that follows local width and caps at 320 points. Phone and tablet retain the
existing 70.w sizing. A disposable placeholder fixture checks the shared bound
inside an intrinsic scroll layout at widths of 240, 320 and 600 points. Six
wallet QR and modal tests and full analysis passed. The fixture does not render
the complete invoice screens or initiate a payment; real invoices, scanning,
native rendering and mobile/tablet visual checks remain open. The signed-in
session was not touched.

## 2026-11-05 — desktop focus strategy

Application startup now uses Flutter's input-aware focus strategy on desktop;
phone and tablet retain touch mode. Previously touch mode suppressed the
divider and rail keyboard-focus indicators in the actual application. Twenty pane, focus, account and
no-hover widget checks pass, as does full analysis. Native screen-reader and current-build focus
traversal remain unverified.

## 2026-11-05 — pane minimum and native fixture follow-up

A disposable widget fixture puts the real desktop DM workspace and real
suggested-interest cards on opposite sides of the outer divider at an
approximately minimum-window content width. At 1.5× text, both 400-point
extremes render and a disposable DM draft survives narrowing and widening.
This is not the full Home feed or the live sidebar.

A separate macOS Flutter fixture with a distinct bundle identifier and its own
preferences used a copy of the current divider and synthetic content. Native
keyboard adjustment changed the panes from 532/520 to 492/560 points; a
fullscreen round trip restored 492/560, and after quitting and relaunching the
fixture fullscreen restored the same 795/904-point split seen before restart.
The fixture did not test real app content, physical display changes, VoiceOver,
mouse dragging or the production window-frame restoration. The original signed-in
app was not touched. Eighteen pane, account, focus and no-hover tests and full
analysis passed. The pane minimum is still provisional until current-build real
feed/sidebar and native display/accessibility checks are completed.

## 2026-11-05 — divider focus and DM draft preservation

The desktop divider now shows keyboard focus without a hover highlight and
only exposes semantic resize actions that can move it at the current limit.
A disposable DM draft survives a wide–narrow–wide transition; a control run
without an added key confirmed that Flutter already preserves the subtree.
Account change fixtures still return the detail navigator to its base. Seventeen divider,
DM, account, focus and no-hover tests passed, as did full analysis.

The current 400-point pane minimum and 520-point default remain provisional:
these tests do not establish usability of real feeds and sidebar content or
native fullscreen, display changes, VoiceOver and live account behavior. The
signed-in session was not touched and its build may differ from source.

## 2026-11-05 — grouped wallet and points sizing

Desktop Lightning-address QR rendering now uses its local width and remains
square, capped at 320 points. Cashu loading artwork, balance divider and mint
URL control use bounded desktop dimensions instead of window percentages. The
points explanation has a 560-point desktop width cap and scrolls in a short
window. Phone and tablet sizing paths remain unchanged.

A disposable Lightning-address fixture checks the QR at 240, 320 and 600
points. Solid and fluid points fixtures use a 320×400-point box at 1.5× text
and scroll to the action. Sixteen wallet, points, modal and no-hover tests and
full `flutter analyze --no-pub` passed. Cashu loading and balance dimensions
were analyzed but not rendered in these fixtures. Native layout, real wallet
state, QR scanning, translated labels, and phone/tablet visuals remain open.
No payment, sharing, export or account action was performed; the signed-in
session was not touched.

## 2026-11-05 — empty Cashu wallet sizing

The desktop empty Cashu wallet illustration is bounded to its local width and
160 points, and the empty state scrolls in short panes. Both desktop wallet-type
switch labels can wrap instead of overflowing at larger text sizes. Phone and
tablet layout paths remain unchanged. Disposable 320×220-point fixtures at
1.5× text cover solid and fluid states in LTR and RTL and scroll to the add
button; both switch variants also fit a 200-point fixture. Eight wallet and
empty-state tests and focused analysis passed. No wallet was created or
switched. Native layout, translated labels, live wallet state, and phone/tablet
visuals remain unverified; the signed-in session was not touched.

## 2026-11-05 — eCash token dialog sizing

The desktop eCash token QR now stays square within the dialog's available
width, capped at 320 points, and the dialog content scrolls in short windows.
Phone and tablet retain their existing layout. A non-redeemable placeholder
fixture checks the QR at 240, 320 and 600 points and opens the actual desktop
dialog in a 600×500-point window at 1.5× text, scrolling to its action. Four
wallet, modal and shared-sizing tests passed. No token action was invoked.
Native appearance, QR scanning, translated labels, real tokens and mobile/tablet
visuals remain unverified; the running signed-in session was not touched.

## 2026-11-05 — split restoration and nested focus fixture

A disposable shell fixture reproduces the earlier first-Tab observation: the
nested Navigator initially owns focus and Tab enters its side control. Continued
Tab traversal reaches and activates the rail, main and side controls; this does
not establish the traversal order or behavior of the actual shell. No focus
policy was changed. Divider fixtures also check saved 1% and 99% fractions at
wide and narrow widths, preserving the saved value and restoring the clamped
layout after remount. Ten focus, divider and menu tests passed. Real content at
pane minimums, native keyboard and screen-reader traversal, fullscreen/display
changes and live account behavior remain open. The signed-in app was not touched.

## 2026-11-05 — compose and account keyboard access

The compact Compose button now has an explicit semantic label. The signed-in
account footer uses the same focusable, labeled rail action as destinations,
with its existing switcher callback and avatar tap preserved. Disposable tests
open the actual compact and expanded Compose menus by keyboard, dismiss them
with Escape and reopen them; a separate account-control fixture does the same
with a disposable dialog. No account was switched and no content was published.
An initial synthetic nested-pane fixture did not reach its rail action with Tab;
that fixture was not retained and does not establish the cause or actual-shell
behavior. End-to-end pane traversal, real account dialog and VoiceOver still
require verification. The running session was not touched.

## 2026-11-05 — rail keyboard access

Desktop rail destinations and search now expose labeled button semantics,
keyboard focus and Enter/Space activation. Selected destinations report their
state, and the existing long-press action remains available to semantics.
Keyboard focus has an outline; pointer hover does not add a highlight. A
disposable control fixture covers activation, focus, semantics and hover;
focused analysis and 15 navigation/control/hover tests passed before the
additional hover fixture, which also passed. Native focus traversal, VoiceOver,
actual destination actions, compose/account access and focus restoration remain
open. No mobile or tablet navigation code was changed; the signed-in session
was not touched.

## 2026-11-05 — poll chooser

The desktop poll chooser no longer reserves a phone navigation-bar inset and
can scroll in a short dialog. Phone and tablet retain their existing layout.
A disposable 320×220-point fixture at 2× text rendered the two choices and
exercised scrolling without creating a poll; focused analysis and three chooser/modal
tests passed. Real navigation, native appearance, translated labels and
mobile/tablet visuals remain unverified. The signed-in session was not touched.

## 2026-11-05 — image selector actions

The desktop article image selector's action footer can grow for enlarged text
instead of being limited to the phone navigation-bar height. The phone and
tablet height remains unchanged. A disposable 320×350-point fixture at 2× text
checks the action's size without uploading; focused analysis and six dialog
tests passed. Native rendering, translated labels, image selection and upload,
and mobile/tablet visuals remain unverified. The signed-in session was not
touched.

## 2026-11-05 — calendar overflow affordance

The desktop calendar now shows an interactive horizontal scrollbar when its
content overflows. Its thumb keeps the same color and thickness on hover.
Disposable 320-point, 1.5× text fixtures dragged the scrollbar with a mouse
in LTR and RTL; focused analysis and 11 date-picker, divider and no-hover
tests passed. Native appearance, trackpad and keyboard access, date selection,
translated labels and mobile/tablet visuals remain unverified. The running
signed-in session was not touched.

## 2026-11-05 — pane state and account fixtures

Disposable widget tests exercise the actual signer-notification path: a
same-key refresh preserves an open text draft, while switching keys or signing
out returns the detail navigator to its base. A separate divider fixture checks
that both independent scroll positions and a draft survive a drag. Full
`flutter analyze --no-pub` and 76 desktop/navigation/hover tests passed using
Puro `pipress`. These do not verify real account
switching, draft persistence, nested dialogs, live data or native behavior.
The signed-in session was not touched.

## 2026-11-05 — shared date picker

The desktop date picker uses a bounded height, allows its calendar to scroll
horizontally when enlarged text needs more width, and wraps the time and clear
controls. Phone and tablet sizing remains unchanged. A disposable 320×350
point fixture with 1.5× text exercised scrolling and clearing; focused analysis
and the widget test passed. Native horizontal-scroll discoverability, date and
time selection, translations, RTL and phone/tablet visuals remain unverified.
The running signed-in session was not touched.

## 2026-11-05 — media chooser and Smart Widgets

The desktop media chooser no longer reserves the phone navigation-bar inset.
The desktop tools list uses a single column and bounded saved-tool cards. The
desktop Smart Widget preview has a bounded width and scrolls content within its
available height. Phone and tablet branches remain unchanged. A disposable
320-point, 1.5× text fixture rendered the media choices without selecting or
uploading files; a valid six-button Smart Widget fixture verified scrolling in
a 320×180-point box. Focused analysis and seven desktop tests passed. Real
tools, native rendering, selection/upload, RTL and mobile/tablet visuals
remain unverified.

## 2026-11-05 — bookmark dialog and article table

The desktop bookmark picker and create-list form use fixed padding rather than
window-relative tablet padding. Desktop article table editor inputs use
bounded column widths. Phone and tablet branches are unchanged. A disposable
320-point widget fixture with 1.5× text verified bookmark title entry; it did
not publish or save a list. The bookmark picker with real lists and the table
editor's native interaction and large-text layout remain unverified.

## 2026-11-05 — profile QR and shared empty states

Desktop profile QR codes now remain square within their local pane, capped at
320 points, instead of using window width for both dimensions. Desktop
signed-out, muted, disabled-message, offline and error illustrations use
bounded sizes; offline instructions can wrap in a narrow pane. The existing
phone and tablet paths remain unchanged. Disposable widget checks cover QR
resizing at 240, 320 and 500 points, an offline retry action at 320 points
with 1.5× text, and a long offline instruction. The QR test exercises the
shared bounds with a disposable payload, not a real profile view. Native
appearance, QR scanning, real profile actions, RTL and mobile/tablet visuals
remain open.

## 2026-11-05 — shared headers and image selector

Wallet, inbox and notification selectors now cap their desktop width instead
of using half the full window; the protected-event dialog icon is bounded as
well. The desktop image selector uses a bounded preview and a two-column
history rather than window-height sizing and a tablet grid. Phone and tablet
branches remain unchanged. Disposable widget fixtures exercise the
notification menu and image selector at 320 points with 1.5× text, including
empty and placeholder history; no images were uploaded. Real history, native
rendering, long translated labels and phone/tablet visual regression remain
unverified.

## 2026-11-05 — shared desktop sizing and divider checks

Desktop revenue-split padding and share-dialog padding now stay bounded rather
than scaling with the window. Share QR rendering stays square within local
width (up to 320 points), and desktop share recipients and palette controls use
bounded sizes. The desktop QR scanner fallback no longer reserves a
window-sized square. Two shared signed-out banner illustrations and the Smart
Widget profile selector also use bounded desktop sizes. Phone and tablet
branches retain their prior sizing.

A disposable 320-point widget fixture with 1.5× text exercises the scanner
fallback, revenue-split toggle and share QR, including RTL direction. Divider
tests also exercise invalid saved values and semantic increase/decrease; the
existing drag, persistence, clamping and keyboard-reset tests pass. Ten focused
widget tests, full `flutter analyze --no-pub`, and 62 desktop/navigation tests
passed using Puro `pipress`. These checks do not establish real
sharing, QR scanning, editor data, native VoiceOver, or mobile/tablet visual
behavior. The running signed-in app was not changed or restarted; its build is
unknown. Divider minimums remain provisional and the wider sizing audit remains
open.

## 2026-11-05 — article relay selection

The desktop article relay step now uses fixed padding and a single column, so
its choices fit a narrow pane even when the full window is wide. Phone and
tablet branches retain their previous padding and grid behavior. A disposable
widget fixture passed at 320 points with 1.5× text and exercised a relay tap;
focused analysis passed. Native appearance, real relay selection, RTL and
mobile/tablet visual regression remain unverified. The running signed-in app
was not restarted or used as a fixture.

## 2026-11-05 — desktop curation items

Desktop curation editing now uses the existing single-column reorderable list
instead of the nested two-column grid. Its separate drag handle leaves the
delete action accessible, and reorder updates the displayed active collection.
Phone and tablet continue to use their previous responsive branches. Focused
analysis and three existing desktop layout tests passed. A disposable narrow
widget fixture also verifies dragging through the desktop handle and an adjacent
delete action; it does not cover the real curation data flow. The macOS debug
build succeeded with the existing Swift Package Manager plugin warnings. Native
dragging, deletion, scrolling and visual layout still require verification with
safe fixtures.

## 2026-11-05 — publishing editor padding

Curation, video and Smart Widget content and specification screens now use
fixed desktop padding instead of padding based on the whole window. Their
phone and tablet branches are unchanged. Focused analysis and four existing
desktop layout tests passed; those tests do not render these editors. A macOS
debug build succeeded with the existing Swift Package Manager plugin warnings.
Native layout, large text and the curation grid at narrow widths remain unverified.

## 2026-11-05 — article publishing layout

Article publishing details and the article image selector's action row use
fixed desktop padding instead of window-relative tablet padding. Phone and
tablet branches are unchanged. Focused analysis and four existing desktop
layout tests passed; these tests do not exercise the article screens. A macOS
debug build succeeded with the existing Swift Package Manager plugin warnings.
Native visuals, long labels, large text and image selection remain unverified.

## 2026-11-05 — paid-note sheet sizing

The desktop paid-note sheet now uses local padding, a bounded alert icon and a
square invoice QR capped at 320 points and constrained by the available width.
Phone and tablet sizing paths remain unchanged. Focused analysis and five
existing desktop modal/control tests passed; those tests do not cover the invoice.
The macOS debug build succeeded with Flutter 3.44.9 / Dart 3.12.2 (Puro
`pipress`); Flutter reported existing Swift Package Manager plugin warnings.
No YakiHonne process was running when checked, and the build was not launched.
The native invoice, large text and QR scanning remain unverified. No test payment
or publish was attempted. The root glass guide remains absent.

## 2026-11-04 — people grid

Know people now uses the shared pane-width masonry grid for profile cards and
loading skeletons, and the existing search-profile component for profile identity.
The trending-note request supplies author IDs only; the view loads profile
metadata for display. Tests cover narrow/wide placement and profile interaction;
native rendering and live metadata still need verification.

## 2026-11-04 — people discovery

The former Following workspace source is now Know people. It shows unique
trending-note authors, excludes the active account and muted users, and reuses
the existing profile cards. Existing saved Following selections open the new
source. The source has profile skeletons, search and refresh; account switches
rebuild the workspace. Focused tests cover author ordering and deduplication,
selection and navigation. Live relay, moderation changes and native appearance
remain unverified; an empty relay response does not establish connectivity.

## 2026-11-04 — responsive workspace feeds

Discover, Articles and Videos use a pane-width masonry layout: one column at
narrow widths and up to three when there is enough room, with fewer columns at
larger text scales. Their existing content cards and a single scrollable are
retained. A widget test covers narrow, wide and large-text column selection;
the workspace and divider tests also pass. Native appearance, live content and
scroll position when crossing a column breakpoint remain to be checked. Other
pane routes and the Following people list have not received this grid pass.

## 2026-11-04 — pane divider continuation

The persistent desktop workspace now has a draggable divider with a saved
per-device split, keyboard adjustment and reset, double-click reset, and
semantics actions. The default remains a 520-point side pane; both panes clamp
to 400 points when space permits and share smaller widths equally. This leaves
drag travel at the native minimum window size. A narrow
window does not overwrite the saved fraction. Focused widget tests cover drag,
restoration, clamping and keyboard reset. These are provisional layout values:
real content, screen scaling, restored geometry, VoiceOver, fluid/solid visuals,
and preservation of live drafts and pane stacks during resizing still require
native verification. No live session was restarted for this work.

The interrupted Articles/Videos/Discover slice passed targeted analysis and the
existing workspace tests, but live relay behavior, account isolation, moderation,
bookmark/follow updates, and route arguments remain to be verified. Empty relay
results cannot establish connectivity. No live content behavior is claimed here.

# Desktop Implementation Guide

Reference for shipping YakiHonne to macOS, Windows and Linux. All findings are sourced from
the current tree (branch `DESKTOP`, merged with `main` v2.0.7 on 2026-09-01) — resolved
dependency versions come from `pubspec.lock`,
platform support from each plugin's declared `flutter.platforms` key, not from documentation.

**For what is done and what is left, jump to the [Implementation tracker](#implementation-tracker).**
The original analysis and tracker below are historical; the current audit supersedes them.

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

## Current audit — 2026-11-01

### Desktop pane source update

Notifications and Bookmarks have been removed from the pane selector at the
user's request; saved selections for them fall back to Discover. Following now
shows profile bios, NIP-05 identifiers and websites when available. The NIP-05
text is displayed without a verification claim. This remains a people view,
not a notes feed. Native appearance and account switching need verification.

### 2026-11-03 continuation

Desktop pane redesign: Following · Notes was removed at the user's request.
The default is now a discovery digest with topic shortcuts and compact trending
note previews; people, notifications and bookmarks remain selectable. A small
source pill replaces the former full-width header. Existing per-account source
choices are preserved; the removed source falls back to Discover. Discovery
uses the existing remote-cache trending query, with a timeout and retry, and
does not mount a second Home feed. Native visuals, live content, moderation
updates and relay/offline behavior still need hands-on verification.

Follow-up: the source selector now uses the centered `GlassPullDownButton`,
and interest shortcuts reuse `TagContainer`. The cache trending query can
deliver events without EOSE, so the discovery loader keeps partial results at
its deadline and closes its request. If the cache returns no usable previews,
it queries the app's existing trending relays using an isolated core. Tests
cover cache completion and missing EOSE; actual relay results and appearance
have not been verified in a fresh macOS session.

Screenshot correction: the default glass trigger shape rendered as a wide
ellipse. The source selector now explicitly uses a rounded rectangle with a
radius matched to its height. Its centered placement and shape are covered by
a widget test; the corrected native appearance still needs a fresh launch.

The user subsequently requested the exact left-pane container and a floating
selector. Both panes now use the shared `FluidSourceContainer`; the right
selector overlays independently scrolling content and uses the same inset.
The previous right trigger was 48 points while the rendered left control was
40; both desktop containers now share the 40-point height, verified by a test
rendering the actual controls side by side. The right pane's source menu remains
independent. Native visual verification is still outstanding.

Glass source-menu positioning follow-up: automatic screen clamping combined a
pane-sized `MediaQuery` with window-global trigger coordinates, moving the
right menu toward the left pane. The menu now opens centered on its trigger,
with its width bounded by the pane. A widget test uses a horizontally offset
nested navigator and verifies that every menu item stays inside the pane and
can be selected; native verification remains open.

Following-feed continuation: the workspace source menu now offers Following ·
Notes alongside the existing people, notifications and bookmarks sources. This
experiment was subsequently removed as described above. Its
controller owns refresh and pagination, deduplicates events and discards stale
or wrong-account results. Each query uses a separate short-lived Nostr core and
its own relay sockets, sharing the cache but not the main core's socket map.
The account's relay list must be ready before it queries. Pagination overlaps
the boundary second and reports a stalled full duplicate page, though relays
do not guarantee stable ordering among events in the same second. The shared
query helper suppresses some transport errors, so an empty response cannot
reliably distinguish offline from empty. The view listens for mute and deletion
updates while mounted. Unit tests cover controller state and the signed-out
selector, not live relay ownership, feed rendering, resource use, moderation
updates, or native behavior. Those remain open.

Rechecked `DESKTOP` (60 commits ahead), the unstaged diff and untracked desktop
files; the root glass guide remains absent and the local dependencies and
`.env` are present. A YakiHonne session was already running, so it was not
restarted or used as evidence for the latest build. The Puro VM aborts in the
sandbox; focused checks require execution outside it.

The player audit found that an account switch could leave a pending play intent
valid before a controller was active. The manager now invalidates that intent
when its account changes, including while initialization is in progress. A
fake-platform regression test covers the loading case; this is not a native
account-switch verification.

YouTube feed embeds use `youtube_player_flutter` with a widget-owned webview
controller, autoplay on activation, and disposal with the feed widget. On
desktop, playback notifications now coordinate pauses with managed videos and
other registered embeds; account changes pause embeds belonging to the previous
account. The managed video's bar remains available while paused. The embed is
not retained in that bar and webview playback reports arrive asynchronously;
rapid switches, account changes and native YouTube behavior require hands-on
verification. The editor's separately owned file preview now participates in
desktop pause coordination, exposes play/pause, and avoids autoplay after a
newer play intent or account change during initialization. It is not retained
in the bar. A widget test covers pausing and resuming the preview with a fake
video platform. Mobile playback is unchanged. Native editor behavior and
disposal while loading still require verification.

### 2026-11-03 workspace-base slice

Desktop playback follow-up (supersedes the opt-in prototype description
below): managed desktop videos start paused. Playing one activates its bottom
bar and pauses other managed controllers; the bar retains the active controller
when the video page is closed with Back. Inline feed videos without a Nostr
video model use a URL-based session and can be reopened from the bar. Desktop
media-grid previews use static cards. A play-intent generation prevents a slow
earlier selection from taking over a newer one. The single-player policy is
disabled on mobile. Account changes clear the retained session. The separate
YouTube embeds and local editor previews now participate in pause coordination
as described above. Native playback, switching, and Back still require manual
testing.

Desktop Now Playing prototype: horizontal and vertical video detail pages have
an explicit Keep playing action once their controller is ready. It transfers an
additional controller owner to a bottom bar; the original page can then close
without disposing or visibility-pausing that video. The bar supports playback,
seek, mute, reopening the detail page, and close. A different video detail or
an account change stops the retained player. Feed previews do not create a
session. Existing fallback URL aliases are resolved when reopening a controller.
This first slice does not automatically minimize on ordinary Back/navigation,
does not provide a floating video preview, and has not been visually or natively
verified with actual media, fullscreen, rapid account switches, or all themes.
Focused fake-platform ownership/account tests, navigation tests, analysis, and a
macOS debug build passed; these do not prove native playback behavior.

Player placement follow-up: the former scaffold-wide bottom navigation slot
could expand to cover the window. The player now has a bounded height beneath
the two content panes, inside the content column; the sidebar retains its full
height. A widget test checks the hidden and visible layouts and their bounds.
Visual verification in a fresh macOS app remains open.

Player appearance follow-up: the bar shares the workspace's rounded fluid
surface and stays aligned with both panes. Its thumbnail/title, playback,
timeline and secondary actions are grouped; absent or sensitive thumbnails
use a compact video icon. Widget tests cover its bounds at compact and minimum
window widths, a long title and the no-thumbnail case. Real-theme appearance
and native playback remain to be checked in a fresh app session.

The user reported a non-finite `AspectRatio` assertion when minimizing a
vertical video. During the pane resize the video can receive zero or unbounded
dimensions. The vertical ratio calculation now has a portrait fallback, and
the shared player independently rejects invalid ratios. Focused tests exercise
zero/unbounded constraints and a mounted player transitioning through infinity,
NaN, and zero. Native playback of the corrected transition remains to be
retested in a running app.

Window sizing follow-up: macOS minimum width is now 1,153 points: two
520-point content panes, a 1-point divider, a 72-point compact rail, and
40 points of shell padding. This is calculated from the current layout;
actual minimum-size rendering and window restoration still need a full app
restart and visual verification on real displays.

Follow-up: the base has a per-account source selector for Following people,
notification history and bookmark lists. It retains visited source widgets;
notification history is displayed only for its owning account, and bookmark
lists are filtered by owner. The existing notification data is reused without
sharing the main view's tab or scroll controller. Bookmarks have a pane-owned
cubit which remains alive beneath its detail route. Following notes, live
account switching, real data, and native layout still require verification.

- `DetailPane` retains its nested navigator and now seeds an account-scoped
  Following people list and Search action, using the account's cached contact list. Visible rows request profile metadata. The base route remains mounted under
  opaque detail routes. It does not subscribe to relays or attach the main
  feed's controller. The main area's controllers remain owned by
  `MainViewContent`, per tab and account; the base owns its own scrollable.
- Home's global `LeadingCubit` owns source selection, refresh, pagination and
  live-feed activity. `LeadingFeed` also schedules suggestions and ads. A
  second instance is therefore not a safe independent Following pane. An
  isolated source, cancellation, pagination, account ownership and side-effect
  contract remain necessary before introducing one.
- The existing signer hook pops the pane stack when its public key changes,
  but preserves it for same-key metadata refreshes. It uses animated pops;
  transition privacy, unsaved editor behavior and real account switching are
  not verified. DM selection replaces the current DM route only when that route
  is on top; switching while a profile or other page covers it needs audit.
- Puro `pipress`: Flutter 3.44.9 / Dart 3.12.2. Both path dependencies and
  `.env` exist; root `GLASS_IMPLEMENTATION.md` remains absent. Focused pane,
  route and pagination tests passed (19); `flutter analyze --no-pub` passed;
  macOS debug build succeeded. The build emitted Swift Package Manager plugin
  support warnings. A visual inspection reached an already running older app
  instance displaying the previous empty pane, so it does not validate this
  build. It was left running to avoid interrupting the existing session. The
  minimum/wide, theme, account, drafts and relay runtime checks remain open.
- Following the initial review, the fallback was changed to the cached people
  list. The six focused base/navigation tests and analysis pass. A new macOS
  build was interrupted after an extended wait; the revised UI has not been
  visually checked in a fresh process.

For the proposed desktop product direction and its implementation backlog, see
[Desktop product assessment](DESKTOP_PRODUCT_ASSESSMENT.md) and
[Desktop task plan](DESKTOP_TASK_PLAN.md). Those documents describe proposed
work; this audit records implementation and verification evidence.

### Persistent desktop pane — 2026-11-02

- The user requested a permanent side pane for desktop pages, including wallet
  and editor flows, with DM conversations beside their list. The desktop shell
  now allocates both panes at all window widths; the detail pane shares narrow
  space and caps at 520 points. Page navigation uses the detail navigator,
  including named pages and direct page pushes. Selecting a different conversation
  replaces the previous DM route; switching accounts clears the pane stack.
- The macOS minimum window width is now 1,280 points, with the sidebar collapsing
  below 1,450 points. Narrow desktop feeds use one card column, and the media
  grid uses two columns. Grid geometry and navigation have focused tests. The
  full range of views, dialogs, account switching and resizing still needs a
  hands-on pass, especially wallet and editor flows at the minimum width. Windows
  and Linux window minimums have not yet been implemented or tested.

### macOS notification investigation — 2026-11-02

- The user reports YakiHonne is absent from macOS notification settings. The
  app only requests notification permission on Android. More fundamentally, the
  locked `awesome_notifications` 0.10.1 macOS plugin implements only
  `getPlatformVersion`; notification and permission methods return
  `FlutterMethodNotImplemented`. Its declared macOS platform entry is not evidence
  of functional notification support. A macOS notification implementation and
  live-event wiring are needed before system alerts can be verified. Android
  UnifiedPush does not provide closed-app macOS delivery.

### Compose pane follow-up — 2026-11-02

- Wide desktop routes the note, article, media and smart-widget composers into
  the detail pane. The pane remains mounted when hidden for DMs or a narrow
  window, preserving its navigation stack and unfinished composer state; new
  pushes use the root navigator while the pane is hidden. Publication dialogs
  opened by a pane composer use its navigator so they close the correct editor.
  Routing and hidden-state behavior have widget coverage; the editors and
  publishing flows still need a hands-on macOS pass.

### User runtime verification — 2026-11-02

- The user reports that startup, profile refresh placement, detail-pane spacing,
  article refresh, and video save and cancellation worked in their macOS test.
  The report does not establish whether article replacement with a newer event,
  saved-video playback, or every pane route and theme was exercised.
- The user reports that the final Blossom Upload button did nothing after file
  selection. The open dialog had no configured servers, so its upload button was
  disabled. It now shows an empty-server message directing the user to add one.
  The YakiHonne server card offers an Add server action; a real upload and Blossom
  download remain to be verified after a server is configured.

### Debug launch follow-up — 2026-11-02

- A fresh `puro -e pipress flutter run -d macos --debug --no-pub` built and
  launched successfully. Its startup output showed successful relay connections as well as
  DNS, HTTP and timeout failures for other relays. The captured output was truncated, so
  it cannot conclusively establish whether the frame-scheduling exception recurred.
- An earlier YakiHonne process was still attached to a VS Code debug session. The desktop
  automation selected that older window rather than the newly launched process, so no
  visual or interactive results from this launch can be attributed to the rebuilt app.
  The newly launched processes were stopped; the existing debug session was left intact.
  Startup logging and the profile, pane, article, video, QR, Blossom, export and native
  thumbnail checks remain open on a uniquely identifiable rebuilt instance.

### Article refresh follow-up — 2026-11-02

- A subsequent user test reported an error. The refresh now includes the article's relay
  hints, relays recorded for its event, connected relays, and configured user relays;
  individual connection attempts have a bounded timeout. These address possible missed
  relays and long connection waits, but the exact cause of the reported error is not yet
  established. Focused analysis and a macOS debug build passed; retest against the same
  article is still required.
- Article detail now exposes a desktop refresh action and uses the same relay-backed
  operation for pull-to-refresh. It queries the author, article kind (including drafts),
  and identifier without a cache-first lookup, selects the newest returned event, and
  retains the displayed event if the response is older. A replacement rebuilds the
  article subtree so metadata, actions, highlights, and translation state use the same
  version. An empty response or exception shows an error; an empty response cannot
  distinguish an unavailable relay from an article not found.
- Focused analysis of `article_view.dart` passed and all 12 desktop pagination tests passed
  with the `pipress` SDK. The article refresh itself has not been exercised against live
  relays or tested on a running rebuilt app. No additional media, notification, signing,
  deep-link, or layout runtime verification was completed in this follow-up.

### Video save follow-up — 2026-11-02

- On macOS, video downloads now use the already registered file selector's save panel and
  copy the temporary download to the chosen destination without loading the video into Dart
  memory. Temporary files are removed after success, cancellation, and failed downloads;
  unsupported desktop platforms are rejected before downloading. Unknown response lengths
  no longer produce invalid progress percentages. The selector platform interface is now a
  direct dependency at the existing locked version.
- The download dialog waits for the save operation before showing success, and reports
  cancellation and failure separately. Closing the dialog during the operation no longer
  updates disposed widget state. These behaviors are code-level changes, not runtime results.
- Full analysis passed before the dialog follow-up; focused analysis passed after it, and
  the final macOS debug build succeeded with the existing Swift Package Manager warnings.
  This path, including save-panel permissions, cancellation,
  overwrite, large files, and the resulting video, still needs a rebuilt-app runtime test.

### Detail-pane layout follow-up — 2026-11-02

- Removed the standalone refresh row above profiles; the existing profile menu now runs
  the active tab refresh and resets pagination. In desktop detail panes, profile toolbar
  controls and shared fluid app bars have a small top inset, and shared fluid bottom bars
  and the article's floating stats bar have bottom breathing room. The pane navigator and
  its content remain full-size. These changes need a rebuilt-app visual pass, including
  other pane routes and non-fluid themes.
- In the prior rebuilt app, an article opened with the refresh button and remained visible
  after clicking it; no newer version was available to verify replacement. The button was
  still disabled at the next observation, so a UI timeout was added. A timed-out
  underlying relay query may continue until its own cleanup completes. The timeout and
  error feedback have not yet been verified in the rebuilt app.
- Focused analysis and all 12 desktop pagination tests passed; a macOS debug build
  succeeded with the existing Swift Package Manager warnings. Video save was attempted
  from a feed player but the save dialog was not reached; it remains unverified.

### Pagination frame scheduling — 2026-11-02

- A startup exception was traced to changing the refresh footer from a scroll notification
  during layout. Automatic pagination now schedules the footer transition after the frame,
  coalesces notifications, and checks that the controller is still eligible before loading.
  A widget regression test dispatches duplicate notifications during layout.

This audit supersedes conflicting historical statements below. `DESKTOP` contains the local
merge of main through 2.1.1 (`2afb6bb`); the branch was clean and 60 commits ahead of its
remote at the start of this pass. The post-merge analysis, 35 selected tests and macOS debug
build reported by the previous session are not a full suite or a hands-on runtime pass. The
current `.puro.json` selects `pipress`; use its Dart 3.12+ SDK for the merged dependencies.
The root `GLASS_IMPLEMENTATION.md` named by AGENTS.md is absent in this checkout.

### Runtime follow-up — 2026-11-01

- Relaunched the built debug app from `build/macos/Build/Products/Debug/YakiHonne.app`.
  A media-grid image opened in the detail pane; its download action opened the macOS save
  panel. Cancel returned to the app without a success message. A subsequent save to a
  temporary location showed success and produced a valid 1024×1024 PNG. This covers one
  image, not other formats, video, QR images, Blossom downloads, or key/wallet exports.
  The signed-in account had no connected wallet and no Blossom files for those checks.
- A wide video detail exposed an unwanted left inset from the nested navigator's padding.
  Removed that inset for all pane routes; after rebuilding and relaunching, the video player
  met the pane divider. The remaining top inset was subsequently removed and the rebuilt video view was checked
  against the pane top. Other pane views need a visual regression pass after this shared change.
- Resized to a narrower desktop window: the sidebar collapsed, the detail pane disappeared,
  and the media source/filter/refresh row fit; refresh showed the grid loading state and
  repopulated the grid. A full narrow-width layout, pagination and retry audit is still
  outstanding.
- Video preview images appeared in the media grid, but event-supplied artwork/cache has not
  been ruled out; this is not evidence that native thumbnail generation succeeded. The video
  detail menu inspected did not expose a download action. Notification delivery, signing,
  and deep links were not tested in this pass.

### Follow-up — 2026-11-01

`puro -e pipress flutter analyze --no-pub` passed; `test/desktop_pagination_test.dart`
passed all 12 tests; and a macOS debug build succeeded. The build warned that several
plugins do not support Swift Package Manager, which Flutter says will become an error in a
future version. This is not a full test suite or runtime verification of the rebuilt app.

- **Observed in a running macOS session:** at a wide window the Home source/filter/refresh
  row and empty detail pane rendered. Clicking refresh displayed the loading state and then
  replaced the feed with newer items. The filter opened as a centered dialog and Escape
  dismissed it. This was an already-running app of unconfirmed build identity; it does not
  verify the later changes below, narrow sizing, pagination/retry, other dialogs, or glass
  variants.
- **Media and exports (code-level only):** macOS network image/video, QR image and Blossom
  downloads use the native save dialog instead of the mobile gallery plugin. Cancellation is
  handled without a success/error toast. macOS key/wallet export stops after the save dialog
  instead of calling the unsupported `open_filex` plugin. Both macOS entitlements allow
  user-selected file writes. Other desktop platforms report save failure until a supported
  file saver is chosen. The later video save follow-up above replaces the in-memory copy.
  Save, cancellation,
  formats, permissions and export behavior still need a rebuilt-app runtime pass.
- **Thumbnails (code-level only):** macOS uses the existing `fc_native_video_thumbnail`
  plugin; Linux returns the existing placeholder and Windows only attempts local files.
  Remote macOS videos, cache behavior and failures still need runtime checks.
- **Article:** the earlier metadata-only refresh was replaced in the 2026-11-02 follow-up
  above; relay and rebuilt-app behavior still need verification.
- **Dashboard:** the six empty callbacks are passed into individual content cards, not the
  Home refresh action; they remain unresolved and are not advertised as refresh controls.
  The outer content/smart-widget lists have separate non-empty refresh callbacks.
- **Notifications:** the locked `awesome_notifications` plugin declares macOS support and
  is registered, but initialization, permission, delivery, tap and badge behavior remain
  unverified. Android resource names and the Android-only permission flow require a macOS
  runtime audit; no notification support is claimed from plugin registration alone.
- **Still open:** NIP-46 connection/signing and cold/running links, narrow layout, keyboard,
  right-click, selection, dialog scrolling/Escape, the four layout/product decisions, and a
  current Windows/Linux dependency and packaging audit. Desktop IAP remains guarded.

Priorities and evidence from this tree:

1. **Purchase safety (partly guarded, high):** IAP defaults on. Receipt validation sends `android` on every
   non-iOS platform, and subscription settings label IAP as Google Play on macOS. The API
   accepts only `ios` and `android`; the IAP guide describes mobile store builds and does not
   establish a macOS product, receipt or distribution contract. macOS plugin availability alone
   does not establish that a purchase can be validated. Decide distribution and backend/store
   support before enabling a macOS store flow. Desktop store checkout is now blocked, restore
   and store-management controls are hidden, and historical `iap` payments use a generic label
   on desktop. Points and the existing non-IAP configuration remain available. These guards have
   not been exercised with a real account or purchase; validation itself still needs a platform
   contract before desktop IAP is enabled.
2. **Mobile plugins (partly guarded, runtime unverified):** all five QRView constructions now
   gate the scanner to mobile. Redeem defaults to manual entry on desktop and the profile share
   scanner toggle is hidden. Other scanner pages show an unavailable message; their calling
   flows need a usability pass and paste alternatives. Media saving still calls the mobile
   gallery plugin, video thumbnail generation calls `video_thumbnail`, and key/wallet exports
   call `open_filex`. Other direct gallery-saver calls exist in blossom management and diverse
   functions. These require desktop replacements or explicit gating. Local notifications initialize
   `awesome_notifications`; permission prompting is Android-only, and notification/badge calls
   remain unverified on macOS. A debug build does not prove plugin behavior.
3. **Feed interaction (code complete, runtime unverified):** `AdaptiveSmartRefresher` now
   provides a desktop refresh icon; in fluid notes, articles and media feeds it shares the
   source/filter container, with a standalone fallback elsewhere. Overflowing feeds load near
   the end on scroll;
   short lists get a load-more fallback, and failures get a retry control. It disables conflicting
   requests and exhausted pagination, allows explicit retry after
   failure, and does not auto-retry failed loads on scroll. Widget tests cover the short-list
   controls, loading, failure, exhaustion, refresh and existing scroll pagination. Call sites
   outside this wrapper and actual mouse, keyboard and layout behavior still need a runtime pass.
4. **Login/deep links (open):** remote signer forms exist; Amber controls are Android-gated.
   macOS registers Nostr and wallet schemes and `app_links` handles links, but cold and running
   launches, NIP-46 connection and signing have not been exercised. Verify signer handoff and
   both login variants on a signed-in desktop session.
5. **Desktop interaction and visuals (open):** sidebar hover and some secondary-click support
   exist, but feed long-press actions, selection, focus and application shortcuts need a broader
   audit. Panel-scoped MediaQuery does not make global `sizer` dimensions panel-scoped. Check
   narrow/wide windows, split DM/detail panes and adaptive modal sizing, scroll and Escape,
   including `showAppModalSheet` forwarding through `showAdaptiveModal`.
6. **Product decisions (open):** notifications detail layout, feed gutter, dedicated thread
   layout, and preserving the detail-pane stack across DMs need decisions and runtime design
   validation. Re-audit Windows/Linux plugin support and packaging against the current lockfile;
   the old matrix and test counts below are historical, not release evidence.

Desktop refresh follow-up: notifications refresh the active history/premium tab; dashboard home,
profile, wallet balance and transaction history, Cashu history, and creator subscriptions have
mouse-accessible refresh actions. Article detail now has the relay-backed refresh described
above. Some dashboard item `onRefresh: () {}` callbacks are no-ops rather than refresh
widgets and require individual product/data-flow review. These actions and their placement have
not been verified in a running desktop session.

The scanner and purchase changes above are code-level guards, not a hands-on macOS verification. No purchase,
media, notification, deep-link or layout runtime behavior was verified in this audit.

## Implementation tracker

Live state of the port, audited against the tree on 2026-07-30 (branch `DESKTOP`, everything
uncommitted). This section supersedes [Suggested order](#suggested-order) as the working list —
that one is the original plan, this is what actually happened.

`[x]` done and seen working — on screen, or covered by a test · `[c]` code complete, **never seen
running**: analyze and tests say nothing about it · `[~]` partially done, the rest named inline ·
`[ ]` not started.

**2026-09-01 — merged `main` (v2.0.7, PRs nc013/nc014).** `main`'s "fluid mode" rebuilt the
glass shell on `liquid_glass_widgets` (`GlassScaffold` + `LiquidGlassBottomNavigationBar`,
replacing this branch's `AnimatedSlide` stack) and standardized every sheet call on
`showAppModalSheet`. Merge rule: keep `showAdaptiveModal` (desktop-adaptive) at every sheet
site; take `main` for its feature refactors (`requireSubscription`, `_LoginBrandColumn`,
Quill editor — this branch's AppFlowy `_AppFlowyEditorSection` is gone). Mobile chrome is now
`main`'s `GlassScaffold`; the `if (isDesktopPlatform)` sidebar/detail-pane branch is untouched.
Post-merge: `flutter analyze` clean, `flutter build macos --debug` ✓, 109/111 tests
(`widget_test.dart` + the commented-out `pom_operator_lists_test.dart` are pre-existing, same
on `main`).

Tree state behind the original audit: `flutter analyze` clean; `flutter test` = 16 passing,
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
- [c] Bottom sheets → dialogs. `showAdaptiveModal` (`functions_set.dart:297`) is the wrapper:
      `showModalBottomSheet` on mobile, centered `Dialog` on desktop, with a focus-independent
      Escape handler and an `isCurrent` guard so nested sub-sheets pop one at a time.
      **~97 call sites across 42 files use it.** The 2026-09-01 `main` merge introduced `main`'s
      own `showAppModalSheet` wrapper (`fluid_sheet.dart` — `showModalBottomSheet` only, no
      desktop branch) at **96 more sites**. Every one of those is a bottom sheet on desktop.
      Not a blind swap: `context` moves from named to positional, scroll bodies need an explicit
      `dialogHeight:` (620 is the common value, from the earlier pass), and any raw
      `DraggableScrollableSheet` at the body root must become `AdaptiveDraggableSheet`
      (`modal_sheet_container.dart` — now also forwards `snap` / `snapSizes`).
      **Sweep complete (2026-09-01).** All `showAppModalSheet` call sites migrated to
      `showAdaptiveModal` across ~90 files — compose, per-note, profile, settings, packs,
      dashboard, wallet, DM, logify, subscriptions, the whole `add_content_view` editor
      (article/curation/video/smart-widget specs, quill editor math/table/image/zap sheets,
      smart-widget templates/drafts/frames), `YNavigator.presentPage` (one generic wrapper →
      26 cashu/wallet flows desktop-adaptive at once; every target verified `drag=0`).
      `main`'s `fluid_sheet.dart` wrapper reduced to a `@Deprecated` forwarder to
      `showAdaptiveModal` — kept (not deleted) so `showAppModalSheet` sites merged from `main`
      later bind to something desktop-correct on arrival instead of silently regressing.
      Method: `context` named→positional; `DraggableScrollableSheet` at a body root →
      `AdaptiveDraggableSheet` (~28 body widgets; `modal_sheet_container.dart` gained
      `snap`/`snapSizes` passthrough); `dialogHeight:` (620 default, 640 editor specs, 560
      short lists) only where the body scrolls, omitted for `mainAxisSize.min` content.
      Cross-checked every swapped body's other call sites — none reaches desktop outside
      `showAdaptiveModal`'s bounded box. `flutter analyze` clean, 117/119 tests (2 pre-existing).
      Not seen on screen: dialog sizing per sheet, Escape-to-close, and especially the
      `presentPage` cashu/wallet cluster — those bodies are page-shaped (`QrScannerModal`,
      `CashuPayView`, `CashuRedeemView`, `CashuTokenDetailsView`) and now render in a 560×720
      box; check for cramping first. Six sheets got `dialogHeight` guessed from file-scoped
      grep on multi-class files (`_YakiNip05Sheet`, `_WalletAddressSheet`, `_MathEquationSheet`,
      `_TableSheet`, `RequestRelayJoin`, `_RelayListRequiredSheet`, `MediaDescription`,
      `_RedeemCodeSheet`) — bounded so they can't crash, but may render taller than needed.
- [c] Escape-to-close on those dialogs has never been seen working — `cliclick` keystrokes do not
      reach the Flutter window, so only the user can confirm it.
- [c] **Content max-width cap.** `kMaxFeedColumnWidth` = 680 (`detail_pane.dart`). In
      `main_view.dart` the single feed column (no detail pane) is clamped to it and centered
      in the panel with `MainAxisAlignment.center`, so a wide monitor gets symmetric glass
      margins instead of edge-to-edge notes. `_PanelScope` is fed the clamped width, so `.w`
      and `largerThan(MOBILE)` inside the feed now compute against 680, not the window — this
      is what defuses most of the remaining `sizer` sites for free. When the detail pane
      *is* showing (panel ≥ 1024pt) the feed keeps its `panel − 520 − 1` width left-aligned
      and the pane stays `Expanded` — unchanged, that path was already verified. Chosen
      strategy: hard cap, centered (not a right-hand gutter). Never seen on screen.
- [~] `sizer`: axis is correct now, but **157 raw `.w` and 53 `.h`** still measure the *window*,
      not the panel — a re-scoped `MediaQuery` does not reach them. They need explicit gating
      site by site; the ones inside the detail pane and the DM columns are the visible offenders.
- [x] **Infinite scroll on desktop.** `AdaptiveSmartRefresher`
      (`views/widgets/adaptive_smart_refresher.dart`) wraps `SmartRefresher`; on
      `isDesktopPlatform` it adds a `NotificationListener<ScrollNotification>` that drives
      `controller.footerMode.value` straight to `LoadStatus.loading` when the feed is within
      400pt of the bottom — that fires the footer indicator's listener, which calls
      `onLoading`, synchronously so a second notification in the same frame sees `loading` and
      bails. Reuses the view's existing `RefreshController` and `onLoading` closure, so
      `loadComplete()` / `loadNoData()` in each `BlocConsumer` still line up. The
      `shouldLoadMore` predicate guards re-entry (`LoadStatus.loading`), end-of-feed
      (`noMore`), nested/horizontal scrollables (`depth != 0`, non-vertical axis) and
      non-scrollable lists (`maxScrollExtent <= 0`). `test/desktop_pagination_test.dart`
      covers the predicate and pumps the wrapper — a fling to the bottom fires `onLoading`
      exactly once (`flutter test` runs on macOS, so the desktop branch is live). Swapped at
      15 call sites: `leading_view`,
      `discover_view`, `media_view`, `profile_view`, `explore_packs_view` (×2),
      `relay_feed_view`, `uncensored_notes_view`, `smart_widgets_view` (view + dashboard ×2),
      `polls_view`, `wallet_view` transactions, `smart_widget_selection`,
      `curation_articles_list`. **Never seen running** — same tooling limit as
      Escape-to-close. Known ceiling (`ponytail:` comment in the wrapper): a feed whose page
      one doesn't overflow the window never triggers; a visible "load more" button is the fix
      if a short filtered list needs it.
      `notifications_view` and `home_dashboard` carry `enablePullUp` with no `onLoading` —
      neither is a paged list, so no change.
- [ ] Refresh affordance (pull-*down*). Same 20 files; `onRefresh` is also mouse-unreachable.
      Lower priority than pagination — stale-but-present beats truncated — but each feed still
      needs a visible refresh button on desktop.
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
- [c] Media viewers open in the pane too: `PictureView`, `VerticalVideoView`,
      `HorizontalVideoView` added to `kDetailPanePages`, so a tap on a media-grid or
      profile-media tile lands in the 520pt pane instead of full screen. The full-screen
      `openGallery` swipe viewer (long-press) is unchanged. Not seen on screen.
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

### 2026-11-04: picture description layout

The desktop picture viewer now remeasures its description against local width
and current text scale instead of measuring the initial window width once.
Focused measurement tests cover width changes, larger text and RTL; existing
divider resize and persistence tests also pass. Targeted analysis is clean.
The running native app was observed read-only in an active thread and was not
restarted. Actual picture rendering, styled links, divider accessibility and
minimum/intermediate window sizes still require native verification.

### 2026-11-04: profile filter pane width

The profile's floating filter width now follows the scoped desktop pane rather
than the window-wide sizer width, and its dropdown buttons fill that bounded
control. Focused Dart analysis passes and `git diff --check` is clean. A
read-only observation of the active native session showed the two-pane layout
with real Know people cards at a wide size; its build could not be established
as current. The profile change, resizing at minimum and intermediate sizes,
large text, and divider keyboard and native accessibility remain unverified.
The active session was not changed or restarted.

### 2026-11-04: article curation dialog sizing

The desktop add-to-curation form now uses standard padding and a bounded image
height instead of sizing them from the window. Focused analysis and
`git diff --check` pass. Native appearance and large text remain unverified.

### 2026-11-04: DM list padding

Desktop conversation-list padding no longer scales with the window width at
larger breakpoints. Focused Dart analysis and `git diff --check` pass. Native
DM layout, resizing and large text remain unverified; the active session was
not disturbed.

### 2026-11-04: additional desktop sizing

DM gift and redeem cards use the message container width, and the gift claim
button is centered in the card on desktop. The bookmark-list editor uses
standard desktop padding, and the fluid profile preview is capped by the
available window. Focused Dart analysis and `git diff --check` pass. Native
appearance, large text and resizing are still unverified.

### 2026-11-04: feed media bounds

Desktop single-image previews are capped at half the window height (up to 420
points) and use contain fit. Embedded media cards use the pane width with a
360-point cap. Gallery and video behavior were not changed. Focused Dart
analysis and `git diff --check` pass; native rendering, sensitive media and
playback remain unverified.

### 2026-11-04: desktop density

Appearance now offers device-local comfortable and compact workspace spacing.
The setting updates representative feed, people-card and header spacing while
preserving comfortable as the previous default. Translations were generated for
all locales. Focused analysis and 11 density/workspace tests pass, including
preference restoration; `git diff --check` is clean. Native visual validation
in solid and fluid themes, hit targets and large text remain open. No native
build was made over the active app session.

### 2026-11-04: desktop note containers

Home feed notes and reposts, and Discover notes, use bordered containers on
desktop in both solid and fluid themes, independently of the fluid-card setting.
Mobile retains its prior behavior. Focused analysis and two widget tests pass;
native appearance remains unverified.

Desktop article cards now use the same container treatment in the workspace,
Discover feed and profile feeds. Focused analysis, container/feed tests and
`git diff --check` pass; native appearance remains unverified.

### 2026-11-04: desktop destinations and inner DM split

Desktop input decorations suppress hover color. Smart Widgets opens in the outer
side pane, and wallet and notifications main-panel content is capped at 680
points. DMs now put the conversation list and selected conversation in an inner
split of the main panel, preserving the outer pane. Desktop message links select
the inner conversation, and selection is scoped to the current account. Focused
layout/navigation tests pass; real conversations, drafts, account switching,
small-window overflow and native appearance still require hands-on validation.

Desktop DM content now shows the conversation list alone below 600 points and
keeps the selected conversation mounted for restoration on wider layouts.
The compact account avatar uses the account switcher action, desktop glass
text buttons have a 44-point minimum matching the default glass icon button,
and workspace/player icons use Lucide. Focused widget tests pass; native visual
checks and real DM behavior remain open.

Desktop fluid text, elevated and outlined buttons now share a 44-point minimum
and standard visual density, so desktop compact density does not shrink their
visible surfaces. The minimum allows larger text to grow. Focused tests cover
all three button styles and large text; login/signup appearance still needs a
native check, including any controls with explicit local size overrides.

### 2026-11-04: gallery, spacing and desktop modals

Desktop gallery navigation now uses page-controller arrows beside the progress
surface; the arrows share its height and stay synchronized with swiping.
Density choices use the same cards as glass quality, Home's content inset is
reduced, and the desktop rail has scroll-edge shading. Desktop load-more is
limited to loaded, nonempty short feeds and hidden during requests. Desktop
adaptive modals draw one complete border around a continuous surface with
vertical padding; their root sheet does not draw a duplicate inner border.
Focused tests pass. Native gallery gestures, modal appearance and live feed
loading remain unverified.

### 2026-11-04: hover and stats sheet

Material hover overlays and sidebar hover fills are suppressed while pressed,
selected and keyboard-focus states remain. Local, licensed copies of
`liquid_glass_widgets` and `pull_down_button` suppress their internal hover
visuals; see `third_party/README.md` for update guidance. The note stats sheet
uses the shared desktop modal surface instead of adding a second border.
Widget tests cover hover, focus, clicks and the common modal surface; native
stats-sheet appearance still needs verification.

### Desktop Home sidebar update (2026-11-04)

The desktop detail pane's base now shows the Home media and suggestion
sections instead of the workspace source selector. Home no longer inserts
those sections in its desktop feed; mobile retains its existing layout. The
pane uses a subtle theme-derived background and retains its nested navigator.
Focused analysis and the pane/navigation tests passed. Native appearance,
live suggestion loading and account switching still require verification.
The desktop sidebar now always shows its sections regardless of feed visibility
settings, with smaller headings, additional spacing and trending notes.

## 2026-11-11 — sidebar and More inventory

Desktop persistent actions: Search opens SearchView; Home selects leading;
Messages selects DMs and retains its mark-all-read long press and existing
signed-in dot behavior; Notifications marks read before selecting its view and
shows the existing unread dot; Compose retains its sign-in gate and menu;
the account footer retains login/account switching. Re-selecting a selected
main view scrolls to the top.

More contains Media, Articles and Wallet (main-view selections; Wallet requests
balance first); Explore packs, Relay Orbits and Settings (pushed routes); and,
when signing is available, Smart Widgets, Profile, Dashboard, Subscription,
Creators Subscriptions, Pricing, Blossom Storage, Yaki Points and Yaki Pro.
Points retains its system-login check and login popup; Yaki Pro opens its
existing external URL. More highlights for the selected secondary main view.
The searchable dialog uses the existing translated labels and the existing
callbacks; it does not add unread counts or change mobile navigation.

Widget fixtures cover search, keyboard activation, Escape and focus restoration,
and a short RTL dialog at 1.5× text. This is not verification of the real
signed-in/out sidebar, onboarding tour, every destination, native rendering,
VoiceOver or extreme-height shell. The running signed-in app was not touched.

Verification: seven focused More/rail widget tests passed and full
`flutter analyze --no-pub` reported no issues using the checkout's `pipress`
Puro environment. A native fixture was not run for this change.

### Sidebar priority follow-up

Media and Wallet returned to the rail, and Settings moved from More to the
fixed footer. The compact avatar uses the same 44-point size as Compose. The
navigation area can scroll at short heights while the footer stays in place.
More groups its remaining entries under existing translated headings and uses
theme colors; the Compose popup has a translucent blurred surface. This
supersedes the preceding inventory's placement of Media, Wallet and Settings.
The signed-in app was not restarted for this change; native visuals remain open.

Compose now uses the actual `GlassMenu` morphing control, replacing the prior
translucent Material popup. Settings has its own rounded theme-colored footer
container. The compact and expanded Compose Escape/reopen widget fixtures pass;
native rendering and full keyboard traversal remain unverified.

## 2026-11-11 — desktop subscription checkout

Desktop pricing now selects the existing external card checkout even when the
mobile IAP build flag is enabled. Existing Lightning and points choices remain
available, while mobile retains the flag's existing behavior. Stripe-managed
subscriptions expose the existing billing and plan controls on desktop; store
restore and store-management actions remain mobile-only. Before desktop card
checkout the client checks the current account and fetches subscription status,
refusing a second checkout for active IAP or Stripe subscriptions. The API also
rejects active IAP checkout, but its existing link endpoint does not provide an
atomic duplicate-Stripe guard. Browser launch failure is reported as failure,
and status is refreshed on app resume and after leaving checkout.

The Stripe and creator-subscription endpoints are existing backend paths; no
backend changes or deployment were made in this work. Fake-account and
fake-browser tests alone do not establish a live Stripe purchase, webhook
delivery, production account session, native browser return, or behavior during
concurrent checkout requests. The user confirmed on 2026-11-11 that Stripe
checkout is done; the confirmation did not specify the test conditions or
webhook details. The duplicate-Stripe concurrency guard remains a separate
backend concern.

Compact profile follow-up: the account action retains a 44-point hit area, but
its visible avatar is centered at 36 points so it no longer appears larger than
the adjacent controls. The earlier 44-point avatar note is superseded. Widget
layout checks cover the action and image bounds; native appearance is unverified.

Compact profile correction: the visible avatar and adjacent compact buttons are
44 points; the avatar remains centered in its 44-point action. This supersedes
the previous 36-point adjustment. Native appearance remains to be checked.

### Desktop search focus ring

The desktop glass search field suppresses the blue focus ring while retaining
text focus and keyboard input. A disposable widget fixture verifies typing and
that the ring painter is absent. Mobile retains the package default. The running
app was not restarted; native appearance remains unverified. Focused analysis of
the vendored field reports ten existing informational lint findings.

### Sidebar and tour fixture follow-up

The desktop rail now exposes tour targets for Search, Home, Media and the
signed-in account action. Before focusing a desktop tour target, the tour
reveals it in its scrollable viewport and recalculates the card's vertical
placement. The signed-out login is not presented as a profile target.

Disposable assembled-sidebar fixtures verify signed-out Home reselection,
Media, Notifications, Wallet and Articles selection and their mocked side
effects, as well as signed-in More inventory and account target presence. A
separate short-scroll fixture verifies target reveal. Together with the existing
More, rail and shell keyboard fixtures, 16 focused tests pass. These fixtures
use fake cubits and signers: real destination pages, full tour progression,
native rendering, VoiceOver and live account behavior remain open. The active
signed-in app was not touched.

### Completion confirmation

On 2026-11-11 the user confirmed the desktop shell baseline and Stripe checkout
are complete. The earlier native shell observations above remain the recorded
evidence; individual edge-case coverage and Stripe test conditions were not
specified. Do not repeat the completed baseline as outstanding work.

### Scope decisions — 2026-11-11

The user confirmed sidebar and navigation verification is complete. Planned
pin/reorder, command search, shortcuts, context-menu expansion and the optional
multi-column deck are removed from scope. Historical open-status notes above
are superseded for these items. Native reliability remains the active work.

### Native reliability check — 2026-11-11

The locked `awesome_notifications` 0.10.1 macOS implementation still returns
`FlutterMethodNotImplemented` for notification methods. Desktop now skips the
local notification manager's initialization and delivery, and DM and
notification cubits default to no system alerts and skip permission, badge and
DM delivery calls on desktop. Mobile paths retain their prior behavior. A
focused disposable manager fixture passes and focused Dart analysis reports no
issues. This is a fail-safe, not a macOS notification implementation; native
alerts and their settings remain unresolved.

Code inspection confirms the three QR scanner views gate camera widgets to
mobile and show a desktop fallback. Desktop subscription controls retain their
platform gates. These are code-level findings, not native device tests.

The desktop shell omits the mobile app bars that display connectivity status;
its `isConnected` value reflects device connectivity rather than individual
relay health. Offline/partial-relay feedback therefore remains open. The
running-link handler recognizes Nostr Wallet Connect and Alby links, but the
initial-link path explicitly skips them and no other initial-link handler was
found. Cold wallet-link behavior remains unresolved; no link was opened and no
wallet operation was performed. NIP-46, real uploads, exports, media and native
notification permission/delivery still need safe native fixtures and actual
verification. The running signed-in app was not disturbed.

### Reliability scope update — 2026-11-11

Per user direction, macOS system notifications are not needed and are removed
from the remaining scope. The existing guard against unsupported plugin calls
remains. Connectivity and links are the active work; after they are fixed, the
next stage is cross-platform release readiness. Earlier broader Phase 4
open-work lists are superseded by this scope.

### Link lifecycle continuation — 2026-11-11

The app_links stream supplies both the initial and later links. MainCubit now
subscribes once instead of separately reading the latest link, so cold wallet
URIs enter the same handler as running URIs without that duplicate path. Wallet
handling waits for wallet initialization and checks the signer is unchanged;
signed-out wallet links are ignored and remain an open case. Alby callback
classification checks the actual host and path. Two disposable stream and
classification tests pass, and focused Dart analysis passes. These tests do
not establish native cold/running delivery, navigation, wallet callback behavior,
or reconnection. No links were sent to the running app and no wallet operation
was performed. Device/relay status and offline/reconnect behavior remain open.


### Device connectivity continuation — 2026-11-11

The connectivity repository now initializes and periodically refreshes device
interface availability, accepts VPN and other interfaces, emits only changes,
and discards an initial check superseded by a newer platform event. DNS lookup
is separate and cannot overwrite interface state. Two disposable fake-platform
tests pass. This signal does not establish Internet access or relay health; its
initial boolean still cannot represent unknown, and desktop status, relay
feedback and native offline/reconnect behavior remain open. The running app was
not used.


### Narrowed desktop reliability continuation — 2026-11-11

The user removed wallet-link work and requested that relay reconnection remain
simple. No relay dependency change was applied. The desktop rail reports device
interface availability separately from the count of configured relay sockets
that are open. A platform error makes the interface status unknown; DNS failure
does not change it. This is interface and socket status, not a guarantee of
Internet access, relay authorization, event delivery, or fresh feed content.
A widget fixture covers unknown, offline and available interface states alongside
a synthetic relay count. Unsent events now remain queued when a retry fails,
and an empty relay list uses the normal fallback; a mock-storage/fake-sender test passed without sending
an event. Existing reconnect behavior remains in place.

A loopback-only experiment in a disposable dependency copy exposed duplicate
connection behavior during close/reopen. Its proposed dependency changes were
not applied following the user's instruction; live relay recovery and active
subscription continuity are not verified.

The app now starts its link inbox before app initialization and attaches it
after the main view is built. In an isolated macOS debug app with a distinct
bundle ID, no URL registrations or shared keychain group, two synthetic Nostr
URLs were delivered by explicitly targeting the fixture: one cold launch and
one while running. A fake-stream test covers buffering before view attachment.
This does not verify OS default-handler selection, actual content navigation,
or live relay lookup. Wallet links are out of scope.

A separate fresh macOS debug fixture with the same isolation used the real
NotesEventsCubit, synthetic reply stats and a small view that retains/releases
the open ID. Eviction preserved the reply while retained; after release and
marking the other entries recent, a later prune evicted it. The first attempt
assumed deterministic order for equal access times and failed; the corrected
fixture controlled recency and passed. This is not an end-to-end NoteView or
real-content test. The running signed-in app was not used. Focused tests and
analysis passed, and the updated app source built in the isolated copy.


### Cross-platform implementation start — 2026-11-11

The user accepted the preceding device/relay, Nostr-link and cache work as
complete for the plan; its actual verification limits remain above. Windows
and Linux are now active scope. Wallet links, system notifications and the
deck remain out of scope.

Current generated plugin metadata was checked against the lockfile using
Flutter 3.44.9 / Dart 3.12.2. Windows includes app_links, connectivity_plus,
flutter_inappwebview_windows, secure storage, file selection and URL launcher.
Linux includes app_links_linux, GTK, connectivity_plus, secure storage, file
selection and URL launcher. Registration alone does not prove runtime support.
The locked video_player, just_audio and webview_flutter do not provide the
embedded Windows/Linux implementations used by these screens. The main audio,
video, YouTube and Smart Widget paths now present an explicit browser fallback;
Linux Google sign-in displays an unavailable message and Linux embedded X
posts provide a browser action. Disposable simulated-platform widget tests
cover these paths without opening external links. Other editor/media paths
still need audit and native verification.

The Linux runner now uses the installed GTK plugin's command-line and single
instance setup; a startup argument is queued with a short duplicate guard, and
a desktop-entry template is provided. The Windows runner forwards `nostr:`
arguments to an existing window using the app_links 6.3.2 message contract; a
per-user protocol registration script is provided for installer integration.
No OS handler or registry entry was installed. Unit fixtures cover Linux
startup delivery and deduplication; neither native runner was built or run on
its target platform. Flutter on this host is macOS and no Linux container
daemon or Windows compiler was available.

An isolated macOS debug build of the updated shared code passed; it used a
separate app identity and empty fixture configuration. Focused cross-platform
and existing desktop media tests passed, and repository-wide Flutter analysis
reported no issues. Windows/Linux builds, window sizing,
DPI, file dialogs, clean-machine storage, protocol registration, package
installation, signing, notarization and release smoke tests remain open. The
tracked `.github/workflows/desktop.yml` currently uses unpinned stable Flutter,
does not check out the sibling Nostr dependency or restore `.env`, omits Linux
libsecret/GStreamer development dependencies, and does not perform the stated
obfuscation/symbol upload. Its release artifacts must not be treated as release
readiness evidence until that workflow and its credentials are addressed.

### Cross-platform audit continuation — 2026-11-11

The Windows and Linux local-video composer previously constructed
`VideoPlayerController.file` despite the missing platform player. It now shows
existing translated playback-unavailable text without starting the player; video
trim and compression controls are hidden on those platforms, while selecting a
thumbnail and uploading the original remain available. `pro_video_editor` does
register Windows/Linux implementations, but its editor also requires the absent
player; metadata extraction is already caught on failure. This is a simulated
platform check, not an end-to-end upload or native editor verification. Other
editor, thumbnail, camera, clipboard and media paths still require a complete
call-site and native audit.

Network image and video saves now use the registered file-selector save dialog
on Windows/Linux; cancellation leaves no output and video temporary files are
cleaned up. Generated-image and Blossom downloads still explicitly report
unavailability on those platforms; key and wallet export paths need a separate
security-conscious audit and were not exercised. Native dialog behavior,
overwrite handling, write permissions, and paths with spaces are not verified.
Linux secure storage registers a libsecret backend and requires a working
Secret Service; Windows registers secure storage. Neither clean-machine startup
nor locked/unavailable keyring recovery was tested.

Link inspection: Linux `gtk` strips the executable from remote command-line
arguments and `app_links_linux` forwards the first argument; the local initial
argument is buffered separately. The time-based duplicate suppression can also
suppress an intentional identical link received during its initial three-second
window. Windows uses the plugin's `WM_USER + 2` UTF-8 `WM_COPYDATA` contract;
window discovery and a successful message send do not prove the plugin listener
was ready, especially during startup. The Linux desktop entry and Windows
per-user registry script are inputs only; handler registration, installer
integration, cold and running delivery, duplicate and lifecycle behavior remain
unverified on the target systems. No system registration was performed.

The Windows runner declares per-monitor V2 DPI awareness and responds to
`WM_DPICHANGED`; Linux and Windows start at 1280×720 with no native minimum
constraint found. Their scaling, minimum usable size, keyboard and accessibility
behavior require native testing. Do not infer target validation from macOS or
widget fixtures.

The desktop GitHub Actions workflow is now manual and uses Flutter 3.44.9 and
the same pinned Nostr sibling revision as the mobile release workflow. It
requires `APP_ENV` in a `desktop-build` environment, installs Linux libsecret
and GStreamer development dependencies, enables obfuscation and saves unsigned
build candidates and symbols as short-lived artifacts. It has not been run;
runner availability, lockfile enforcement, plugin compilation, symbol output
and dependency coverage are unverified. `.env` is a bundled asset, so GitHub
Secrets only protect its delivery to CI: values in the app are extractable by
recipients. Use only distributable client configuration in `APP_ENV`, protect
artifact access, and never put private credentials there. This workflow does not
upload symbols to GlitchTip, create installers, sign, notarize, or publish.

Release engineering remains open: define and test a Windows installer or MSIX
with opt-in Nostr registration, WebView2 prerequisite, Authenticode signing and
safe uninstall; define a Linux package with executable/desktop-entry/icon
placement, shared library and GStreamer runtime dependencies, Secret Service,
package signing and non-destructive handler selection. macOS release settings
currently specify automatic Apple Development signing and a keychain access
group; distribution identity, entitlements, hardened runtime, notarization,
stapling, update delivery and GlitchTip symbol upload need a real release
pipeline and verification. No package, certificate or release action was used.

Verification for this continuation: repository-wide `flutter analyze --no-pub`
reported no issues; 11 focused link, local/network media, webview and Smart
Widget tests passed; `git diff --check` passed. The first local-video test run
failed because the fixture reset the platform override too late; after fixing
fixture cleanup, the selection passed. These tests do not exercise native
file dialogs or the workflow. No native Windows/Linux host was available, and
the running signed-in app was not touched.

### File-save and storage audit continuation — 2026-11-11

Generated-image and Blossom downloads now use the registered Windows/Linux file
selector, sharing a byte-save helper with network-image downloads. A fake
selector and disposable temporary directory verify cancellation, exact bytes, a
path containing spaces and propagation of a write failure. The callers retain
their localized success/error handling. The actual OS dialogs, overwrite
confirmation, permissions and downloads remain untested on native targets.
Windows video-thumbnail source filtering now recognizes drive-letter and UNC
paths while rejecting URLs; a pure path-classification test passes. Actual
Windows thumbnail creation and codecs remain unverified.

Camera enumeration is gated to mobile in startup; Linux image picker delegates
gallery selections to file_selector but requires a camera delegate for camera
selection. The Windows/Linux picker, clipboard, editing and playback call-site
audit and native checks are still incomplete.

**Secure-storage release blocker:** `LocalDatabaseRepository` catches secure
read errors as missing values and catches write errors without reporting them.
`SettingsCubit.init` treats missing account maps as empty; account addition
then updates in-memory maps and proceeds after writes whose failure was hidden.
An unavailable or locked Secret Service or a Windows storage error could thus
appear as missing accounts or an apparently successful but non-persistent
sign-in. Recovery must distinguish unavailable storage from an empty store,
prevent overwriting data based on a failed read, surface write failure before
confirming account changes, and handle the multiple related maps consistently.
This needs dedicated disposable fault-injection tests and a startup/authentication
flow design; it was not changed or tested with the user's account.

Verification: repository-wide `flutter analyze --no-pub` passed, eight focused
save, thumbnail-source, deep-link and local-video tests passed, and
`git diff --check` passed. These are host-side tests with fake or simulated
platforms; no Windows/Linux native build or app session was run.

### Account-storage foundation — 2026-11-11

An isolated, currently unused `AccountSnapshotStore` prototypes reading the
five legacy account maps without writing during migration and saving them as a
single versioned secure value. Disposable in-memory fault injection covers a
failed legacy read, a failed write, and malformed snapshot data. These tests
assume the fake backend does not change a value when a write fails; they do not
establish atomicity or failure semantics of any native secure-storage backend.

**The secure-storage release blocker remains open.** Production initialization
and account mutations still use the old methods. Integration must address the
active account index stored separately in preferences, serialized account
changes, startup and localized recovery, sign-in and logout error handling,
legacy migration and downgrade behavior, and remote signer data. It must not
assume that a failed native write left the old value intact. Native locked and
unavailable keyring behavior remains unverified. No account data or running app
was accessed for these tests.

The user subsequently approved applying the eventual safe account-storage
handling to Windows and Linux, with Linux-specific keyring guidance, while
leaving mobile and macOS behavior unchanged. The unused prototype now refuses
concurrent operations and requires a successful reload following any failed
write, including a simulated write that changed the value before reporting an
error. Four disposable fault-injection tests pass. This does not integrate the
prototype or resolve the production release blocker.

The prototype was extended to carry the active index and remote signer data in
the same value and to fail if the legacy signer read fails. Six disposable
tests and focused analysis pass. It remains unused by production; native write
semantics, migration, recovery UI, and integration are still unverified.

### Desktop account-storage integration — 2026-11-11

The Windows/Linux settings path now reads a versioned account snapshot using
the existing secure-storage backend. It loads legacy account maps without
writing at startup, includes the active account and remote signers in the
snapshot, and saves it before applying account addition, switching or removal.
Failed reads show a localized retry screen (with Linux keyring guidance).
Failed or uncertain writes report an error and require an app restart before
another account change. Legacy entries are removed only after snapshot
write/read verification; cleanup can resume after interruption. Mobile and
macOS retain their existing storage path.

The new format is not readable by older app versions after migration. Changed
legacy account entries are detected and block initialization, but an older
version may see no accounts after cleanup, and its active-account selection
cannot always be distinguished from stale preferences. Do not downgrade a
migrated desktop profile without a separately verified account backup and
recovery process. Snapshot verification does not prove crash durability,
cross-process exclusion, or OS backend behavior. Native Windows/Linux builds,
locked keyring and real account migration remain untested; the desktop release
blocker remains open pending those checks. No real account was accessed.
Repository-wide Flutter analysis and 14 disposable account-storage tests pass;
the tests include a successful removal and injected read, write and cleanup
failures. The retry screen and native secure-storage providers were not tested
end to end.

### Account-storage review continuation — 2026-11-11

Review found that legacy values could change after the initial read and be
deleted by migration cleanup. Saving now checks the legacy hashes again, and
cleanup checks them before starting and before deleting each value. A changed
value blocks the operation and is retained. This is still not cross-process
locking: another process could write between the final check and deletion.
Avoid concurrent app versions and retain an independently verified backup.

The settings cubit now rejects overlapping Windows/Linux account changes until
the preceding change has finished applying its in-memory state. If a later step
throws after a successful save, further changes require restart. Disposable
tests cover overlapping removals, changed legacy values before and during
cleanup, and a removal whose write took effect before reporting failure; the
restart fixture loads that persisted outcome. Existing fixtures cover failed
reads, failed additions/removals, switching after a failed save, interrupted
cleanup and restart. These use in-memory storage and synthetic account strings;
they do not establish native durability, atomicity or keyring behavior. The
retry screen, successful live account switching, remote signer lifecycle and
removal, and native locked/unavailable Linux Secret Service remain unverified.
Removing a single account currently retains its remote signer record in the
snapshot; review and test its lifecycle before release.

The downgrade limitation remains: an older build cannot read the snapshot and
may show no accounts after cleanup. Legacy hash checks detect some subsequent
changes, but cannot protect against every older-version or concurrent-process
scenario. The Windows/Linux secure-storage release blocker remains open.

On this macOS host, 22 focused storage and deep-link tests and focused analysis
passed using Puro `pipress`; `git diff --check` passed. Flutter aborted inside
the sandbox, so these commands ran outside it. Docker had no usable daemon and
no Windows/Linux target host was available. The running signed-in app and real
account data were not used. Link runner inspection still leaves the Windows
listener-readiness race and Linux initial-link deduplication ambiguity open;
native window minimums, scaling, plugin fallbacks, packaging and installation
remain unverified as described above. No protocol handler was installed.

### Remote signer and recovery continuation — 2026-11-11

On Windows/Linux, removing an account now saves a snapshot without its remote
signer before removing and closing that signer in memory. Removing all accounts
also closes the in-memory remote signers after saving. A disposable signer test
checks that a failed write keeps the account and signer and that a successful
removal persists without the signer. Remote login on those targets now waits for
the login success callback before reporting success; a full account list also
does not proceed as a successful login. Mobile and macOS retain the previous
remote-login path. This is not a native or end-to-end remote-signer test.

`DESKTOP_ACCOUNT_RECOVERY.md` describes a proposed backup and recovery
validation procedure and the downgrade restrictions. It is not a verified
recovery guarantee. A protected, independently restored backup and each actual
account recovery method must be validated on the target systems before release.

The host is macOS; Docker has no usable daemon, and no Windows compiler, Linux
host, desktop-file validator, or PowerShell was available. The packaging inputs
and workflow remain unexecuted; no package or protocol handler was installed.
The previously documented Windows forwarding race, Linux duplicate ambiguity,
native window sizing and scaling, keyring recovery, plugin behavior, installer
and clean-machine checks remain open. Simulated storage, link, media, webview,
Smart Widget and file-save fixtures passed; these do not substitute for target
OS testing. No user account, wallet or running application was used.

### Native implementation continuation — 2026-11-11

Windows Nostr forwarding now waits for a readiness signal from the Dart link
subscriber and expects an acknowledgment from the existing window. On timeout
or failed forwarding it exits instead of opening a second app against the same
profile. The five-second timeout can reject a link while startup is slow; there
is currently no user-facing retry message. This path, message ordering, window
discovery and multiple rapid links have not been built or tested on Windows.

Linux now suppresses the primary local Nostr command at the GTK signal source,
because that argument is already passed to Dart at startup. Remote command
lines are left to the plugin, so a deliberately repeated link is not removed by
a time window. The Dart fixture checks repeated stream events, not the GTK signal
contract; native cold/running delivery and remote links arriving before the Dart
plugin listener is ready remain unverified. Neither platform has an installed
handler as a result of this work.

Windows and Linux runners now specify provisional 1153 × 600 logical minimums,
matching the existing macOS value. Per-monitor Windows DPI and GTK geometry
hints are used. Actual client area, display scaling, window manager behavior,
small displays, accessibility and usability remain unverified on target OSes.
Windows/Linux media selection sheets hide camera choices that have no configured
picker delegate and retain gallery/file selection. A simulated-platform widget
fixture covers the shared selector; the other sheets and actual dialogs still
need native verification.

An Inno Setup definition and a Debian candidate builder have been added under
the platform packaging directories. They are unsigned, unbuilt definitions and
do not register handlers, install prerequisites, sign, or publish. The Debian
dependency list and placeholder maintainer need review; WebView2, package
upgrades, uninstall, platform prerequisites, signing and clean-machine behavior
remain open. No package was created or installed. The snapshot still lacks
cross-process exclusion and a product-supported downgrade migration; do not
consider the recovery procedure a verified guarantee.

Fourteen focused link, selector and fallback tests passed after correcting a
missing import in the first test run. Focused analysis, shell syntax validation
and `git diff --check` passed. No Windows/Linux native compilation or run was
available, and no signed-in app, account, wallet or network publication was used.
