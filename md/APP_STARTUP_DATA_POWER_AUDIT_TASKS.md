# App startup, data use, and power optimization tasks

**Status:** Investigation complete; P0 tasks complete; wallet/Cashu and Notifications P1 tasks complete; remaining P1/P2 tasks not started  
**Prepared:** 2026-10-07  
**Scope:** Flutter client startup, Nostr/API loading, retained feed data, background refresh, media playback, and cache work.

## Goal

Reduce unnecessary startup work, network traffic, retained data, and battery use while preserving a useful warm start. The app should still show the selected Home feed and the signed-in account state needed to render and filter it. Feature state should load when its feature is opened, or earlier only when a documented product requirement needs it.

The primary optimization target is **side effects triggered by global cubit construction and startup orchestration**. Constructing an empty cubit is generally cheap; starting requests, subscriptions, timers, media controllers, and scans is the work to control.

## Audit findings and context

### Current startup sequence

- The app entry point awaits AppInitializer.initApp() before runApp(): lib/main.dart.
- The initializer builds global cubits and then feed cubits. DiscoverCubit, LeadingCubit, and MediaCubit start their own work from their constructors: lib/initializers.dart.
- The initial main view is Home. MainView uses an IndexedStack and only creates the other tab bodies after a tab has been visited: lib/views/main_view/main_view.dart.
- That UI laziness does **not** currently make feed data lazy: Discover and Media cubits are global and begin fetching before their tab bodies are created.
- Home, Discover, and Media initial feed builders use a 50-event limit. Each populated feed starts a 30-second extra-content timer that checks whether the feed has content, not whether that tab is active: lib/logic/leading_cubit/leading_cubit.dart, lib/logic/discover_cubit/discover_cubit.dart, and lib/logic/media_cubit/media_cubit.dart.
- Home also starts a five-event media suggestion request, paid-note ad lookup, and suggestion requests. The same leading suggestions initializer is called by both Leading and Media, duplicating the trending-user and latest-article request paths: lib/logic/leading_cubit/leading_cubit.dart, lib/logic/media_cubit/media_cubit.dart, and lib/logic/suggestion_box_cubit/suggestions_box_cubit.dart.
- For signed-in users, a second wave starts two seconds later. It loads metadata, notifications, DMs, media-server settings, related account events, YakiHonne app settings, and creator subscriptions: lib/initializers.dart and lib/repositories/nostr_data_repository.dart.
- routingInitData() starts rewards pricing, user stats, and subscription-usage requests during app setup. Its local settings read is awaited by startup: lib/repositories/nostr_data_repository.dart.
- MainCubit still starts the selected Lightning wallet balance during main-view construction because quick zaps validate against it. Bitcoin fiat rates now load only when a wallet/fiat surface is opened, with an in-memory 30-minute freshness window. Cashu initialization starts when its view or payment method is selected; recommended mints load when a mint picker opens: lib/logic/main_cubit/main_cubit.dart, lib/logic/wallets_manager_cubit/wallets_manager_cubit.dart, and lib/logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart.
- DM initialization reads cached conversations and gift wraps, processes cached events, starts live querying, and resumes older-history backfill in bounded five-page batches. Notifications query up to 40 history events before subscribing: lib/logic/dms_cubit/dms_cubit.dart and lib/logic/notifications_cubit/notifications_cubit.dart.
- Relay and maintenance work includes forced relay/contact refresh, contact relay discovery, relay reconnect checks every 10 seconds, a core DB flush every 10 seconds, and internet checks every minute. The remote-cache socket is explicitly initialized and connected even though NostrCore is constructed with loadRemoteCache: false; on connection failure its retry path waits and reconnects repeatedly: lib/initializers.dart, ../nostr_core_enhanced/lib/core/nostr_core_repository.dart, and ../nostr_core_enhanced/lib/cache/remote_cache_service.dart.
- Video autoplay defaults to enabled for embedded media, and creating a video controller enables wakelock: lib/models/app_models/app_customization.dart, lib/views/widgets/content_renderer/content_renderer.dart, and lib/logic/video_controller_manager_cubit/video_controller_manager_cubit.dart.
- Camera discovery is started during settings initialization. The cache cubit measures database and media-cache sizes after five seconds. The image cache is configured with a 100 MB byte ceiling. The feed list has a 500-item cap: lib/initializers.dart, lib/logic/crashlytics_cubit/crashlytics_cubit.dart, and lib/models/app_models/diverse_functions.dart.

### Keep these warm

These are the recommended minimum startup responsibilities:

- App preferences needed to choose theme, locale, account, selected feed source, and filters.
- Local signer/account identity and cached metadata.
- Local mute, contact, and relay state used by the selected feed.
- The selected Home feed's initial page and the relay connections required to obtain it.
- Unsent-event processing so pending user actions are not stranded.
- Push registration/live notification behavior when the user enabled it and it is a product requirement.

Prefer **local cache first, asynchronous refresh second** for state that affects first paint. Do not wait for unrelated feature state before showing Home.

## Implementation task list

### P0 — Make feed initialization follow visited tabs

- [x] Make DiscoverCubit and MediaCubit construction passive. Add an idempotent start/ensure-initialized entry point, and invoke it only when the corresponding tab is first selected.
- [x] Keep the selected Home feed's first request on startup, using the locally selected source and filter.
- [x] Ensure the transition into a tab starts its feed once, retains its list/scroll state on later tab switches, and handles a source/filter change correctly.
- [x] Remove the redundant suggestionsBoxCubit.initLeading() call from Media initialization. Ensure leading suggestions are loaded once; deduplicate any concurrent/in-flight calls to shared trending or article methods if other call sites can overlap.
- [x] Review Home's media teaser, paid-note ads, and suggestion requests. Keep any module required in the initial viewport warm; move below-the-fold requests to a visibility/near-viewport trigger where this does not cause visible layout regressions.
- [x] Review whether the Home first page needs 50 items. If there is no measured reason to retain that size, begin with approximately 20–25 and keep existing load-more behavior for scroll. Preserve the selected source's filter, ordering, and pagination anchor.

**Acceptance criteria**

- A cold launch starts the selected Home feed, but does not request Discover or Media feed data until those tabs are visited.
- The suggestions request previously triggered by both Home and Media occurs once for that startup/loaded state.
- Switching tabs does not rebuild an already loaded feed or create duplicate timers/subscriptions.
- Home's initial content and current source/filter behavior remain intact.

### P0 — Tie feed refresh timers to visibility and app lifecycle

- [x] Give each feed one owned refresh timer; cancel it when its tab is inactive, the cubit is disposed, or the app is paused.
- [x] Poll immediately when an initialized feed with content becomes active again, then continue every 30 seconds. Lazy Media/Discover feeds begin polling only after their first page loads. On app resume, refresh the active feed after a bounded delay rather than firing all inactive feed timers together.
- [x] Prevent overlapping extra-content requests if a slow request is still running when the next timer tick occurs.
- [x] Preserve manual pull-to-refresh and load-more behavior.

**Acceptance criteria**

- No inactive feed issues periodic extra-content requests.
- Pausing and resuming the app does not leave duplicate timers or subscriptions.
- A slow request cannot create concurrent copies of the same poll.

### P1 — Keep DMs ready and bound older-history backfill

- [x] Keep cache-first startup hydration; load cached direct messages and gift-wrap IDs before setting live/history cursors or starting network work.
- [x] Show the history-loading indicator only when no cached DM history is available; continue older-history backfill without keeping the cached inbox in a loading state.
- [x] Start the live DM subscription immediately after cache hydration, before older-history requests, so foreground reception does not wait for backfill.
- [x] Decrypt historical kind-1059 gift wraps and persist their inner DM events before advancing the history cursor.
- [x] Bound each history worker run to five pages, widen each completed date window up to 180 days, persist its cursor and live watermark, and resume after a short delay.
- [x] Advance the history cursor only after all queried relays reach EOSE; retry incomplete pages with 1–15 second backoff and leave the cursor unchanged.
- [x] Cancel scheduled work and ignore stale results after logout/account changes; preserve the Remote signer restriction and Amber opt-in check.
- [x] Keep foreground relay reception separate from background push behavior. The foreground startup/callback path was verified by code inspection; push delivery remains under the notification P1 work below.

**Acceptance criteria**

- [x] Cached DM sessions and latest locally available messages are ready when the user opens DMs.
- [x] New messages are received while the user is using the app, without requiring entry to the DM tab.
- [x] Older-history work does not gate cache hydration or live subscription startup and resumes without reprocessing already handled events.

**Implementation note:** Each worker run caps the number of date-window queries, while relay response size remains uncapped. Adding a result limit needs tie-safe pagination so messages sharing a timestamp are not skipped.

### P1 — Separate notification badge/live behavior from history loading

- [x] Keep local notification state available at startup and restore the unread dot from saved per-account notification IDs.
- [x] Keep a relay-only live subscription for foreground arrivals and use a persisted per-account timestamp for bounded catch-up after pause/background time.
- [x] Load recent notification history when the Notifications tab opens; refresh the list on pull-to-refresh.
- [x] Avoid querying full history at startup or replaying the local event backlog through the live subscription. Catch-up asks for at most one event per enabled notification filter because the badge only needs to know whether unseen activity exists.
- [x] Gate permission prompts, push registration, local delivery, and server revocation on the saved push setting; respect the private-message category and keep one heartbeat timer/connection listener.
- [x] Merge burst arrivals without losing unread IDs and bound retained unread, seen, and in-memory notification IDs.

**Acceptance criteria**

- [x] The unread dot is restored at startup and appears for unseen foreground or catch-up arrivals; opening Notifications marks those IDs read.
- [x] Full notification history is not loaded before the Notifications tab is opened.
- [x] Opening Notifications loads the recent list, and pull-to-refresh refreshes that list without restarting live reception.
- [x] Opted-in push configuration is refreshed on resume and revoked when push is disabled.

**Implementation note:** The catch-up cursor is initialized at app startup so activity during delayed account hydration is included. Catch-up advances its cursor only after all queried relays reach EOSE; incomplete queries retry after 30 seconds. Opening Notifications marks the current watermark seen, and cursor writes are monotonic. Live reception starts at the captured time boundary with a short overlap. Initial cursor creation does not turn old history into unread activity.

### P1 — Lazy-load wallet and Cashu data

- [x] Keep the eager Lightning wallet balance request in MainCubit because quick zaps need it for validation; defer fiat-rate fetching to wallet/fiat use.
- [x] Keep wallet settings/selected-wallet metadata locally and retain the eager Lightning balance needed by quick zaps; load fiat rates when wallet/fiat UI needs them.
- [x] Move Bitcoin fiat-price fetching to wallet/fiat UI use and cache successful results in memory for 30 minutes.
- [x] Remove recommended-mint fetching from the Cashu cubit constructor. Fetch recommendations when the Cashu mint picker opens, coalescing concurrent requests.
- [x] Defer Cashu wallet initialization from generic post-login warmup. Initialize when the Cashu wallet view or Cashu zap payment method is opened; retain explicit account-switch initialization.

**Acceptance criteria**

- Home launch keeps the Lightning balance request needed for quick zaps but does not request fiat prices or Cashu data solely because the main view exists.
- Opening Wallet preserves selected-wallet and balance behavior and loads fiat rates if stale.
- Opening the Cashu wallet loads wallet state; opening its mint picker loads recommended mints.

### P1 — Move feature-specific API requests out of generic routing warmup

- [ ] Keep local settings required for immediate actions available, but move rewards pricing to the first reward/action view that needs it.
- [ ] Move points stats to the points/profile view.
- [ ] Move subscription usage/status refresh to subscription UI or another explicit usage-check point; retain any cached status needed for existing gating behavior.
- [ ] Review settingsCubit.getYakiHonneApp() and defer its remote lookup until a view uses the app/client registry data.
- [ ] Confirm getTopics() is currently local initialization before changing it; do not count it as a network request.

**Acceptance criteria**

- A user who stays on Home does not trigger unrelated pricing, points, usage, or app-registry requests.
- Reward, points, subscription, and client-settings features still load current data on entry/use.

### P2 — Make auxiliary relay, pack, media-server, and subscription sync conditional

- [ ] Load local packs early only if the selected feed source requires them; otherwise load them on Packs entry. Run remote pack sync in the background or on demand.
- [ ] Keep local favorite relay/relay-set data where it affects the selected source, but defer remote favorite-relay sync until a relay-management view or dependent feed is opened.
- [ ] Keep the current user's local media-server settings accessible for upload flows; defer Blossom-set lookup/discovery until upload or media-server settings need it.
- [ ] Fetch creator subscriptions when premium notifications or a profile/subscription check needs them. Use an in-memory freshness guard to avoid repeated requests.
- [ ] Preserve a background refresh only for a specific feature that demonstrably needs current data before its screen opens.

**Acceptance criteria**

- Unused feature sync does not run during ordinary Home startup.
- A feed configured to use packs/favorite relays still has its local source data before its first query.
- Upload and subscription flows continue to obtain current settings when invoked.

### P2 — Reduce relay discovery and retry churn without breaking the active feed

- [ ] Preserve connection to the relay set needed for the selected feed and the current user's cached relay list.
- [ ] Replace forced current relay-list/contact-list refresh on every launch with a freshness-aware cache-first refresh.
- [ ] Resolve missing contact relay lists in bounded batches and only when gossip/following-feed behavior requires them. Do not remove relay discovery blindly; it may be necessary for configured feeds.
- [ ] Confirm the intended REMOTE_CACHE behavior. If remote cache is disabled/unavailable, skip connecting it. If enabled, use capped exponential backoff and pause/retry appropriately across app lifecycle changes.
- [ ] Review the app's 10-second reconnect loop, core 10-second flush, and one-minute DNS check for overlap. Retain required reliability behavior, but avoid tight retry loops and background work.
- [ ] Coalesce repeated reconnect requests from app lifecycle and connectivity callbacks.

**Acceptance criteria**

- The active feed remains usable through normal network changes.
- A failed optional remote-cache endpoint does not retry indefinitely on a fixed short interval.
- Relay lists and missing contact relay metadata are not force-refetched on every ordinary launch.
- App background/resume does not create a burst of duplicate reconnect or feed operations.

### P2 — Constrain media playback and defer platform/cache work

- [ ] Review the default for embedded autoplay. Prefer an explicit user preference with a conservative default, or restrict autoplay by visible viewport and network type.
- [ ] Ensure only the visible player is actively buffering/playing. Pause or release offscreen players and pause playback on backgrounding, while preserving any intentional fullscreen behavior.
- [ ] Ensure wakelock is enabled only during active playback/fullscreen and reliably disabled on pause/dispose.
- [ ] Move availableCameras() to the composer/camera entry point.
- [ ] Move database/media cache-size measurement to the cache settings page or an explicit maintenance action. Verify whether CacheExceedsSizeContainer in leading_view.dart is unused before removing or reconnecting it.
- [ ] Review the 100 MB decoded image-cache ceiling and the 500-event feed cap with runtime memory measurements before changing them. Avoid a global cache reduction that causes excessive image reloads.
- [ ] Review the 2 GB cache threshold and retention rules. Preserve DM data and the current user's own events unless a separate product decision explicitly changes retention.

**Acceptance criteria**

- Videos do not start buffering solely because an embedded player widget was built when autoplay is not allowed.
- Backgrounding releases/pause video resources and wakelock.
- Camera discovery and cache-size scans do not run on ordinary Home startup.
- Any memory/cache-size change is supported by measurements and does not cause repeated media fetches or data loss.

## Suggested implementation order

1. Make Discover/Media lazy, remove duplicate leading suggestions, and suspend inactive feed polling.
2. Move wallet and feature-only HTTP requests to their owning views/actions.
3. Split DM history backfill and notification history from the minimum live/badge behavior.
4. Make relay/contact refreshes cache-first and bound optional cache/reconnect retries.
5. Adjust autoplay, cache scans, and memory limits after observing behavior on representative devices.

Each implementation change should be kept narrow enough to review against its acceptance criteria. Prefer a small ensure-initialized or feature-entry boundary over deleting global cubits; existing global consumers may still rely on those instances.

## Risks and decisions to preserve

- Do not delay the selected feed's local source/filter settings; they determine what the initial request should fetch.
- Do not remove current-user metadata, mute filtering, outbox retry, or opted-in notification behavior as a side effect of deferring other features.
- DMs have a visible unread indicator. Deferring DMs must preserve its expected behavior with a cheap local summary or a deliberately chosen live path.
- The drawer displays wallet balances. Keep Lightning balance warm for quick zaps, load fiat rates on drawer open, and initialize Cashu when the drawer is opened in Cashu mode.
- Nostr queries can be cache-first or relay-fanned. A 50-event limit is not a reliable estimate of bytes transferred. Validate actual network calls rather than multiplying limits into assumed traffic.
- The current UI mounts only visited tab bodies, so avoid attributing all image/video downloads to the offscreen feed cubits. Feed event requests and media-file requests are separate cost sources.
- Do not introduce blanket database clearing or shorten protected-event retention as a performance shortcut.

## Handoff notes

- The initial investigation was static and source-based. It did not measure network bytes, startup duration, CPU, memory, or energy on a device. Treat impact labels above as likely relative priorities, not measured savings.
- The repository's Tokensave graph/database was unavailable during the audit; findings were checked against the current source tree. Re-check implementation details before changing code.
- The working tree already contained unrelated uncommitted changes, including edits to files named in this plan such as lib/initializers.dart, feed cubits, lib/logic/main_cubit/main_cubit.dart, and video/UI files. Before implementation, inspect git status and relevant diffs; preserve and build on the user's existing edits. Do not reset, revert, or overwrite them.
- The checked wallet/Cashu tasks in this worktree implement the completed subset above. Other uncommitted application changes predate this work and have been preserved.
