# Changelog

## [2.0.8] - 2026-09-17

### Added

- Video editor and video compressor before publishing.

### Changed

- Engagement chart enhancements.

### Fixed

- GrapheneOS feed issue where notes failed to load.
- Note preview before publishing is now scrollable.
- Paid notes payment issue.
- Notification tap no longer shows "notification not found" when the note isn't in the local DB yet.
- Replies not showing under some notes.

## [2.0.7] - 2026-08-31

### Added

- Kind 1111 (NIP-22) comment support in notes and replies.
- Free plan card and a side-by-side plan comparison in pricing.
- Premium badge and a "Seen on" relay indicator.
- Landscape support for video playback.

### Changed

- Rewritten paid-note payment flow with live tracking, auto-publish, and a new published-confirmation screen.
- Username now always shown in edit profile, with connect and upgrade prompts when needed.
- Second Reader AI actions now match each paragraph's feedback, and the AI assistant stays open after processing.

### Fixed

- SSE stream now re-logs in on an expired session and retries.
- Payment sheet no longer leaves stale invoices behind when closed.
- Removed the 800 sats payment preset from zaps.
- General bug fixes and performance enhancements.

## [2.0.6] - 2026-08-20

### Added

- Added Ask AI to improve, rewrite, retone, or expand any part of an article without leaving the editor.
- Added Second Reader to pick a reader persona and see how they would react to your draft, paragraph by paragraph.
- Added Energy Mapper, a per-sentence emotion graph of your note, to spot flat or overheated passages before publishing.
- Added Yakihonne plans in-app, with a usage dashboard and subscription badges.
- Added direct creator subscriptions from their profile.
- Added Fluid mode, a glass look across the app with blurred surfaces and translucent sheets.
- Added Google sign-in for new accounts.
- Added encrypted key backup and recovery from settings.
- Added gift code redemption straight from a DM.
- Added a guided tour on first launch and a what's new screen after major updates.
- Added flip to share on notes.

### Changed

- Redesigned bottom navigation.
- Reworked search, discover, profile, and note stats.

### Fixed

- General bug fixes and performance enhancements.

## [2.0.5] - 2026-05-14

### Changed

- Moved nested comments to Feed customization.
- Disabled followings notifications by default.
- Updated description in Blossom management upload view.
- Enabled internal view opening for Blossom management items.
- Adjusted mirror functionality in Blossom management options.
- Optimized videos prefetching.

### Fixed

- Fixed videos thumbnails not loading in Blossom management.
- Fixed quote functionality.
- General bug fixes and performance enhancements.

## [2.0.4] - 2026-04-30

### Added

- Launched interactive DM Gifts.
- Introduced Blossom server management.
- Added NIP-22 comment support for articles and videos.

### Changed

- Optimized relay sharing links with direct content parameters.
- Simplified relay invitation UI to "Share".
- Unified feed settings by moving nested replies configuration.
- Improved relay browsing experience from the homefeed.
- Added relay sharing capability within the Orbits view.
- Improved relay joining with automated connection timers.

### Fixed

- Fixed relay filtering when posting notes in Relay Orbits.
- Added automatic state reset for paid note progress.
- Resolved layout and keyboard overlap on relay join requests.
- General bug fixes and performance enhancements.

## [2.0.3] - 2026-03-29

### Added

- Added relay review.
- Added relay join request.
- Added expanded nested replies in notes
- Added nsec saving to ios keychain
- Added option to autotranslate note in 3 seconds.
- Added support for nwc multi relays.
- Added pending paid notes in dashboard.
- Added imeta tag to when publishing notes and articles.

### Changed

- Added expired content ignore.

### Fixed

- Fix pasting text in private message not working.
- Fix profile fetching issue.
- Fix screen orientation in youtube links when trying fullscreen mode.
- Fix paid notes not being submitted issue.
- Fix notification refresh when switching to view.
- Other bug fixes and performance improvements.

## [2.0.2] - 2026-03-01

### Added

- Started packs support.
- Media packs support.
- Relay based trending notes.
- Scheduled notes.

### Changed

- Added messages non blocking sending & queueing.
- Added messages deletion (single/multi).
- Added note and its reply rendering in messages.
- Added ability to enable/disable actions popups.

### Fixed

- Fix ecash wallet creation.
- Fix sharing not function on ios 26.
- Fix duplication when adding relays to lists.
- Fix currencies update issue.
- Fix hashtags with greek language not recognized.
- Fix note text display issue (unsupported fonts).
- Adjusted muted thread by adding message box.
- Other bug fixes and performance improvements.

## [2.0.1] - 2026-01-29

### Added

- Ecash implementation.
- Note deletion.

### Changed

- Add gesture detector on the image box when tryin to upload an image in article publishing.
- Improve database indexing for faster data loading.

### Fixed

- Fix adding relay manually is not working when creating a relay set.
- Fix mute thread in search is not working.
- Fix relay list is not showing on user profile.
- Fix app audio taking priority over other audios from other running apps.
- Bug fixes and performance improvements.

## [1.9.8] - 2026-01-02

### Changed

- Add option to disable auto-play.
- Add option to copy note text.
- Add support for qt, 3gp videos & support for ipfs media.
- Add content warning for media.

### Fixed

- Fix media upload issue.
- Fix sharing media issue.

## [1.9.7] - 2025-12-23

### Added

- Introducing Media feed (videos, images).
- Added profile pinned notes.

### Changed

- Add RTL directionality in Articles' editor.
- Profile sections reworked.
- Added mentions section in profile.
- Load latest selected sources on startup.
- Re-scroll to the top of feed when changing options.

### Fixed

- Fix Amber encryption syncing & Amber nip44 event decryption issue.
- Fix messages not being fetched from dm relays.
- Fix "nostr:" not working in search.
- App stability improvements.
- Bug fixes & performance improvements.

## [1.9.6] - 2025-12-02

### Fixed

- Fix scrolling stuck behaviour.
- Fix nostr scheme decoding issue.
- Fix audio controller not being dismissed properly.

## [1.9.5] - 2025-11-25

### Added

- Add relays sets.
- Add russian language.

### Changed

- Fetch events from the relays encoded in the nostr scheme in search.
- Optimise note view.
- Add option to mute notifications with more than 10 mentions.

### Fixed

- Fix click on tag issue in search page.
- Fix search relays update overrides user regular relay list.

## [1.9.4] - 2025-11-17

### Added

- Add mute thread option
- Optimized search with dedicated search relays for faster and more accurate results
- Ability to change app primary color

### Changed

- Nostr scheme render for yakihonne and other nostr clients inside the app
- Add option to enable/disable url previews
- Add youtube preview
- Add split screen tab in writing article on tablets
- Make following in relay orbits as default
- Add smart widget render in feed
- Add cover, "t" and "r" for bookmarks
- Add video fallback urls
- Add video download
- Add blitz wallet

### Fixed

- Fix currencies symbols
- Fixed various bugs across the app
- Remove "App" from basic smart widget

## [1.9.3] - 2025-11-03

### Added

- Support for onion relays connectivity.
- Other currencies in the wallet.

### Changed

- Forward notifications to their respective views.
- Favorite relays, settings relays, interests in dashboard (Add data to the top of list).
- Add relay in event encoding when sharing content.
- Accept only njump.me and nostr.com Nostr scheme rendering.
- Make article drafts clickable, and change the behavior on already fetched articles to take drafts to edit not article view.
- Added "," to the URL regex.

### Fixed

- Fixed points system not functioning well.
- Fixed content actions disable not updating.
- Fixed GIF display.
- Fixed sharing intent opening files in YakiHonne.
- Fixed display names.
- Fixed database blocking issue.

## [1.9.2] - 2025-10-21

### Added

- Receive share intent in-app
- Rearrange action buttons
- Add Hindi language
- Blur images for non-followers

### Changed

- Updated URLs (/r/notes, /r/content)
- Better GIF sizing
- Loading indicator in search bar
- Paginated transactions list
- Added DM loader & empty feed placeholder

### Fixed

- Resolved note display, zap split, and nostr URL issues
- Fixed QR scanning, redeem controller, and shareable links
- Fixed unfollow button, mentions, and nip05 handling
- Improved notifications sync and stats loading with WoT
- Fixed nsec bunker setup, article markdown, and Blossom upload
- Reset search scroll position and made suggestions scrollable

## [1.9.1] - 2025-10-05

### Added

- Redesigned app bar and new themes: Black & Ivory.
- Database-first architecture with offline mode.
- Relay orbits for relays discoverability and management.
- Nsec bunker integration.
- New content box and updated video types.
- Default custom reactions added.

### Changed

- Republishing & broadcasting of events integration.
- Improved feed for large screens (single column).
- Clickable relay URLs in notes.
- Support for nostr scheme from other URLs.
- Optimized performance, notifications, and mentions.
- Optimized content sharing experience & newely added image sharing option.
- Optimized fetching and searching.
- Overall performance optimization.

### Fixed

- General bug fixes and improvements.

## [1.8.6] - 2025-08-19

### Added

- Add redeeming feature.
- Add slidable message reply.

### Changed

- Remove gossip model popup.
- Remove muted user from feed.

### Fixed

- Fix sharing issue gets stuck.
- Fix loading mutes list at app start.
- Fix issue with connecting a new amber account.
- Fix one tap zap not triggering external wallet.

## [1.8.5] - 2025-08-12

### Changed

- Add relay functionality on the relays feed.
- Forward deleted account to login or first connected account.

### Fixed

- Fix notification view not showing loading icon.
- Fix audio regex having video extension.

## [1.8.4] - 2025-08-07

### Fixed

- Fix issue where content translation is not displayed.

## [1.8.3] - 2025-08-05

### Changed

- Adding support for local relays in the relays feed settings.

### Fixed

- Fix RTL text directionality in content rendering.
- Fix keyboard getting dismissed when attempting account deletion.
- Fix suggested profiles duplicates in account creation.

## [1.8.2] - 2025-08-03

### Added

- **Cache Management**: Automatic cache purging functionality
- **Translation Service**: Support for custom translation service
- **Relay Search**: Search functionality in relays feed settings
- **RTL Support**: Right-to-left language support for note editor
- **Image Display**: Support for base64 images display
- **Profile Enhancement**: Render support for profile about content

### Changed

- General improvements and performance enhancements

### Fixed

- Resolved various bugs and issues

## [1.8.1] - 2025-07-23

### Added

- **WOT Configuration**: Support for Web of Trust configuration
- **BLOSSOM Support**: Integration with BLOSSOM protocol
- **Relay Management**: Support for favorite and DMs relays
- **Payment Integration**: Payment support for smart widgets
- **Internationalization**: Added Arabic and French language support
- **Media Upload**: Enable image pasting functionality

### Changed

- **Zapping Experience**: Complete rework with ability to switch between external and internal zapping
- **Smart Widget AI**: Now enabled by default

### Fixed

- Resolved various issues and bugs
- General improvements and performance enhancements
