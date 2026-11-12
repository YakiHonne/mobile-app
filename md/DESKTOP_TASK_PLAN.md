# YakiHonne Desktop: Implementation Task Plan

**Created:** 2026-11-03  
**Companion:** [Desktop product assessment](DESKTOP_PRODUCT_ASSESSMENT.md)  
**Current implementation evidence:** [Desktop implementation audit](DESKTOP_IMPLEMENTATION.md#current-audit--2026-11-01)

This is a proposed, ordered backlog. Unchecked items are not claims of existing
behavior. Do not treat older implementation-tracker entries or plugin support
tables as current release evidence. Preserve the existing uncommitted work and
recheck the branch, diff, docs and actual dependency versions before starting.

## Working rules

- Start with macOS using `/Users/MAC/.puro/bin/puro -e pipress`; prior Dart and
  Flutter checks required escalation. Do not remove or replace existing changes.
- Retain the user's permanent side pane and route desktop pages into it. The
  conversation list is in the main pane and its open conversation in the side
  pane. The user requested usable desktop minimum width; validate rather than
  continually increasing the limit without testing real displays.
- Preserve mobile behavior. Read `md/DESIGN_GUIDELINES.md` before UI work. The
  root `GLASS_IMPLEMENTATION.md` was absent at assessment time; check again
  before modifying fluid mode. Do not edit the older snapshot as a substitute.
- Edit source locale JSON and regenerate slang translations when adding text;
  never hand-edit generated translation files. Cover at least English, a long
  translated label and an RTL locale during visual checks.
- Prefer focused, meaningful tests for navigation, state and layout contracts.
  Run relevant tests and analysis, then a macOS debug build. Native behavior
  needs manual verification; write the actual outcome and test environment into
  the current audit. The stock counter `test/widget_test.dart` is known stale;
  report pre-existing failures rather than presenting a partial run as a full
  suite.
- Protect account-scoped and private data. Never publish an event, spend funds,
  upload a user's file or export a private key merely to obtain test data;
  use explicit disposable fixtures or a user-directed test account.

## Starting state and dependencies

2026-11-03 continuation: branch, status, diff, local inputs and root glass
guide were rechecked. The existing YakiHonne session was left running; no fresh
native baseline was established. Pending desktop video play intents are now
invalidated across account changes, with a fake-platform loading regression
test. YouTube embeds now coordinate desktop pauses with managed video while
mounted, but are not retained in the bar. Local editor previews now also join
pause coordination and have desktop play/pause controls. Both need native
verification, and neither is retained in the bar.

2026-11-03 slice: branch and existing diff rechecked; `.env` and both sibling
path dependencies are present. Puro `pipress` supplies Flutter 3.44.9 and Dart
3.12.2. The root glass guide is still absent. No test account or disposable
fixtures were established, so the native baseline remains open.

- [ ] Recheck the current audit and run/build state; identify any changes made
      since this plan was written. The existing checkout was `DESKTOP`, 60
      commits ahead of `origin/DESKTOP`, with extensive uncommitted work.
- [ ] Confirm both local path dependencies and `.env` are present without
      printing secrets. Record Flutter/Dart versions from the requested Puro
      environment. Confirm root glass guidance exists or document its absence.
- [ ] Establish a manual test account, relay access and non-sensitive media
      fixtures. Do not assume a connected wallet, Blossom server, or newer
      article event is available.
- [ ] Define a short, reproducible baseline: start app, minimum and wide window,
      Home → note → back, DMs → conversation, Search, Compose and Settings.
      Record screenshots or observations with theme, window size, build and OS.

## Phase 0 — Stabilize and measure the current shell

**Desktop shell baseline: complete**, based on the user's native verification
and confirmation on 2026-11-11. The narrower unchecked cases below are optional
follow-up coverage, not a requirement to repeat the verified baseline.

- [x] Verify the desktop shell baseline: navigation and return, DM switching,
      draft retention, same-account refresh, side-pane recovery, compose and
      settings at narrow and wide widths, pane dragging/reset, window behavior,
      VoiceOver, appearance/language and media.

2026-11-11 user verification: the user reports that navigation and return, DM
switching, draft retention and same-account refresh, side-pane recovery, and
compose/settings at narrow and wide widths worked. During an account switch,
an open note draft remained in the editor; after closing and reopening the
editor, the draft was gone, which the user considers correct. The user
confirmed that the open draft remains visible under the second account. This is
the user's accepted behavior for that editor, and means an open draft is not
isolated across accounts. The active signing identity and other account-scoped
data were not explicitly verified; the individual routes and offline cases
exercised were not enumerated.

- [x] Exercise same-key refresh, account change and sign-out against the
      detail pane with disposable signers and a text draft. Real account
      switching, nested dialogs and persistent drafts remain unverified.

**Outcome:** establish a trustworthy baseline before layering a workspace on
top of the recent navigation changes.

- [ ] Verify the latest built macOS app actually enforces its minimum and
      restores an older saved window safely. Test fullscreen, display changes,
      a smaller laptop display, text scaling and the rail's collapse transition.
- [ ] Exercise navigation entry points from the rail, feed, search, profile,
      DM, modal, deep link and account switch. Cover named routes, builder routes,
      direct pushes, replacements, Back/Escape and a dialog above a pane route.
- [ ] Verify a DM switch replaces the prior conversation without stale active
      notification suppression; return from a profile/media view to the correct
      conversation. Verify per-account drafts and account isolation.
- [ ] Verify that account changes clear another account's pane, while metadata
      refreshes for the same account do not close an editor or lose a draft.
- [ ] Exercise note, article, media and widget compose, plus wallet/settings,
      at minimum and wide widths. Check dialogs and publish/save transitions;
      do not publish or transact without an explicit test setup.
- [ ] Test fluid and non-fluid themes, large text, a long translation and RTL;
      record overflows, unresponsive controls and nested navigator failures.
- [ ] Triage findings by impact, fix blockers before Phase 1, and update the
      audit with observed results. Keep historical claims visibly historical.

**Exit:** no known data-loss, cross-account, wrong-route or blocking layout bug
in the baseline flows; remaining findings have reproduction and ownership.

## Phase 1 — Give the side pane a useful default

Latest update: Notifications and Bookmarks were removed from the pane selector;
Discover and Following remain. Following now presents more profile detail where
available. Earlier source lists below describe historical states.

2026-11-03 redesign: the user rejected the Following notes source and the pane
header. Following notes was removed. Discover now provides topic shortcuts and
trending note previews, with a compact source pill for switching to people,
notifications or bookmarks. Verify its visual treatment, content, empty and
offline states, and account behavior in a fresh native session.

Earlier 2026-11-03 continuation (superseded): Following · Notes was an optional pane source with
independent state and one short-lived query core per request. Pagination
overlaps the boundary second and detects full duplicate pages, but relay ordering
within that second is not guaranteed. The query helper can suppress transport
errors, so offline and empty are not reliably distinguished. Verify relay
lifetime, overlapping requests, account changes, moderation updates, resource
use and rendering on a real session before considering this phase complete.

2026-11-03 follow-up: the base now offers an account-specific saved choice of
Following people, notification history, or bookmark lists. Visited choices stay
mounted when switching, preserving their scroll positions. Notifications reuse
the existing data owner without sharing its tab or scroll controller; bookmarks
own a pane-scoped cubit. This is not yet a Following notes feed, arbitrary feed
selection, or a live/native verification of notification and account behavior.

2026-11-03: the pane now starts with a cached, account-scoped Following people
list and Search, retained as the nested navigator's bottom route. Visible rows
request profile metadata; it starts no feed subscription. A Following notes feed remains open work: Home's `LeadingCubit` owns the shared
source, refresh, pagination and feed lifecycle; its view also starts suggestion
and ad work. A second `LeadingView` would not be an independent Following feed.
The list has signed-out, loading and empty fallbacks; offline and cache errors still need clearer treatment. The pane
stack survives ordinary desktop tab changes; signer changes currently pop it to
the base, while same-signer metadata updates leave it alone. Draft retention and
account switching still require native verification, including pop transitions.

**Outcome:** the side pane has an intentional default and returns to it after
temporary detail navigation.

- [ ] Map `MainView`, `DetailPane`, `YNavigator`, relay subscriptions and
      existing feed cubits/controllers. Identify which state is global and which
      must be independent for two simultaneously visible feeds.
- [ ] Design a pane-scoped source and state contract: account, source, filters,
      selected item, loading/error status, independent scroll, pagination,
      refresh, cancellation and disposal. Reuse cached data where safe.
- [ ] Build the signed-in Following default as a distinct pane experience.
      Provide a clear signed-out/empty/offline state and an action to choose an
      available alternative. Do not require a new account or server.
- [ ] Preserve the base pane and its scroll position when opening and closing a
      thread, profile, composer, settings or other page. Preserve the main feed
      independently. Specify navigation behavior when DMs are selected.
- [ ] Test the same account/source in both panes without attaching a single
      `ScrollController` twice, clobbering cubit state, duplicating notification
      side effects, leaking listeners or creating uncontrolled relay requests.
- [ ] Add meaningful widget/state tests for base → detail → back, independent
      scrolling, refresh/pagination, empty/offline/error, account changes and
      disposal. Verify live behavior and resource usage on macOS.

**Exit:** useful default or actionable fallback on first open; selecting and
closing details reliably restores both pane positions and state.

## Phase 2 — Pane sizing and content layout

### Remaining work

The user reports that pane/divider, window, VoiceOver, appearance/language and
media checks worked, and confirmed the divider highlight is gone. The precise
build, display configuration and individual cases were not recorded. The open
items below cover remaining matrix detail and account-specific behavior rather
than negating those successful checks.

- [x] Complete the pane-local sizing audit and fix confirmed desktop issues,
      with targeted layout tests.
- [ ] Validate provisional pane minimums and divider behavior with real content
      and native fullscreen, display, pointer and accessibility checks.
- [ ] Verify desktop density and real feed media in the current native build.
- [ ] Complete localization, large-text and solid/fluid visual checks across
      minimum, intermediate and wide windows.
- [ ] Visually check phone and tablet behavior for changed shared widgets.

- [x] Make desktop Cashu deposit input, Lightning payment, eCash send, swap and
      nutzap forms scroll in short dialogs, with wrapping SATS/fiat labels.
      Disposable fixtures cover entry, scrolling and the Lightning address step
      at 1.5× and 2× text in LTR and RTL. Native rendering, real wallet/mint
      data and actual operations remain open.

- [x] Make the desktop Smart Widget checker use local pane width for its layout
      and sliding preview; cover resizing and the empty preview with a disposable
      large-text fixture. Real Smart Widget content and native visuals remain open.

- [x] Bound and scroll the desktop Cashu deposit invoice and make desktop send
      and receive choice sheets scroll. Disposable short-dialog fixtures cover a
      mocked invoice and both choice sheets. Real wallet flows, scanning and
      native visuals remain open.

- [x] Bound and make the desktop Cashu operation-result sheet scrollable;
      a non-redeemable placeholder fixture covers its QR and close action.

- [x] Bound the desktop zap invoice dialog and amount-entry dividers to local
      space; a short-window placeholder QR fixture covers the dialog layout.

- [x] Bound desktop receive and zap invoice QR codes to their local width.
      Shared sizing is tested with a disposable placeholder; full invoice
      screens and native scanning remain verification work.

- [x] Exercise the desktop poll chooser in a short 2× text fixture, including
      scrolling. Real poll navigation and native rendering remain open.

- [x] Exercise the desktop article image-selector actions in a short, narrow
      fixture at 2× text. Native rendering and real image selection remain open.

- [x] Exercise the desktop calendar's visible horizontal scrollbar with a
      mouse in LTR and RTL disposable fixtures. Native input and translated
      calendar layouts remain unverified.

- [x] Exercise divider dragging with independently scrolled disposable panes
      and an unfinished text draft. Real content and native resizing remain open.

- [x] Exercise the shared desktop date picker in a short, narrow disposable
      fixture with enlarged text and its clear action. Native scrolling, date
      selection, translated labels and RTL remain open.

- [x] Exercise desktop media choices and a scrollable Smart Widget preview in
      narrow disposable fixtures. Real tools, media selection, native visuals
      and mobile/tablet visual checks remain open.

- [x] Exercise desktop bookmark title entry in a disposable 320-point,
      1.5× text fixture. Real bookmark lists and the article table editor
      still need native layout and interaction checks.

- [x] Exercise desktop profile QR bounds across narrow and wide fixture sizes,
      and an offline retry/long-text fixture. Real profile and empty-state
      rendering, QR scanning, native visuals and RTL remain unverified.

- [x] Exercise a desktop notification selector and the image-selector
      empty/placeholder history in disposable 320-point, 1.5× text fixtures.
      Wallet/inbox headers, real image history, native rendering and long
      translated labels still require verification.

- [x] Exercise divider semantics and invalid persisted values in widget tests;
      native VoiceOver, actual content and measured pane minimums remain open.
- [x] Cover shared desktop scanner fallback, revenue split and share QR at
      320 points with 1.5× text; the QR fixture also uses RTL direction. Real
      sharing, native visuals and phone/tablet visual checks remain open.

- [x] Exercise desktop article relay choices in a 320-point disposable widget
      fixture with 1.5× text and a tap. Desktop uses fixed padding and one
      column; native rendering, real relay data and RTL remain unverified.

- [x] Cover the desktop curation drag handle and adjacent delete action with a
      disposable narrow-width widget fixture. This does not verify the real
      curation data flow or native dragging.

2026-11-05: desktop curation editing uses a single-column reorderable list and
a separate drag handle, avoiding the nested two-column grid at narrow widths.
Phone and tablet routing is unchanged. Focused analysis and existing desktop
layout tests pass, but curation dragging, deletion and native visuals remain
unverified.

2026-11-05: curation, video and Smart Widget content and specification screens
use fixed desktop padding, retaining their existing phone and tablet branches.
Focused analysis and existing desktop layout tests pass; these tests do not
render the editors. Native visuals, large text and the curation grid at narrow
widths remain open.

2026-11-05: article publishing details and the article image selector action
row use fixed desktop padding rather than padding based on the full window.
Focused analysis and existing desktop layout tests pass; article-specific
native and large-text checks remain open. Mobile and tablet branches are
unchanged.

2026-11-05: the paid-note sheet uses desktop-local padding and alert sizing,
and caps its square invoice QR at 320 points within the available width. Phone
and tablet sizing paths are unchanged. Focused analysis and existing desktop
modal/control tests pass; these tests do not exercise the invoice. Native
layout, large text and QR scanning still need a safe fixture.

- [x] Profile floating filter sizing: the filters use the scoped desktop pane width
instead of the window-wide `50.w`; the notes, media and other filter buttons
fill that bounded control. Focused analysis passes. This has not been checked
in a current native build, including at large text sizes.

2026-11-04: the desktop picture viewer now recalculates its description
truncation indicator for local width and text scale; focused measurement tests
cover resizing and RTL. Native picture rendering and divider accessibility
remain unverified; the active app session was not restarted.

**Depends on:** Phase 0 and the pane-state contract in Phase 1.

2026-11-04: the article-to-curation dialog uses bounded desktop padding and
image height instead of window-sized `15.w` / `20.h`. Focused analysis passes;
native dialog layout and large text remain unverified.

2026-11-04: the desktop DM conversation list uses standard horizontal padding
instead of window-wide `20.w` at larger breakpoints. Focused analysis passes;
native DM layout and resizing remain unverified.

2026-11-04: desktop DM gift and redeem cards now fit their message container,
with the gift claim control centered locally. The bookmark-list editor uses
standard desktop padding, and the fluid profile preview has a window-aware size
cap. Focused analysis passes; native visuals and large text remain unverified.

2026-11-04: single feed images have a desktop height cap and use contain fit;
embedded media cards use a pane-aware width capped at 360 points. Existing
gallery and playback actions are retained. Focused analysis passes; actual
images, sensitive media, autoplay and native resizing remain unverified, so
the broader feed-media task remains open.

2026-11-04: added a device-local comfortable/compact selector in Appearance.
It adjusts workspace grid gaps, feed-card padding, people-card padding and a
people-section header gap; comfortable preserves their prior values. Eleven
locales were regenerated. Focused analysis and 11 workspace/density tests pass,
including spacing updates and preference restoration. Native theme, contrast,
hit-target and large-text checks remain open; the active app was not rebuilt.

2026-11-04: A first resizable divider is implemented with a device-local saved
fraction, drag, arrow keys, Home/double-click reset and accessibility actions.
The 520-point default and 400-point per-pane minimum are provisional: when the
available panel is under 801 points the panes share it evenly. The lower minimum
leaves drag travel at the native minimum window size. Widget tests
cover resizing, persistence, clamping and keyboard reset; real content, large
text, display scaling, restored window geometry and native accessibility remain
unverified. Do not treat the measurements as a validated macOS minimum.
Discover, Articles and Videos now adapt their card columns to pane width and
text scale; test coverage exists, but native visuals and resizing while scrolled
remain open. Other pane routes still need the planned layout audit.

- [x] Implement a draggable divider with a resize cursor, double-click and
      keyboard reset, keyboard resizing and semantics. Use a
      520-point default and 400-point pane minimums when space allows; at
      smaller widths share the available space evenly. No hover highlight.
- [x] Persist the split per device, reject invalid saved values and clamp the
      layout without overwriting the saved fraction when the window narrows.
      Widget tests and an isolated macOS fixture cover restoration.
- [ ] Verify the provisional pane minimums with real feed and sidebar content,
      and check the production window across fullscreen, display changes,
      native pointer and VoiceOver. Verify live account changes separately.
- [x] Audit raw `.w`/`.h` and window-wide layout assumptions in pane routes;
      address confirmed issues in feed grids, media, headers and controls.
      Native real-content and visual verification remain separate items above.
- [x] Add shared compact/comfortable desktop density tokens and apply them to
      representative feed, pane header and list surfaces without changing mobile
      defaults, including the current Home side-pane sections.
- [ ] Verify density hit targets, text contrast and existing theme variants in
      the current native build.
- [x] Bound desktop feed media previews, retain aspect-ratio and autoplay
      handling, respect hidden video previews, and provide a full-media action.
- [ ] Verify real image/video rendering, sensitive media and playback in a
      current native desktop build.
- [ ] Add layout tests for minimum constraints, divider clamping/restoration,
      localization and text scale. Complete visual
      checks at minimum, intermediate and wide sizes in fluid and solid themes.

**Exit:** main and side content remain usable and reversible at supported sizes;
no clipping or lost state in the tested core flows.

## Phase 3 — Desktop navigation and interaction

**Complete by user confirmation (2026-11-11).** Sidebar and navigation
verification is done. Per user direction, pin/reorder, command search,
shortcuts and context-menu expansion are removed from this plan.

## Phase 4 — Connectivity and links

**Status: complete by user direction (2026-11-11).** Device and relay status,
Nostr links and reply-cache verification are closed for this plan. Wallet links
and a relay-core reconnection overhaul are out of scope. Verification limits
remain documented in the audit; do not use the running signed-in app for tests.

- [x] Separate device interface state from DNS and relay socket status; show
      unknown, interface availability and configured relay socket counts on
      desktop. Disposable interface fixtures cover stale checks and errors.
- [x] Preserve unsent events when a retry fails, with a fake-sender fixture.
- [x] Deliver cold and running Nostr URLs to an isolated macOS listener; queue
      an early link until the main view is ready. This verifies delivery only.
- [x] Exercise reply-stat retention and later eviction in a fresh disposable
      macOS process using the actual cache cubit and a synthetic view lifecycle.
- [x] Close the remaining navigation and relay recovery follow-up by user
      direction. Actual content navigation and live recovery were not verified.

Historical 2026-11-11 continuation (wallet scope superseded): the link listener now uses the app_links stream for
both initial and subsequent URIs, avoiding a separate latest-link read and its
duplicate delivery. Wallet handling waits for initialization and checks that
the signer has not changed. A disposable stream/classification fixture passes;
it does not exercise navigation, wallet callbacks, native URL registration, or
signed-out launch. Signed-out wallet links are currently ignored and need a
defined recovery flow. Connectivity, relay status and reconnection remain open.

macOS system notifications are not needed and are removed from scope. The
existing unsupported-plugin guard remains a fail-safe. Other previously listed
Phase 4 checks are not release-blocking work in this plan. Once connectivity and
links are complete, proceed to Phase 6 cross-platform release readiness.

## Phase 5 — Optional deck exploration

**Removed from scope by user direction (2026-11-11).** Do not carry the
multi-column deck forward as outstanding work.

## Phase 6 — Cross-platform and release readiness

**Active scope (2026-11-11):** Windows and Linux implementation and release
readiness. Wallet links, system notifications and the deck remain out of scope.

- [ ] Re-audit Windows/Linux plugin registrations and runtime behavior against
      the current lockfile; historical matrices are not sufficient. Define
      media/audio/webview support and explicit fallbacks per target.
  - [x] Add external-browser fallbacks for the main embedded audio, video,
        YouTube and Smart Widget paths on Windows/Linux; gate Linux Google
        sign-in and embedded X posts. Disposable widget tests pass.
  - [ ] Audit remaining media/editor entry points and verify all fallbacks on
        native Windows and Linux, including WebView2 and Secret Service.
- [ ] Implement and validate platform-appropriate minimum window constraints,
      scaling, keyboard modifiers, file dialogs and deep-link registration on
      each supported target. System notifications remain out of scope.
  - [x] Prepare Linux GTK command-line delivery and a desktop-entry template;
        prepare Windows running-link forwarding and a per-user protocol script.
  - [ ] Build and test cold/running Nostr links on both native platforms, and
        complete installer integration. No handler has been registered here.
- [ ] Verify macOS signing, notarization, entitlements, update and packaging
      path; define Windows/Linux packaging and dependencies separately. Recheck
      Swift Package Manager plugin warnings against the shipping Flutter SDK.
- [ ] Run full analysis and the meaningful test suite, record known pre-existing
      failures, and execute a documented release smoke matrix. Release builds
      follow the repository's obfuscation and symbol-upload instructions.

## Suggested first implementation slice

Start with Phase 0's navigation/account/draft audit and a minimal Phase 1
prototype. The first reviewable change should establish the side-pane base
state and show a useful Following view or an actionable fallback, with tests
for opening/closing a detail and independent scroll state. Avoid adding
arbitrary columns, a new design system, a notification backend and rail
customization to that same change. Record any unresolved architecture decision
before expanding the slice.

## 2026-11-11 — native pane check

The user subsequently reported successful pane dragging and reset, window
behavior, VoiceOver, appearance/language and media checks. The exact build,
display configuration and individual matrix cases were not specified. At the
user's request the divider's visible focus highlight was removed; keyboard and
semantic actions remain. The user confirmed the highlight is gone natively.
Do not infer that every display, locale, theme or playback case was checked.

An isolated current-code macOS build using the production window class reached
both 400-point divider limits by keyboard and survived a fullscreen round trip;
interest cards were visible at 1.5× text and RTL direction. The feed was
synthetic, the native pointer attempt did not visibly resize, and VoiceOver,
actual translated screens, real media playback and display changes remain open.
The hidden-video placeholder now scrolls after a large-text overflow was found;
focused English/French/Arabic and eight-theme widget checks pass. The desktop
test selection passed 148 tests and Flutter analysis passed. See the audit for
fixture limits; none of these checks completes the broad Phase 2 exit criteria.

The prior isolated synthetic macOS fixture confirmed a fullscreen keyboard
resize; automated pointer drags did not visibly move the divider and are not
a native pointer pass. Eight current splitter and DM/interest widget tests
passed. Real feed/sidebar minimums, VoiceOver, pointer dragging, production
window restoration and display changes remain open; see the current audit for
the environment and observations.

## 2026-11-05 — split and shell fixture follow-up

Disposable tests cover extreme saved divider fractions across narrowing and
remounting, and keyboard traversal from a nested Navigator to rail, main and
side controls. The Navigator starts focused in this fixture; the actual shell,
real-content minimums, native focus order and display changes remain unverified.
The Phase 2 and Phase 3 checklist items remain open.

## 2026-11-05 — eCash token dialog

The desktop token dialog has a locally bounded square QR and scrolls in a
short window. A disposable placeholder fixture covers widths of 240–600 points
and a 600×500-point dialog at 1.5× text. Native, real-token, translation and
phone/tablet visual checks remain open; the broader pane audit remains open.

## 2026-11-05 — empty wallet pane

The desktop Cashu empty state has a locally bounded illustration and can scroll;
the desktop wallet switch labels wrap. Disposable solid/fluid, LTR/RTL and
large-text fixtures pass. Native visuals, real wallet actions and translated
labels remain open, as does the wider pane sizing audit.

## 2026-11-05 — grouped wallet and points layout

Desktop Lightning-address QR sizing now follows local width; Cashu loading
artwork, balance divider and mint URL have bounded widths. The desktop points
explanation scrolls and has a width cap. Disposable QR and solid/fluid points
fixtures pass, alongside wallet, modal and no-hover checks; full analysis passes.
Cashu loading/balance rendering, native appearance and real actions remain
unverified. The six broad Phase 2 items remain open.

## 2026-11-05 — divider and DM breakpoint

The divider has a keyboard focus indicator and omits semantic actions at its
limits. A disposable draft test confirms that the DM conversation keeps its subtree
across a wide–narrow–wide transition over the inner 600-point breakpoint. Seventeen
focused tests and full analysis pass. Real-content minimums and native
fullscreen, display and accessibility validation remain open.

## 2026-11-05 — minimum-content and macOS fixture

A disposable fixture exercises the real DM workspace and interest cards at
both 400-point divider extremes with 1.5× text and a draft. A separate macOS
fixture confirms keyboard resizing and split persistence through fullscreen and
an app restart. The full feed/sidebar, real app frame restoration, external
display changes, native mouse and VoiceOver remain unverified; pane minimums
remain provisional. Eighteen focused tests and full analysis pass.

Desktop startup now uses an input-aware focus strategy, so keyboard focus
indicators are not suppressed by the mobile touch setting. Focus and no-hover
fixtures pass; native current-build accessibility remains open.

## 2026-11-05 — invoice QR bounds

Desktop receive and zap invoice QR codes now use local square bounds capped
at 320 points. A placeholder fixture covers the shared sizing inside an
intrinsic scroll layout; real invoice screens and native scanning remain open.
The wider pane-route sizing audit remains in progress.

## 2026-11-05 — Home sidebar density

Compact density now reduces section and heading gaps in the current desktop
Home sidebar; comfortable spacing and card sizes remain unchanged. A disposable
interest section fixture checks switching density at 1.5× text, and existing
feed preference and no-hover fixtures pass. Native theme, contrast and hit
target verification remains open.

## 2026-11-05 — desktop feed media implementation

Single video previews are pane-bounded and single image/video and gallery
previews expose a gallery action. Hidden desktop videos do not instantiate a
player or request gallery thumbnails before opening. Existing autoplay settings
are passed through. Twenty-two disposable feed, gallery, playback coordination
and no-hover tests and full analysis passed. Real native media rendering and
playback remain verification work.

## 2026-11-05 — zap invoice dialog and amount dividers

The desktop zap invoice dialog uses a bounded square QR and scrolls in short
windows; amount-entry dividers in send, receive and zap flows are bounded.
A non-payable placeholder dialog fixture passes at 380×300 points and 1.5×
text. Ten wallet, modal and no-hover tests and full analysis passed. The real
invoice flow, scanning and native visuals remain unverified; the broader
pane sizing audit remains open.

## 2026-11-05 — Cashu operation result sizing

The desktop result sheet scrolls in short windows; its animation and token QR
use bounded sizes. A disposable placeholder fixture checks the actual sheet at
320×350 points with 1.5× text. Ten wallet, modal and no-hover tests and full
analysis passed. Real token behavior, scanning and native visuals remain open.

## 2026-11-11 — desktop navigation More implementation

The desktop rail now keeps Search, Home, Messages, Notifications, More,
Compose and the account action outside a scroll view. The brand is hidden in
short windows. More filters the localized destination labels and retains the
existing signed-in visibility and callbacks. The currently selected Media,
Articles, Wallet or Smart Widgets view highlights More; selecting the first
three still scrolls to the top when already active. Mobile navigation and the
account-switch behavior were not changed.

The isolated dialog fixture covers case-insensitive search, empty results,
keyboard activation, Escape and focus restoration, plus a short RTL window at
1.5× text. These are widget checks, not a native desktop or screen-reader pass.
Destination and sign-in coverage in the real sidebar, the onboarding tour,
actual navigation, extreme rail heights and native focus remain to be verified.
See the implementation audit for the destination inventory and test results.

### Sidebar priority follow-up

Media and Wallet are back on the rail. Settings is fixed with Compose and the
account action at the bottom. The compact avatar is 44 points, matching
Compose. At constrained heights the navigation section can scroll independently
of that footer. More now groups its searchable destinations under translated
headings; Compose uses a translucent, blurred popup. These changes do not alter
account switching or destination callbacks. Native appearance remains to be
checked in a disposable build.

Follow-up: Compose now uses the actual glass menu component rather than a
translucent Material popup, and Settings has a rounded footer container. Native
appearance and full keyboard traversal still need a disposable desktop check.

## 2026-11-11 — desktop subscription billing

Desktop platform subscriptions now use the existing external card checkout and
Stripe management controls instead of the IAP flag. Mobile store selection is
unchanged; desktop restore/store actions remain guarded. Tests use fake account,
status, checkout link and browser responses. **Stripe checkout is complete** per
the user's confirmation on 2026-11-11. The confirmation did not specify test
conditions or webhook details. The backend's duplicate-Stripe concurrency guard
remains a separate concern; see the implementation audit.

## 2026-11-11 — scope decisions

The user confirmed sidebar and navigation verification is complete, and removed
the optional interaction enhancements and multi-column deck from the plan.
Continue with Phase 4 native reliability and Phase 6 release readiness.

## 2026-11-11 — native reliability findings

Desktop now avoids unsupported `awesome_notifications` initialization,
permission, badge and delivery calls. The disposable manager guard test and
focused analysis pass. This does not implement desktop system notifications.
The desktop shell has no equivalent of the mobile connectivity indicator, and
its connectivity boolean is not a relay-health measure. Initial wallet links
are explicitly skipped by the initial-link handler even though running links
are handled. Track these as Phase 4 work; see the audit for the code-level
findings and verification limits. No real account, payment or upload was used.

## 2026-11-11 — reliability scope update

The user removed macOS system notifications from scope and directed the next
work to connectivity and links. After that work, proceed to cross-platform
release readiness. Earlier Phase 4 checklists are superseded.

## 2026-11-11 — cross-platform audit continuation

The local-video composer now avoids the unsupported Windows/Linux video player
and hides editor/compression actions that depend on it. Network image and video
saves use the registered desktop file selector on those targets. Native file
dialog, playback, editor and upload validation remains open. Generated-image,
Blossom and secure key export paths need further work; see the audit.

The tracked desktop workflow now describes manually dispatched, unsigned build
candidates with pinned Flutter and Nostr sibling versions, protected build
configuration, Linux build dependencies, obfuscation and retained symbols. It
has not run and does not sign, package, notarize, upload symbols or publish.
Configuration bundled in Flutter assets is extractable. Actual Windows/Linux
packaging, signing, runtime prerequisites and native release tests remain open.
The Nostr link and window/DPI limitations are recorded in the audit; no handler
was installed and no native Windows/Linux test was claimed.

### File-save and secure-storage continuation

Generated-image and Blossom saves now use the desktop file selector on Windows
and Linux; disposable fake-dialog coverage includes cancellation, paths with
spaces, bytes and a write failure. Windows drive-letter video paths are no
longer classified as URLs for thumbnail selection. Native verification remains
open. The audit identifies silent secure-storage read/write failures as a
release blocker requiring fail-safe account initialization and persistence,
with disposable failure tests. No account data was accessed during the audit.

### Storage priority clarification

Prioritize Linux account-storage recovery, especially an unavailable or locked
Secret Service. Keep existing mobile and macOS behavior unchanged for this
work. The shared error-handling weakness can also affect other platforms;
Linux is the immediate priority, not the only platform where errors can occur.
The Windows risk remains documented and must not be represented as verified or
fixed by Linux-only work. Preserve account data and use disposable tests.
