# Changelog

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
