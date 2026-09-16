# Pricing Configuration — CraveFade

## Monetization Model: Subscription (IAP) + Lifetime Buyout

Free-forever core loop with generous free tier; auto-renewable Pro subscription (monthly/yearly) plus a one-time lifetime buyout (compliant: on-device Foundation Models + BYO DeepSeek = zero ongoing marginal cost). NO weekly subscription tier (deliberate anti-pattern avoidance). BYO DeepSeek key users get unlimited deep features with their own key.

## Subscription Group
- **Group Name**: CraveFade Pro
- **Reference Name**: CraveFade Pro
- **Products in group**: `com.zzoutuo.CraveFade.pro.monthly`, `com.zzoutuo.CraveFade.pro.yearly`

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription
- **Reference Name**: CraveFade Pro Monthly
- **Product ID**: `com.zzoutuo.CraveFade.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $4.99 USD per month
- **Display Name**: `CraveFade Pro Monthly` (21 chars, ≤35 ✅)
- **Description**: `Unlimited AI coach, forecasts, deep mode, buddies` (49 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: CraveFade Pro
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription (Primary — default highlighted on paywall)
- **Reference Name**: CraveFade Pro Annual
- **Product ID**: `com.zzoutuo.CraveFade.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $29.99 USD per year (≈$2.50/mo, 50% savings vs monthly)
- **Display Name**: `CraveFade Pro Annual` (20 chars, ≤35 ✅)
- **Description**: `Best value: all Pro features, 7-day free trial` (46 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: CraveFade Pro (same group as monthly)
- **Restore Purchases**: ✅ Required

## One-Time Purchases (Non-Consumable)

### 1. Pro Lifetime
- **Reference Name**: CraveFade Pro Lifetime
- **Product ID**: `com.zzoutuo.CraveFade.pro.lifetime`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $59.99 USD (one-time)
- **Display Name**: `CraveFade Pro Lifetime` (22 chars, ≤35 ✅)
- **Description**: `All Pro features forever. One-time purchase` (43 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Note**: Compliant buyout — on-device AI + user-provided DeepSeek key = no ongoing server/AI cost. Future cloud-cost features must ship as separate tiers, never retroactively into this product.
- **Differentiation Note**: Same feature set as subscription at a higher one-time price — "pay once, never again" value proposition for committed users; subscriptions exist for users who prefer lower upfront cost.

## Free Tier (Default)

- **Price**: Free (forever)
- **Features**:
  - Unlimited puff logging via all 8 entry points (Watch, Widget, Control Center, Action Button, Back Tap, Siri, Live Activity, in-app)
  - Taper plan engine (default 10–20%/week slope) + projected quit date
  - Unlimited 90-second breathing SOS (offline) + bedtime variant + hand task
  - Money-saved calculator (verifiable formula) + recovery timeline (basic)
  - On-device AI coach 3 sessions/day (Apple Foundation Models — zero marginal cost)
  - Full history editing (any date backfill/correction)
  - iCloud sync + 1 Quit Buddy
- **Conversion hooks**:
  - "Free forever core. Price on the box." — prices visible in screenshots and paywall
  - "Your AI coach is on-device and free — 3 chats a day. Go unlimited for less than one pod."
  - Slip ≠ Reset: weekly achievement %, money saved, and recovery progress never reset (trust layer)

## Pro Features Unlocked (All Paid Tiers)

⚠️ Cross-referenced with `capabilities.md` (PHASE 2) — all features below are implemented in PHASE 4+5.

| Feature | Free | Pro (All Paid Tiers) |
|---------|:----:|:--------------------:|
| Puff logging (8 entry points) | ✅ Unlimited | ✅ Unlimited |
| Taper plan (default slope) | ✅ | ✅ Custom slope 10–20%/week |
| 90s breathing SOS | ✅ Unlimited | ✅ Unlimited |
| On-device AI coach (Foundation Models) | ✅ 3 sessions/day | ✅ Unlimited |
| BYO DeepSeek deep mode (pod scan + weekly report) | ❌ Hidden until Pro or key + Pro | ✅ Unlimited (user's own key) |
| Craving forecast + proactive push | ❌ | ✅ |
| Full history heatmap | ✅ Basic calendar | ✅ Full heatmap |
| Bedtime SOS mode | ✅ | ✅ |
| Quit Buddies | ✅ 1 | ✅ 5 |
| iCloud sync | ✅ | ✅ |
| History editing | ✅ | ✅ |
| Widgets / Watch / Live Activity | ✅ | ✅ |
| Manage subscription direct link | ✅ | ✅ |

**BYO Key Model note**: Users who purchase Pro AND configure their own DeepSeek key get unlimited deep-mode usage — the subscription unlocks app features (forecast, unlimited coach, buddies), never meters AI usage. `canGenerate = isPro || hasAPIKey || fmAvailable`.

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid subscription)
- **Available for**: CraveFade Pro Annual (`pro.yearly`) only

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView ($4.99/mo · $29.99/yr · $59.99 once)
- [x] Free trial terms included (7-day, yearly tier)
- [x] Restore purchases functionality implemented
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options (no competitor price comparisons in paywall copy)
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] IAP type purity: subscriptions in group "CraveFade Pro"; lifetime non-consumable listed separately
- [x] Lifetime buyout compliance: zero ongoing marginal cost features only
