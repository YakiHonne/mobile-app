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

- [ ] Prototype a draggable divider; establish measured per-pane minimums and
      a default split from real content at the current macOS minimum and wide
      sizes. Support cursor, hover, double-click reset, keyboard and semantics.
- [ ] Persist a validated split per device; handle invalid or stale saved
      values, account switching, fullscreen and display changes. Do not allow a
      saved preference to make controls unreachable.
- [ ] Audit raw `.w`/`.h` and window-wide layout assumptions in pane routes;
      size against local constraints. Check feed list/grid breakpoints, media
      tile patterns, headers, input controls, long text and large type.
- [ ] Add shared compact/comfortable desktop density tokens and apply them to
      representative feed, pane header and list surfaces without changing mobile
      defaults. Check hit targets, text contrast and existing theme variants.
- [ ] Bound large feed media, preserve aspect ratio and sensitivity/autoplay
      settings, and provide an obvious full-media action.
- [ ] Add layout tests for minimum constraints, divider clamping/restoration,
      localization and text scale. Complete visual
      checks at minimum, intermediate and wide sizes in fluid and solid themes.

**Exit:** main and side content remain usable and reversible at supported sizes;
no clipping or lost state in the tested core flows.

## Phase 3 — Desktop navigation and interaction

**Depends on:** Phase 0; layout work can proceed alongside Phase 2.

- [ ] Inventory rail destinations and usage; keep Home, Search, Notifications,
      Messages and Compose visible. Design a labeled More/app drawer that
      retains every current destination and has searchable, accessible entries.
- [ ] Add local per-account pin/unpin/reorder for a small set of existing
      destinations. Define migration and fallback for a missing relay/profile/
      pack; do not invent unread counts where none exist.
- [ ] Implement an app-level command/search entry and discoverable shortcuts
      for search, compose, focus movement, open and dismiss. Use Cmd on macOS
      and Ctrl elsewhere where appropriate. Avoid intercepting editable fields,
      system shortcuts, modal focus or assistive-technology interaction.
- [ ] Add context menus to representative note/profile/link actions, reusing
      authorization and existing action logic. Add text selection to feed notes.
- [ ] Audit focus traversal and restoration, semantic labels, tooltips, hover,
      cursors, screen-reader announcements, reduced motion and high contrast.
- [ ] Test keyboard-only flows, nested Escape, selectable text, secondary click,
      menus and sign-in/permission gates. Check RTL and long labels.

**Exit:** a user can read, search, compose, open a note and return without a
mouse, and the same core actions are discoverable with a mouse and screen reader.

## Phase 4 — Reliability and native macOS integration

**Depends on:** Phase 0; native notification work may run independently of UI.

- [ ] Design and implement a supported macOS notification backend; the locked
      `awesome_notifications` macOS code is a stub for notification methods.
      Keep Android behavior intact and avoid calling unsupported methods on macOS.
- [ ] Define which live relay events generate alerts, deduplication, account and
      mute filtering, user preference semantics, notification content privacy,
      permission timing, badges and click routing. Distinguish open-app delivery
      from closed-app/background delivery; treat the latter as separate scope.
- [ ] Test first permission prompt, denied/re-enabled permission, foreground and
      background-with-app-running behavior, click/dismiss, badge, multiple
      accounts, reconnect and duplicate events. Record actual OS behavior.
- [ ] Show truthful connection/relay state and actionable offline, partial and
      retry feedback. Implement or verify a new-items control that preserves
      reading position; test reconnection and relay failure.
- [ ] Complete macOS manual checks: QR image save; Blossom upload/download after
      explicit server configuration; video save, cancellation and playback;
      native thumbnail generation using known uncached media; and key/wallet
      exports only with safe fixtures. Preserve the user's reported successes.
- [ ] Verify NIP-46 connection/signing, cold/running Nostr and wallet deep links,
      and scanner guards. Test desktop purchase/restore/store-management guards.
      Keep IAP disabled until macOS product, distribution and receipt-validation
      contract are agreed and implemented.

**Exit:** supported native features have verified outcomes; unsupported ones
fail clearly and are not advertised as working. Open-app notification success
does not imply closed-app delivery.

## Phase 5 — Optional deck exploration

**Depends on:** independent pane state and resource measurements from Phase 1,
plus stable interaction and navigation from Phases 2–3.

- [ ] Prototype an opt-in workspace with two or more independently scrollable
      feeds; test a default Following + Notifications layout and selected
      pack/relay/hashtag sources with real users.
- [ ] Specify per-column data ownership, filters, refresh, pagination, network
      subscriptions, account isolation, persistence, resize, close/back and
      keyboard order before implementing arbitrary rearrangement.
- [ ] Measure memory, relay connections and refresh behavior as columns increase;
      define practical limits and suspend or dispose hidden work safely.
- [ ] Decide whether to ship based on user feedback and resource costs. A deck
      must remain optional and must not regress the standard two-pane workspace.

## Phase 6 — Cross-platform and release readiness

- [ ] Re-audit Windows/Linux plugin registrations and runtime behavior against
      the current lockfile; historical matrices are not sufficient. Define
      media/audio/webview support and explicit fallbacks per target.
- [ ] Implement and validate platform-appropriate minimum window constraints,
      scaling, keyboard modifiers, file dialogs, deep-link registration and
      notification behavior on each supported target.
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
