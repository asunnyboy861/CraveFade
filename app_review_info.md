# App Review Information — CraveFade

## AI Features (BYO API Key Model)
- AI coach uses on-device Apple Foundation Models by default (iOS 26+): private, offline, no key needed. Reviewers on iPhone 15 Pro+ / iOS 26+ see AI features work out of the box.
- On devices without Apple Intelligence, users can optionally configure their own DeepSeek API key (Settings → AI Configuration). The key is stored in the iOS Keychain and sent only to api.deepseek.com.
- The app does NOT sell API keys or AI usage; any API cost is paid by the user directly to their provider.
- When no backend is available, core features (logging, taper plan, 90-second breathing SOS) fully work offline. AI buttons are disabled with guidance text — never clickable dead-ends.
- No free-generation counting gating logic exists; `canGenerate = isPro || hasAPIKey || appleIntelligenceAvailable`.

## HealthKit Integration
- Read-only access to resting heart rate, only after explicit user permission (Settings/Progress → "Apple Health (HealthKit)" section → "Sync HealthKit heart-rate insights" toggle).
- UI clearly identifies HealthKit with section header, icons (heart.text.square.fill / heart.circle.fill), a "Learn More" page (HealthKitInfoView), and a footer explaining data usage.
- The app never writes health data.

## Subscriptions
- Products: `com.zzoutuo.CraveFade.pro.monthly` ($4.99/mo), `com.zzoutuo.CraveFade.pro.yearly` ($29.99/yr, 7-day free trial), `com.zzoutuo.CraveFade.pro.lifetime` ($59.99 one-time, non-consumable).
- Paywall includes subscription title, length, price, auto-renewal disclosure, Privacy Policy and Terms of Use links below the subscribe buttons.
- "Manage subscription" deep link is permanently available at the top of Settings.

## Crisis-Safety Design (Compliance)
- AI coach includes crisis detection: any self-harm signal immediately presents a non-dismissible card with 988 and 1-800-QUIT-NOW tappable hotlines.
- Settings contains a permanent "self-help tool, not medical advice" disclaimer and hotline entry.
- No medical claims (no cure/treat/therapy promises) anywhere in the app.

## Required Links (In-App)
- Privacy Policy: https://asunnyboy861.github.io/CraveFade/privacy.html
- Terms of Use: https://asunnyboy861.github.io/CraveFade/terms.html
- Support Page: https://asunnyboy861.github.io/CraveFade/support.html

These links are accessible from: Settings → Legal, Settings → Support, and the Paywall (below subscribe buttons).

## Review Notes
- Age rating: 17+ (tobacco references). The app supports quitting vaping; no tobacco promotion.
- Privacy label: Data Not Collected. All data is stored on-device (SwiftData) with optional iCloud sync.
- Testing tip: on simulators Apple Intelligence is unavailable — configure a DeepSeek API key in Settings → AI Configuration to exercise Deep Mode, or simply use the breathing SOS which requires no backend.
