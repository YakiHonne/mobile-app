# YakiHonne Desktop: Product Assessment and Direction

**Date:** 2026-11-03  
**Status:** Proposal for the existing desktop implementation  
**Scope:** macOS first; Windows and Linux follow after a current platform audit

This document describes the experience we want to build. It is not evidence
that a proposed feature already exists. The actionable sequence and acceptance
checks are in [DESKTOP_TASK_PLAN.md](DESKTOP_TASK_PLAN.md). Current implementation
and runtime evidence remain in the current-audit section of
[DESKTOP_IMPLEMENTATION.md](DESKTOP_IMPLEMENTATION.md); its older tracker is
historical where it conflicts with the current audit. Existing visual rules are
in [DESIGN_GUIDELINES.md](DESIGN_GUIDELINES.md).

## Executive assessment

YakiHonne has substantial Nostr functionality and a working desktop shell, but
the experience does not yet use the desktop as a coherent workspace. The rail,
feed and persistent detail pane exist, yet the pane can start empty; navigation,
content density, keyboard interaction and page sizing still feel like separate
mobile flows placed beside each other. A larger minimum window alone does not
make the workspace feel complete.

The product direction is **a comfortable Nostr workspace for reading, creating
and managing content**, with two useful, persistent regions. The side pane
remains present at desktop widths and is the destination for pages, including
search, settings, wallet and compose, as requested. A selected page should
temporarily cover useful pane content and return the user to it when closed.
More customizable columns can be an optional later capability, not a condition
for a good first experience.

## Evidence and limits

- The current checkout has a compact/expanded desktop rail, a main content area,
  and a nested detail navigator. macOS currently sets a 1,280-point minimum
  window width; the rail collapses below 1,450 points. The detail pane is
  capped at 520 points and shares narrower available width with the main pane.
  These are current implementation choices, not validated usability targets.
- A macOS visual review showed a live feed beside an empty detail pane. The
  user also reported that the previous minimum width made content feel narrow.
  The latest minimum-width increase has not been visually validated here.
- The user reports that startup, profile refresh placement, detail-pane bar
  spacing, article refresh, and video save and cancellation worked in their
  test. The report did not establish newer-article replacement, saved-video
  playback, or coverage of all themes and pane routes.
- Existing code includes feed filters, packs, relay views, bookmarks, wallet,
  media, articles, creators, widgets, account switching and draft mechanisms.
  We should reuse and verify these rather than treating them as absent.
- The current code and audit identify limited desktop shortcut/context-menu
  coverage, unfinished hands-on layout verification, and a nonfunctional
  macOS implementation in the locked notification plugin. Registration in a
  plugin manifest is not proof that a native feature works.
- Competitor research used official product pages and project documentation;
  Notedeck and Amethyst were not installed or comprehensively tested for this
  assessment. Vendor descriptions, project status and roadmap items are not
  independent UX or performance measurements.

## What to learn from other clients

| Reference | Verified evidence | Design lesson for YakiHonne |
| --- | --- | --- |
| [Notedeck](https://github.com/damus-io/notedeck) | The project describes a multi-column desktop client; [Damus's overview](https://damus.io/notedeck/) describes profile, hashtag and notification columns. | A persistent region should do useful work and allow parallel attention. The overview includes historical alpha claims; do not infer the status of every current feature from it. |
| [Amethyst Desktop](https://github.com/vitorpamplona/amethyst/blob/main/docs/plans/README.md) | Its project index identifies shipped desktop work including an app drawer, customizable navigation, named workspaces, search, feed feedback and visual polish. | A desktop experience is a connected system of organization, continuity and input affordances. Archived plans are project-reported status, not independent verification. |
| [Nostria](https://www.nostria.app/features) | Its product page describes a command palette, favorites, flexible layouts and multi-column threads. | Offer a useful default first, then let users personalize it. |
| [noStrudel](https://github.com/hzrd149/nostrudel) | Its project describes a web client for exploring Nostr information and underlying events. | Offer relay and event detail on demand while keeping ordinary reading approachable. |

No performance ranking or feature-parity claim follows from these sources.

## Product principles

1. **Two useful regions.** The main area and side pane both have clear jobs;
   the side pane does not routinely start as a large dead end.
2. **The user's place is stable.** Opening a page, changing a selection or
   temporarily enlarging an editor preserves feeds, scroll positions and
   unfinished work. Account changes must not expose another account's content.
3. **Content leads.** Controls and visual effects support reading and writing;
   they should not obscure the content or require constant visual attention.
4. **Desktop input is first-class.** Mouse, keyboard and assistive technologies
   can reach the same core actions as touch.
5. **Nostr complexity is available, not mandatory.** Show connection state and
   actionable errors; place relay and event details one deliberate action away.
6. **Default simplicity, optional depth.** Use sensible presets before adding
   arbitrary workspace customization. Preserve the app's own identity and
   features rather than cloning another client.
7. **Prove behavior on the real target.** Build, analyze and widget tests are
   necessary; native dialogs, signing, notifications, accessibility and visual
   behavior require hands-on verification.

## Proposed workspace

```text
┌──────────┬──────────────────────────┬─────────────────────────┐
│          │                          │                         │
│ Rail     │ Home / current section   │ Default: Following      │
│          │                          │ or another chosen view  │
│          │ Select a note ───────────┼─> Thread / profile      │
│          │                          │ Close → previous view   │
└──────────┴──────────────────────────┴─────────────────────────┘
```

### Default side pane

Proposed first default for a signed-in user: **Following**, with independent
scrolling and a clear header. Provide Notifications, Bookmarks and a specific
supported feed as later choices once each can be isolated safely. For a user
without a usable following feed, provide an informative fallback with a direct
action to select another available pane. Never show an indefinite spinner or a
generic error for a valid empty feed.

This is a product proposal, not a claim that another `LeadingView` can simply
be inserted. Existing global cubits, shared controllers and subscriptions may
assume a single consumer. Before shipping a second live feed, verify independent
scroll positions, request lifecycle, pagination and refresh behavior. Use a
pane-scoped controller/state or a properly shared data layer with independent
view state; do not mount a second view with the same `ScrollController` or
blindly duplicate relay subscriptions. Limit initial background work and
measure resource usage.

The pane's base content remains mounted or is restored when a detail page
closes. A pane header names the current view and exposes back/close and the
few actions relevant to it. The main and side panes scroll independently.
When a navigation stack or account changes, keep content ownership explicit.

### Pane widths and presentation

The side pane always exists on desktop. Introduce a visible, accessible divider
that lets the user adjust the split within measured minimum and maximum pane
widths; persist the preference locally per device. Double-click can restore the
default, and keyboard adjustment must be supported. Exact minimums must be
validated against content, text scaling, localization and supported displays,
not selected solely from a screenshot.

Support an **expanded side pane** for article editing, wallet steps, detailed
media and other dense pages. It borrows width from the main area while retaining
the main area's state; it does not send the user to an unrelated full-window
stack. Closing or leaving expanded mode restores the previous split. The main
area may become a narrow context rail if it remains usable; if not, define an
explicit reversible presentation for that page rather than clipping controls.
Short choices and confirmations remain adaptive dialogs.

The macOS minimum window size must work on common display sizes and with system
scaling. Verify restored windows, fullscreen, display changes and the current
1,280-point limit on actual devices before changing it further. A large minimum
can exclude smaller displays; retain the user's permanent-pane requirement while
resolving this with measured layouts. Windows/Linux have not yet been given
equivalent verified window constraints.

### DM and navigation behavior

The conversation list belongs in the main area and the selected conversation
in the side pane. Changing conversations must not leave hidden conversations
subscribed as active or suppress their notifications incorrectly; DM draft
ownership is per account and conversation. Opening a profile or media from a
conversation may stack in the side pane and Back returns to that conversation.
Define what switching away from DMs and returning restores; do not silently
discard the selected conversation or a compose draft.

All desktop page entries, including named routes, builder routes, direct
pushes, replacements, modal-to-page transitions, deep links, wallet, media and
compose, need an explicit navigation audit. Existing centralized routing and
the root route tracker are starting points, not proof that every entry point or
pop sequence behaves correctly. A confirmation dialog's dismissal must never
pop an unrelated root page or erase an unfinished editor.

### Navigation rail and discovery

Keep Home, Search, Notifications, Messages and Compose easy to find. Group
secondary destinations in a labeled More/app drawer; retain access to all
existing features. Add user-pinned favorites only after the grouping is usable.
Favorites can eventually point to a feed, pack, relay, profile or other stable
destination, with account-safe persistence. Provide accessible labels and
tooltips in compact mode. Use unread counts where reliable; retain dots where
counts are unavailable rather than inventing data.

### Content, density and visual language

- Offer comfortable and compact density, preserving readable typography and
  accessible target sizes. Start with shared desktop surfaces rather than
  changing mobile spacing globally.
- Limit feed media height in a way that preserves aspect ratio and makes opening
  the full item obvious. Respect sensitivity and autoplay settings.
- Indicate the selected note or conversation and active pane without relying on
  color alone. Use consistent headers and predictable close/back controls.
- Keep source, filter and refresh controls legible at the validated minimum
  pane width. Tooltips supplement accessible labels; they do not replace them.
- Apply the existing spacing, color, typography and shared-widget conventions.
  Recheck the live root `GLASS_IMPLEMENTATION.md` if it becomes available;
  it was absent during this assessment. Verify both fluid and non-fluid themes.

### Mouse, keyboard and accessibility

Proposed defaults, subject to platform conventions and conflict testing:

| Action | Proposed shortcut | Guard |
| --- | --- | --- |
| Search / command palette | Cmd/Ctrl+K | Does not steal OS/browser shortcuts or interrupt an input unexpectedly. |
| Compose | N | Disabled while an editable field, dialog or incompatible focus owns input. |
| Close / back | Escape | Dismiss only the topmost eligible layer; never discard a draft silently. |
| Move through feed | J/K or arrow keys | Only when focus is in an eligible feed and not editing text. |
| Open selected item | Enter | Acts on the focused item, not an arbitrary last selection. |

Use platform-appropriate modifiers and expose a discoverable shortcut reference.
Right-click menus should offer the same permitted actions as their existing
menus. Text selection, visible focus, screen-reader labels, logical tab order,
reduced motion and high-contrast rendering are part of the feature. Keyboard
and focus behavior must work inside nested pane navigators and dialogs.

### Status, media and trust

Show compact connection/relay status and actionable states such as connecting,
offline, partial results and retry. Avoid asserting all relays are healthy from
one connected socket. Maintain reading position while new posts arrive and use
an explicit new-items control where appropriate.

For media and exports, verify native file selection and save/cancel feedback,
video playback, thumbnails, QR images, Blossom upload/download and key/wallet
exports with suitable test data. File drops and richer media actions are later
enhancements, not prerequisites for safe existing behavior.

macOS system notifications require a working implementation and live-event
wiring: `awesome_notifications` 0.10.1's macOS implementation in this checkout
does not implement notification methods. Test permission, event filtering,
delivery, click behavior and badges separately. Closed-app delivery requires a
separate design and must not be promised by an open-app relay subscription.
Desktop IAP remains guarded until its store, distribution and backend receipt
contract is explicitly defined and verified.

## Optional future: a deck

After the two-pane workspace is reliable, explore an opt-in deck with independent
columns for Following, Notifications, selected packs/relays, hashtags or
profiles. Any proposal must cover per-column source and filter ownership,
scroll/refresh/pagination, subscription limits, persistence, account isolation,
responsive layouts, keyboard order and resource use. A deck is a product
decision with higher complexity; it is not the first implementation milestone.

## Measures of success

- On first launch into the desktop shell, the side pane has an understandable,
  actionable state and can display a useful source without duplicate-controller
  errors or runaway subscriptions.
- Opening a note and closing it restores the prior side content and scroll
  position; switching accounts does not expose previous-account content.
- At the validated minimum and at a wide desktop size, users can read a feed,
  open a conversation, search, compose and access the wallet without clipping,
  forced loss of drafts or unintentionally leaving the desktop shell.
- Keyboard-only users can reach and operate the principal tasks, with visible
  focus and no shortcut interference in editable fields.
- Native behavior is documented as verified only after hands-on tests on the
  target platform. Record environment, outcome and any remaining limitations.
