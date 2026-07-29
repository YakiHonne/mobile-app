## New endpoints (Routers/Points.js)

### GET /api/v1/points/config
Auth: auth_user
```json
{
  "subscription": { "basic": 10000, "premium": 20000 },
  "paid_note": { "free": 800, "basic": 400 },
  "redeem_code": {
    "cost": 1000,
    "limit": 1,
    "period_days": 7,
    "monthly_limit": 4
  }
}
```

### GET /api/v1/points/subscription-eligibility
Auth: auth_user
```json
{
  "points": 12500,
  "eligibility": {
    "basic": { "cost": 10000, "eligible": true },
    "premium": { "cost": 20000, "eligible": false }
  }
}
```

### POST /api/v1/points/subscription-redeem
Auth: auth_user · Body: { "plan": "basic" | "premium" }
```json
{ "success": true, "effective_at": 1782441600 }
```
Errors: 400 { "message": "plan must be basic or premium" | "Already on this plan" | "Insufficient points" | "Not eligible to redeem points for a subscription" | "<redeem error code>" }

### POST /api/v1/points/publish-paid-note
Auth: auth_user · No body
```json
{ "success": true, "points_spent": 400 }
```
Errors: 400 { "message": "Premium plan does not need points to publish a paid note" | "Insufficient points" }

### GET /api/v1/points/codes
Auth: auth_user
```json
{
  "codes": [
    {
      "code": "YR-CUK7YMBV",
      "amount": 1000,
      "status": false,
      "preImage": "",
      "reserved_at": 1782361038
    }
  ]
}
```

### POST /api/v1/points/codes/request
Auth: auth_user · No body
```json
{ "success": true, "code": "YR-CUK7YMBV", "amount": 1000 }
```
Errors: 403 { "message": "Your plan does not include this feature" }, 400 { "message": "Insufficient points" }, 429 { "message": "Redeem cooldown is still active for your plan" | "Monthly redeem limit reached for your plan" }, 404 { "message": "No codes available at the moment" }

### POST /api/v1/points/codes/redeem
Auth: auth_user · Body: { "code": string, "lightning_address": string }
```json
{ "success": true, "amount": 1000 }
```
Errors: 400 { "message": "lightning_address is required" | "Invalid lightning_address" | "Your code is being redeemed..." | "Code already redeemed" | "Could not redeem the code, please try again later." }, 404 { "message": "Code not found" }

## Edited endpoints (Routers/Ops.js)

### GET /api/v1/subscription-status
Auth: auth_user — now spreads the full Account document (matching /api/v1/online's pattern) instead of a hand-picked subset.
```json
{
  "pubkey": "...",
  "plan": "basic",
  "active": true,
  "last_payment_method": "stripe",
  "last_payment_method_display": "points",
  "last_subscription": 1781949600,
  "next_subscription": 1784951451,
  "cancel_at_period_end": false,
  "pending_plan": "premium",
  "pending_price_id": "price_...",
  "pending_original_price_id": "price_...",
  "pending_plan_since": 1782359451,
  "pending_plan_via_points": true,
  "last_subscription_redeemed": true,
  "stripe_customer_id": "...",
  "stripe_subscription_id": "...",
  "stripe_schedule_id": "...",
  "trial_ends_at": 0,
  "trial_used": true,
  "wallets": [],
  "history": [
    { "last_subscription": 1782359451, "last_payment_method": "points", "plan": "basic" }
  ],
  "last_reminder_at": 1781949600,
  "in_trial": false,
  "access_blocked": false
}
```

### GET /api/v1/usage
Auth: auth_user — added a "redeem-codes" entry (plus monthly_limit/monthly_used/monthly_reset_at on it) alongside the pre-existing feature entries.
```json
{
  "plan": "basic",
  "usage": {
    "chat-articles": { "label": "AI Writing Assistant", "period_type": "weekly", "limit": 0, "used": 0, "percentage": 0, "reset_at": 1782518400 },
    "wallet-creation": { "label": "Wallet creation", "period_type": "lifetime", "limit": 3, "used": 1, "percentage": 33, "reset_at": null },
    "redeem-codes": {
      "label": "Redeem codes with points",
      "period_type": "days",
      "limit": 1,
      "used": 0,
      "percentage": 0,
      "reset_at": 1782950400,
      "monthly_limit": 4,
      "monthly_used": 1,
      "monthly_reset_at": 1785625200
    }
  }
}
```
