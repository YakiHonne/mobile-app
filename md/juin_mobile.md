# **Juin report**

### **YakiHonne 2.1.6:**

- **Subscriptions / IAP** — in-app purchase support added, mirroring YakiPro's setup, with pricing/plans for Creator and Pro tiers.
- **Points system** — users can earn/spend points, check subscription eligibility, and redeem points toward a subscription.
- **Paid notes — pay with points** — paid notes can now be unlocked/published by redeeming points instead of only a Lightning invoice; redeem happens first, then the note publishes directly (no invoice wait).
- **Paid notes — free for subscribers** — Pro subscribers skip the paywall entirely and publish paid notes for free.
- **Paid note process reworked** — the paid-note confirmation/payment step was rewritten to support the points path alongside the existing invoice path.
- **Paid note promotion card** — a new ad-style card in the feed promoting paid notes to non-subscribers.
- **Editor — markdown engine rebuilt** — the note/article composer's text-input/formatting engine was largely rewritten.
- **Editor — AI assistance** — an "Ask AI" panel added to the article editor to help while drafting.
- **Editor — energy mapper nudge** — a banner in the note composer promoting the new energy mapper tool.
- **Energy mapper** — a new standalone tool/feature.
- **Second reader** — a new standalone feature.
- **Glass / Fluid UI mode** — a new translucent visual theme rolled out across the main screens.
- **Google Sign-In (Pomegranate)** — Google login flow added, including account/key recovery.
- **Other improvements** — reworked media (video/picture) playback, richer note stats, flip-to-share, and general bug fixes.

### **YakiHonne 0.0.1:**

- **Glass / Fluid UI mode** — new translucent visual theme rolled out across the app's theme system and main screens.
- **Google Sign-In (Pomegranate)** — Google login added to the login screen, plus account/key recovery in settings.
- **Login screen redesign** — brand column, gradient blobs, card, and layout/method widgets reworked.
- **Home screen / navigation polish** — app bar, drawer, and nav bar updated for the new theme.
- **Points screen updated** — Yaki Points screen logic reworked to stay in sync with the shared points system.
- **Plans / pricing / subscribers screens touched** — updated alongside the shared subscription work.
- **Media screen updates** — grid/list view tweaks.
- **Settings updates** — settings app bar and keys section touched (tied to Google key recovery).
- **IAP** — already fully implemented going into June (this was the reference implementation YakiHonne's new IAP was modeled on); untouched this round since it was already complete.

### **Yaki Api:**

- **Receipt validation endpoint** — `POST /api/v1/iap/validate` accepts `platform`, `receipt`, `product_id`, validates it, and activates the subscription on the account.
- **Shared product-ID convention** — `<app>_<plan>_monthly` (e.g. `yakipro_creator_monthly`, `yakihonne_pro_monthly`), mapped to `creator → basic` / `pro → premium` plans and the correct bundle ID per app.
- **Apple verification, dual path** — supports StoreKit 2 (JWS-signed transactions, verified against Apple's root certs, prod+sandbox per bundle ID) and legacy StoreKit 1 receipts (via Apple's `verifyReceipt`, with automatic sandbox retry).
- **Android verification** — uses a per-package Google service account (`androidpublisher` API) to check subscription payment state; separate credentials for `com.yakihonne.pro` and `com.yakihonne.yakihonne`. A package with no configured credentials rejects the purchase rather than accepting it unverified.
- **Apple server notifications** — `POST /apple-iap-notifications` handles renewals/cancellations for both bundle IDs.
- **Android server notifications** — `POST /android-iap-notifications` handles Google Play's Pub/Sub push, routed by `packageName`.
- **Subscription activation logic** — centralized in `Helpers/YakiSubscribers.js` (`activateIapSubscription`), shared by the validate endpoint and both notification webhooks.
