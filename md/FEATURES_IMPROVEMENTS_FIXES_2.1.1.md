# Features, Improvements, and Fixes — 2.1.1

Completed mobile-app work for version 2.1.1.

## Features

## Improvements

- **Profile notes filter:** Add an All option that combines notes, replies, mentions, highlights, and pinned items, removing duplicates.

## Fixes

- **Stability:** Handle missing device sensors, unavailable cameras, push initialization failures, early notification taps, and late callbacks without crashing.
- **Media:** Handle video export failures, prevent callbacks after closing media views, support localized image editor dialogs, and display picture posts without thumbnails safely.
- **Wallets and payments:** Handle wallet creation timeouts, show Cashu redemption results safely, and prevent malformed zap invoices from crashing notifications.
- **Notes and messaging:** Fix scrolling after sending a message, copying repost IDs, scheduled-note updates, Markdown selections, autocomplete searches, and malformed Nostr address links.
- **Accounts and data:** Handle account changes during navigation and contact updates, malformed points records, empty dashboard pagination, late statistics events, and automatic cache purges at startup.
