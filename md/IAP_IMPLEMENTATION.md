# YakiHonne IAP Implementation Guide

## Context

YakiPro (`/Users/MAC/Desktop/Work/Flutter projects/Yaki/yaki_pro`) already has a complete IAP
implementation. YakiHonne is a separate Flutter app that needs the same treatment. Use YakiPro
as the reference implementation throughout.

## App Identifiers

|                    | YakiPro             | YakiHonne                    |
| ------------------ | ------------------- | ---------------------------- |
| iOS Bundle ID      | `com.yakihonne.pro` | `com.yakihonne.appyakihonne` |
| Android Package    | `com.yakihonne.pro` | `com.yakihonne.yakihonne`    |
| Apple ID (numeric) | `6783617216`        | `6472556189`                 |

## Product IDs

Same strings for both apps (registered separately in each app's store listing):

- `yakihonne_creator_monthly` — maps to Creator plan (`basic`)
- `yakihonne_pro_monthly` — maps to Pro plan (`premium`)

## Backend — Already Complete

Backend at `/Users/MAC/Desktop/Work/Web/yaki-api` is fully updated and handles both apps:

- `POST /api/v1/iap/validate` — validates receipts for both YakiPro and YakiHonne product IDs
- `POST /apple-iap-notifications` — has verifiers for both bundle IDs
- `POST /android-iap-notifications` — uses `notification.packageName` from Pub/Sub payload

No backend changes needed.

## Key Design Decisions

### kIapEnabled flag

```dart
const kIapEnabled = true; // false for APK/sideload builds → enables Stripe + Lightning
```

- `true` → IAP for platform subscription, creator subscriptions read-only
- `false` → Stripe + Lightning enabled, creator subscriptions fully interactive

### Platform subscription

Goes through IAP on store builds. Same flow as YakiPro.

### Creator subscriptions

Read-only on store builds (`kIapEnabled = true`). The subscribe buttons are hidden/disabled.
On APK builds (`kIapEnabled = false`), fully interactive as before.

### Web-managed subscription

If a user subscribed via Stripe/Lightning and opens the app on a store build, show
"Your subscription is active." — no external links (Apple guideline 3.1.3).

---

## Implementation Steps

### Step 1 — `pubspec.yaml`

Add dependency:

```yaml
in_app_purchase: ^3.2.0
```

Run `flutter pub get`.

### Step 2 — Constants

Find the constants file (likely `lib/utils/constants.dart` or similar). Add:

```dart
// IAP product IDs
const kIapCreatorProductId = 'yakihonne_creator_monthly';
const kIapProProductId     = 'yakihonne_pro_monthly';

// Set false for APK/sideload builds → enables Stripe + Lightning instead of IAP
const kIapEnabled = true;
```

### Step 3 — Android Manifest

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:

```xml
<uses-permission android:name="com.android.vending.BILLING"/>
```

### Step 4 — iOS Podfile

In `ios/Podfile`, ensure the platform line is uncommented and set to 13.0:

```ruby
platform :ios, '13.0'
```

### Step 5 — iOS IAP Capability

In Xcode: open `ios/Runner.xcworkspace` → Runner target → Signing & Capabilities →
`+ Capability` → **In-App Purchase**.

### Step 6 — HTTP Repository

Find `lib/repositories/http_functions_repository.dart`. Add `yakiProValidateIap()` method
following the same pattern as other `yakiPro*` methods. Reference the YakiPro version at
`/Users/MAC/Desktop/Work/Flutter projects/Yaki/yaki_pro/lib/repositories/http_functions_repository.dart`.

The method POSTs to `/api/v1/iap/validate` with:

```dart
{
  'platform': platform,   // 'ios' or 'android'
  'receipt': receipt,
  'product_id': productId,
}
```

### Step 7 — Pricing Screen

File: `lib/views/subscription_view/pricing/pricing_screen.dart`

Reference: `/Users/MAC/Desktop/Work/Flutter projects/Yaki/yaki_pro/lib/views/pricing/pricing_screen.dart`

Changes needed:

1. Add imports:

```dart
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
```

2. Add to state class:

```dart
StreamSubscription<List<PurchaseDetails>>? _iapSub;
final Map<String, ProductDetails> _iapProducts = {};
bool _restoringPurchases = false;

bool get _useIap => kIapEnabled;
```

3. In `initState`, start IAP if enabled:

```dart
if (_useIap) startIap();
```

4. Add `startIap()`, `_queryIapProducts()`, `_handlePurchaseUpdate()`,
   `_checkoutIap()`, `_restorePurchases()` — copy from YakiPro reference,
   replacing `yakiProAuthCubit.refreshSubscriptionStatus()` with
   `subscriptionCubit.refreshStatus()`.

5. Update `_checkout()`:

```dart

Future<void> _checkout(PricingPlan plan) async {
  setState(() => _loadingPlanId = plan.id);
  try {
    if (_useIap) {
      await _checkoutIap(plan);
    } else if (_isLn) {
      await _checkoutLightning(plan);
    } else {
      await _checkoutStripe(plan);
    }
  } catch (_) {
    if (mounted) setState(() => _loadingPlanId = null);
  }
}
```

6. In `build()`, compute web-managed state:

```dart
final lastPaymentMethod = subscriptionCubit.state.subscriptionStatus?.lastPaymentMethod ?? '';
final isActivePaidSub = subscriptionCubit.state.subscriptionStatus?.active == true
    && subscriptionCubit.state.subscriptionStatus?.inTrial == false;
final isWebManaged = _useIap && isActivePaidSub && lastPaymentMethod != 'iap';
```

7. Hide USD/Sats toggle when IAP:

```dart
onToggleLn: _useIap ? null : (v) => setState(() => _isLn = v),
```

Make `onToggleLn` nullable in `PricingHeroHeader` if not already.

8. Add web-managed banner sliver (when `isWebManaged`) above plan cards — see YakiPro reference.

9. Pass `onCheckout: isWebManaged ? null : () => _checkout(plan)` to `PlanCard`.
   Make `onCheckout` nullable in `PlanCard` if not already.

10. Add "Restore purchases" `TextButton` sliver below plan cards when `_useIap`.

11. Dispose `_iapSub` in `dispose()`.

### Step 8 — Subscription Section

File: `lib/views/subscription_view/widgets/subscription_section.dart`

Reference: `/Users/MAC/Desktop/Work/Flutter projects/Yaki/yaki_pro/lib/views/settings/widgets/subscription_section.dart`

Changes needed:

1. Remove `import 'package:flutter/foundation.dart';` if only used for `kIsWeb`.

2. Replace `isOnMobile` / `kIsWeb` checks with `kIapEnabled`.

3. Add derived booleans:

```dart
final isStripeActive = s.lastPaymentMethod == 'stripe' && s.active;
final isIapActive = s.lastPaymentMethod == 'iap' && s.active;
final showStripeControls = isStripeActive && !kIapEnabled;
final showWebManagedBanner = kIapEnabled && s.active && !isIapActive
    && !s.inTrial && s.lastPaymentMethod.isNotEmpty;
```

4. Gate Stripe controls:

```dart
if (showStripeControls) ... // plan switcher
if (s.inTrial || showStripeControls) ... // cancel/resume actions
```

5. Add "Manage on Store" button when `kIapEnabled && isIapActive`.

6. Add web-managed banner when `showWebManagedBanner` — text: "Your subscription is active."

7. Add `PaymentMethodLabel` handling for `'iap'` — shows Apple/Android icon + store name.

8. Add `_ManageOnStoreButton` widget — deep-links to:
   - iOS: `https://apps.apple.com/account/subscriptions`
   - Android: `https://play.google.com/store/account/subscriptions`

### Step 9 — Creator Subscribe View

File: `lib/views/creator_subscribe_view/creator_subscribe_view.dart`

Two places need a `kIapEnabled` gate:

**`_ProviderCard` (line ~184)** — the "Subscribe" button:

```dart
onPressed: kIapEnabled || provider.url.isEmpty ? null : () => _onSubscribe(context),
```

**`_PlanCard` (line ~561)** — the "Subscribe Now" button:

```dart
onPressed: kIapEnabled ? null : () => _onSubscribe(context, isLoading),
```

No other changes needed — the plans still display, just the action is disabled on store builds.

---

## i18n Keys to Add

Add to the app's translation file (e.g. `lib/i18n/en.json` or equivalent):

```json
"pricing_restore_purchases": "Restore purchases",
"pricing_manage_on_store": "Manage subscription",
"pricing_web_managed": "You have an active subscription managed at yakihonne.pro. Visit there to change or cancel your plan.",
"sub_managed_via_web": "Your subscription is active."
```

Run the translation generator after adding keys (e.g. `dart run slang`).

---

## Store Setup (Pending)

### App Store Connect

1. Open YakiHonne app → Monetization → Subscriptions
2. Create subscription group (e.g. "YakiHonne Pro")
3. Add two Auto-Renewable Subscriptions:
   - Product ID: `yakihonne_creator_monthly` — $11.99/month
   - Product ID: `yakihonne_pro_monthly` — $22.99/month
4. After backend deploy: register App Store Server Notifications URL →
   `https://yourdomain/apple-iap-notifications`

### Google Play Console

1. Open YakiHonne app → Monetize → Subscriptions
2. Create two subscriptions with same product IDs
3. Link service account: Setup → API access
4. After backend deploy: configure Pub/Sub push →
   `https://yourdomain/android-iap-notifications`

---

## Reference Files (YakiPro — already implemented)

| What                               | Path                                                            |
| ---------------------------------- | --------------------------------------------------------------- |
| Pricing screen (full IAP)          | `yaki_pro/lib/views/pricing/pricing_screen.dart`                |
| HTTP repo (yakiProValidateIap)     | `yaki_pro/lib/repositories/http_functions_repository.dart`      |
| Subscription section               | `yaki_pro/lib/views/settings/widgets/subscription_section.dart` |
| Constants (kIapEnabled)            | `yaki_pro/lib/utils/constants.dart`                             |
| Plan card (nullable onCheckout)    | `yaki_pro/lib/views/pricing/widgets/plan_card.dart`             |
| Pricing hero (nullable onToggleLn) | `yaki_pro/lib/views/pricing/widgets/pricing_hero.dart`          |
