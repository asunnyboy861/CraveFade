# CraveFade - iOS Development Guide

> Translated and adapted from: `TR-20260915-烟消云散-操作指南.MD` (2026-09-15)
> Market: 🇺🇸 US-first | Category: Health & Fitness (Quit Vaping)
> Slogan: "Cravings fade in 3 minutes. Ride the wave."

## Executive Summary

CraveFade is a quit-vaping iOS app that transforms the quit app from a "check-in tool" into a "lifeguard for craving moments" — and is the only quit app that **never asks you to open it**. All logging entry points live outside the app (Watch, Widgets, Control Center, Action Button, Back Tap, Siri, Live Activity); the app body only contains reward content (money-saved animations, lung recovery timeline).

**Target audience**: US vapers trying to quit (17+), especially people burned by shame-based counters and predatory subscriptions.

**Key differentiators** (three-layer moat):
1. **Entry Layer**: 8 logging entry points — logging never opens the app.
2. **Intelligence Layer**: Dual-engine AI craving coach (exclusive in the category) — on-device Apple Foundation Models (free, offline, zero marginal cost) + BYO DeepSeek API key (pod photo nicotine estimation + deep weekly reports). Plus predictive intervention (proactive push before peak craving hours).
3. **Trust Layer**: Free forever complete loop, price on the box, Slip ≠ Reset (progress never goes to zero), local-first privacy (privacy label "Data Not Collected"), editable history.

## Competitive Analysis

| App | Strengths | Weaknesses | Our Advantage |
|-----|-----------|------------|---------------|
| PuffCount ($1M+ revenue) | Taper curve, recovery timeline, money calculator, one-tap puff log | ① Opening app to view progress triggers cravings ② Forced subscription, no free tier ③ Slip → shame → abandonment ④ No craving SOS | Fix all 4 pain points: external entry points, generous free tier, Slip ≠ Reset, 3-tier SOS |
| HalfPuff (2026-08) | 8 log entry points, 90s Nimbo breathing rescue, HealthKit recovery, free trigger insights, $4.99/mo $29.99/yr + buyout | Zero AI; predictions are static charts; no deep intelligence after buyout | On-device AI coach free 3x/day; predictive proactive push; BYO deep mode |
| Nixotine | Free SOS 3x/day; "slip only resets streak"; recovery timeline; Live Activity; $29.99/yr $6.99/wk | No AI coach; weekly sub $6.99 = deceptive-pricing complaint magnet | No weekly subscription (deliberate); unlimited Pro AI |
| QuitVape | 4 goal modes; ring progress UI; panic button; generous free tier | No AI, no prediction, no Watch | Watch app + AI + prediction |
| Puff Count: Track Puffs | Camera puff detection; 21-chapter guide; $2.99/mo $11.99/yr $39.99 buyout | Camera detection is a fake need (privacy awkward + misrecognition); static guide | Real AI coach instead of gimmicks |
| Puff Count: Quit Vaping Now | 375K users; Quit Buddies | $20/week pricing → review disaster zone | Transparent pricing, no weekly sub |
| iQuit (cigarettes) | Real-time AI craving coach — 2026 #1 conversion feature | Cigarettes only; $9.99/mo; no free AI | Vape-focused; on-device AI free tier |

**Three sentences that decide the win**:
1. Pure "logging + taper curve + breathing SOS" is red-ocean baseline — copying brings scraps.
2. The AI real-time craving coach is still EMPTY in the quit-vaping category (validated as the #1 conversion feature by iQuit in cigarettes).
3. The #1 review-killer is always deceptive pricing — "price on the box + generous free tier + one-tap cancel" is itself a customer-acquisition weapon.

## Apple Design Guidelines Compliance

- **Calm-Tech**: Dark-first (Cyber-Zen), single task per screen, NO infinite scroll anywhere in the app.
- **iOS 26 native**: Liquid Glass materials, SF Symbols animations, Dynamic Island, Lock Screen Live Activity.
- **Accessibility**: Dynamic Type full support, VoiceOver, one-hand reachability (core buttons in lower half of screen), Reduce Motion degrades animations. Large type, AA+ contrast — usable for 40+ users. Every gesture has a button equivalent.
- **Color emotion rules**: Primary gradient cyan-blue → mint green (recovery/fresh); SOS surf ripples: indigo-violet; **red is ONLY used for "craving won" celebration**; slip events = warm amber ("continue", never "warning").
- **Health apps**: No medical claims (cure/treat/therapy forbidden); fixed disclaimer in Settings + 1-800-QUIT-NOW entry.
- **Widgets/Live Activity/Watch**: Follow HIG for WidgetKit, ActivityKit, WatchKit; complications use accessory families.

## Technical Architecture

- **Language**: Swift 6 (strict concurrency), SwiftUI
- **Data**: SwiftData (primary store, local-first) + CloudKit mirror sync; single shared `ModelContainer` via App Group (`group.com.zzoutuo.CraveFade.shared`); `Database.shared` singleton. All entry points (Watch/Widget/Siri) write to the same database — no count drift.
- **AI**: Apple FoundationModels (iOS 26+, on-device, structured `@Generable` output) with degradation chain: FM available → use FM; unsupported device → prompt BYO DeepSeek key; neither → pure breathing SOS (features never collapse).
- **Cloud AI**: DeepSeek API (BYO key stored in Keychain, direct connection to api.deepseek.com, developer server zero-touch). Vision: pod photo nicotine estimation. Reasoning: deep weekly reports.
- **IAP**: StoreKit 2 (subscription group "pro" + non-consumable lifetime).
- **Intents**: App Intents (LogPuffIntent, `openAppWhenRun = false`) shared by Widget/Control Center/Siri/Action Button/Back Tap.
- **Notifications**: UNUserNotificationCenter, per-item precise DateComponents registration (no coarse daily-repeat), full reschedule after every data update.
- **HealthKit**: read-only comparison (resting HR, sleep vs puff decline).

### Critical engineering decisions (locked before coding)
1. **Local-first**: SwiftData primary, CloudKit sync mirror only → no backend, zero server cost, privacy label "Data Not Collected".
2. **AI degradation chain**: FM → BYO DeepSeek → pure breathing SOS.
3. **Single source of truth**: all entries write via shared App Group + same ModelContainer; UUID idempotency dedupes concurrent writes.
4. **Event immutability**: `PuffEvent` insert-only; history edits = new `CorrectionEvent` offset records (audit trail preserved; stats computed as net values).
5. **Honesty gates**: prediction/weekly report/health-correlation features require ≥5 days of data; otherwise show "X more days of data needed".
6. **Plan changes never delete data**: switching taper plan/goal mode never recomputes/loses history or money totals.
7. **Verifiable money math**: money saved = event count × (user-entered unit price ÷ puffs per unit); formula transparent and tappable.
8. **Medical compliance**: no "treatment/cure/medical" claims anywhere; fixed Settings disclaimer + 1-800-QUIT-NOW.
9. **Buyout compliance**: lifetime non-consumable only because on-device FM + BYO DeepSeek = zero ongoing marginal cost. Future cloud-cost features must use separate consumable/subscription tiers, never retroactively into lifetime.

## Module Structure

```
CraveFade/
├── App/
│   ├── CraveFadeApp.swift
│   └── RootView.swift
├── Models/ (SwiftData)
│   ├── PuffEvent.swift
│   ├── CravingEvent.swift
│   ├── CorrectionEvent.swift
│   ├── QuitProfile.swift
│   └── WishItem.swift
├── Services/
│   ├── Database.swift (shared ModelContainer)
│   ├── PuffStore.swift
│   ├── TaperPlanEngine.swift
│   ├── StatsEngine.swift
│   ├── ForecastEngine.swift
│   ├── NotificationScheduler.swift
│   ├── HealthKitService.swift
│   ├── CloudSyncService.swift (CloudKit mirror + entitlement)
│   └── Keychain.swift
├── AI/
│   ├── OnDeviceCoach.swift (FoundationModels, @Generable CoachAdvice)
│   ├── CoachAdvice.swift
│   ├── DeepSeekClient.swift (BYO: pod vision + weekly report)
│   ├── AIConfiguration.swift (backend selection + degradation)
│   ├── AISettingsViewModel.swift
│   └── CrisisCard.swift (988 / 1-800-QUIT-NOW)
├── Store/
│   ├── PaywallModel.swift (StoreKit2)
│   └── PaywallView.swift
├── Views/
│   ├── Onboarding/ (4-question flow ≤60s)
│   ├── Today/ (ring screen — the only main screen)
│   ├── SOS/ (90s breathing surf + bedtime variant + hand task)
│   ├── Coach/ (iMessage-style AI chat)
│   ├── Recovery/ (timeline)
│   ├── Calendar/ (edit any day)
│   ├── Wishlist/
│   └── Settings/
├── Intents/
│   └── LogPuffIntent.swift (+ SOSStartIntent)
├── Widgets/ (WidgetKit + ControlCenter extension)
├── WatchApp/ (complication + independent logging)
└── LiveActivity/ (ActivityKit: lock screen + Dynamic Island)
```

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Onboarding (≤60s, 4 questions, no account) | Launch → Q1 device type image cards (disposable/pod/refillable, 3s) → Q2 daily puffs slider + presets 50/100/200/300+ (5s) → Q3 price per pod/unit (5s) → Q4 goal: quit today / 6-week taper / observe-only (8s) → plan generated | Device type, baseline puffs/day, cost per unit, puffs per unit, goal | Build `QuitProfile`; compute daily limit, quit date, projected savings | Plan screen: daily cap + quit date + "This plan will save you $X" big-number animation; then main screen + "you never need to open this app" 30s setup guide + Day-1 badge | `QuitProfile` (SwiftData) | Full flow <60s; savings figure uses verifiable formula; no signup |
| 2 | One-tap puff logging (8 external entries) | Tap Watch complication / press Action Button / double-back-tap (Shortcuts) / Control Center toggle / "Hey Siri, log a puff" / Home Screen Widget / Lock Screen Live Activity button / in-app button | Source tag (watch/widget/siri/button/app), event UUID | `LogPuffIntent.perform()`: insert `PuffEvent` idempotently (UUID dedupe), recompute today's net count, compare with `TaperPlanEngine.dailyLimit` | Haptic + count+1; Live Activity number updates in ≤0.5s; if over limit → gentle suggestion (not a warning) to try 90s surf | `PuffEvent` (App Group shared SwiftData) | Log completes ≤0.5s without opening app; rapid double-tap counts once; Watch+phone concurrent logs don't duplicate |
| 3 | Taper plan engine | Onboarding goal=taper → auto plan; Settings → adjust slope 10–20%/week; plan changes never touch history | Baseline, taper %, start date | `dailyLimit(profile:on:)` = baseline × (1−pct)^weekIndex, floor→0; `projectedQuitDate()` | Today's limit ring; "Your last puff: [date]"; tomorrow's target; milestones | Derived from `QuitProfile` | Unit tests: limit curve, quit date, floor-at-0; changing plan never recomputes past money/history |
| 4 | Stats engine (money/nicotine/achievement %) | Automatic; visible on Today screen capsules, Widgets, Live Activity | All PuffEvents + Corrections + profile cost fields | Net puffs today (events minus corrections); money saved = net × (unit price ÷ puffs per unit); nicotine mg estimate; weekly achievement % (days under limit / days elapsed) | "Saved $XXX" capsule; recovery progress D12 capsule; weekly % stays green after slip | Aggregated on-device from SwiftData (T+0 real-time) | Money formula tappable→shows breakdown; numbers traceable to log; slip does NOT reset % or money |
| 5 | SOS breathing surf (L0, offline) | From any entry point / over-limit gentle suggestion → full-screen wave breathing ring: inhale 4s → hold 2s → exhale 6s, ripple animation + hand-squeeze task; after 22:00 auto-switches to sleep-aid variant | Session start | 90s countdown timer, phase animation engine (4-2-6), haptics | Victory page: "Wave #47 crushed!" + cumulative wins + "this saved $0.35" → wish-list progress; or "I still want to vape" button → AI coach (always an exit, never a dead end) | `CravingEvent(outcome: "won"/"slipped"/"ai_helped")` | Works in airplane mode; ring animation 60fps; bedtime variant after 22:00; no shame copy anywhere |
| 6 | AI craving coach L1 (on-device FM) | SOS victory-fail path or Coach tab → chat: FM asks "Where are you? How do you feel?" → one micro-action suggestion (cold water/walk/gum/wait 5 min) | Last-7-day summary (puffs trend, peak hour, top triggers) + mood | `OnDeviceCoach.advise()` with `@Generable CoachAdvice{empathy, microAction, crisisFlag}`; crisis keyword → CrisisCard | Chat bubbles with "🧠 On-device · Private · Works offline" badge; 1 micro-action max per reply | Conversation session-local; `CravingEvent(aiUsed:true)` | Free tier 3x/day, Pro unlimited; zero network traffic; ≤1 action per reply; no dosage advice; crisisFlag → hotlines immediately (cannot be dismissed) |
| 7 | AI deep mode L2 (BYO DeepSeek) | Settings → Advanced → paste DeepSeek API key (Keychain) → features unlock: pod photo nicotine estimate; deep weekly report | API key (Keychain), pod photo JPEG, anonymized weekly aggregates | `DeepSeekClient` direct to api.deepseek.com; vision: estimate mg/ml + confidence; report: trigger attribution + next-week strategy + crisisFlag check | "☁️ Deep Mode" badge; estimate written to profile (editable); weekly report view | Key in Keychain; reports cached locally | Uploads ONLY anonymized aggregates (peak hours, trigger Top3), never raw timestamps or free text; key never leaves Keychain; no key → features hidden, never error buttons |
| 8 | Predictive intervention (L2 forecast) | Automatic once ≥5 days data (honesty gate) | Historical CravingEvent/PuffEvent time distribution | Hour-of-day heatmap → peak craving windows; schedule proactive local notifications BEFORE peak windows | Craving heatmap chart; "peak hours ahead" pre-emptive notification with surf suggestion | Computed stats + precisely registered notifications | Gate: <5 days shows "X more days of data needed"; notifications registered per exact DateComponents; full reschedule after data updates |
| 9 | Slip ≠ Reset handling | After a logged slip (via SOS fail path or manual log) | Slip event + honest backfill prompt for that puff | Reset ONLY consecutive-day streak; weekly %, money total, recovery progress all preserved | Amber "one slip doesn't kill your quit" card + auto-push 60s Recovery Script (audio) + next-morning reminder; NEVER red | `CravingEvent(outcome:"slipped")` + `PuffEvent` backfill | Weekly % stays green/amber (never red); Recovery Script push fires; backfill encouraged; zero shame copy |
| 10 | History editing (any date) | Calendar tab → month view (green=on-target, amber=slip day with % shown) → tap any day → backfill puffs / corrections | Date + count changes | Edits create offset `CorrectionEvent`s targeting original `PuffEvent.uuid` (immutable audit trail) | Updated net stats everywhere | `CorrectionEvent` | Any past date editable; records never lost on plan change; stats recompute net correctly |
| 11 | Lock Screen Live Activity + Dynamic Island | Auto-starts daily after first log or manual start | Live puff count, limit, money saved | ActivityKit update on every event | Lock screen: count + money ticker (real-time rolling like stock); Island: compact count | ActivityKit session | Updates ≤0.5s per log; money number animates; ends at midnight or user stop |
| 12 | Watch app | Watch complication tap → log; Watch SOS button → surf; independent offline logging with sync-back | Source "watch", deviceNonce for offline compensation | Offline queue → reconciliation on reconnect (nonce dedupe) | Complication count; haptic confirmation | Shared SwiftData via App Group | Complication shows today's count; offline logs merge without dupes |
| 13 | Widgets + Control Center | Home Screen widget (count/limit/money); Lock Screen accessory; Control Center toggle → LogPuffIntent | — | Intent invocation | Live counts without app open | — | Widget timeline accurate; Control Center toggle logs without opening app |
| 14 | Recovery timeline | Today screen → Recovery card | Quit date/profile | Public medical milestones: 20min HR↓, 12h CO↓, 2wk circulation↑, 1–9mo lung repair; current node breathing animation | Vertical timeline cards; HealthKit real-data overlay: "your resting HR dropped X bpm" | Milestones derived from quit date; HealthKit read-only | HealthKit overlay only shows real measured values (honesty gate); current node animated |
| 15 | Money wish list | Today screen → Wishlist → add goal (PS5/trip/sneakers) + target amount | Goal name + price | Money saved allocated to goal → progress bar + ETA countdown | Progress bar with countdown | `WishItem` (SwiftData/CloudKit) | Progress = f(verifiable savings); multiple goals supported |
| 16 | Daily summary notification (21:00) | Automatic | Day's events | Aggregate: puffs today, $ saved, distance to target | Local notification "Today: X puffs · saved $Y · Z to go" | Scheduled per-day precise | Fires 21:00 local; content matches log exactly |
| 17 | Daily AI micro-action | Morning local notification (FM-generated previous night or on-demand) | 7-day summary | FM generates ONE 30-second replacement ritual (grip/cold water/breath mint) | Notification + Today screen card | Cached locally | One action only; 30s-completable; respects free-tier AI count |
| 18 | StoreKit2 paywall | Settings/Paywall → Free vs Pro; prices: Pro $4.99/mo, $29.99/yr (7-day trial, default highlighted), Lifetime $59.99 non-consumable | Purchase intent | StoreKit2 Transaction.updates listener; entitlement flag local + CloudKit restore | Paywall: feature list led by app features; Manage Subscription top-of-Settings direct link; legal links | StoreKit2 + local entitlement | Restore works; yearly has trial; lifetime one-time; NO weekly subscription tier |
| 19 | CloudKit sync + Quit Buddy | Sign in iCloud → auto sync; add buddy (free: 1, Pro: 5) share progress | iCloud account, buddy share code | CloudKit mirror of SwiftData + entitlement sync | Cross-device continuity; buddy progress view | CloudKit private DB | Sync restores counts + purchases across devices; buddy sees streak/% (not raw timestamps) |
| 20 | Mood emoji quick log | Today screen → emoji row → tap | Emoji mood | Stored with optional trigger tag | Mood history in calendar/heatmap | Part of CravingEvent/day summary | One tap; feeds trigger analytics |
| 21 | Crisis card (compliance red line) | Auto-triggered by AI crisisFlag; Settings → permanent hotline entry | AI detection | Show 1-800-QUIT-NOW + 988 | Full-screen card, tappable tel: links | Static | Cannot be disabled; appears within 1s of crisisFlag |
| 22 | Settings & compliance | Settings tab | — | — | Disclaimer "self-help tool, not medical advice"; hotline entry; Manage Subscription; BYO key config; data policy explanation; version (read from Bundle, never hardcoded) | — | All links functional; disclaimer unremovable |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Detail | Interaction |
|---|--------|-------------|--------|-------------|
| 1.1 | Onboarding | Plan reveal moment | "This plan will save you $1,247" big-number animation = emotional hit in first minute; contrast with competitors' paywall-first | Auto animation, CTA continue |
| 1.2 | Onboarding | Post-plan setup guide | 30s guide teaching user to place Action Button / Widget / back-tap shortcut ("the app that never asks you to open it") | Paged cards, skippable |
| 2.1 | Logging | Over-limit gentle prompt | "You've reached today's cap — want a free 90-second surf?" — suggestion tone, never warning | Non-blocking card |
| 5.1 | SOS | Hand task | Grip-squeeze counter animation during breathing (oral fixation + hands need help) | Squeeze counter synced to breath phases |
| 5.2 | SOS | Bedtime variant | After 22:00, SOS switches to sleep-aid breathing pacing | Auto by clock |
| 5.3 | SOS | Victory numbering + sound effect | "Wave #47 crushed!" cumulative win count + coin-drop sound; red only here (celebration) | Animation + haptic + audio |
| 6.1 | Coach | Free-tier counter | 3 FM coach sessions/day free; counter visible but never blocks breathing SOS; Pro unlimited | Badge in chat header |
| 7.1 | DeepSeek | Pod estimate editable | AI estimate writes to profile; user can correct manually | Edit sheet after scan |
| 9.1 | Slip | Recovery script | 60s audio + next-morning reminder, auto-pushed after slip | Push + in-app card |
| 10.1 | Calendar | Day detail | Tap day → list events → delete (=CorrectionEvent) or add backfill | Swipe/tap |
| 14.1 | Recovery | Honesty gating | HealthKit correlation ("HR down X bpm") only shows with sufficient real data | Gate message otherwise |
| 18.1 | Paywall | Price transparency | Prices printed in screenshots + paywall ("Price on the box"); no weekly sub | Static card |
| 18.2 | Paywall | One-tap cancel path | Settings top: "Manage subscription" deep link to App Store subscriptions | Link |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|------------|--------|--------|-------------|---------|
| Any log event → all displays | PuffEvent insert | StatsEngine → Today/Widget/Live Activity/Watch | Net count, money | Every insert/correction |
| Over-limit → gentle surf suggestion | StatsEngine | SOS Director | today>limit flag | After each log |
| SOS outcome → craving event + numbering | SOS session | CravingEvent + victory page | won/slipped/ai_helped, $ saved this session | Session end |
| Slip → recovery script | Slip event | NotificationScheduler | slip date | Slip recorded |
| 7-day rolling summary → AI coach context | StatsEngine | OnDeviceCoach / DeepSeek | trend, peak hour, top triggers | Coach session start |
| crisisFlag → crisis card | AI response | CrisisCard | bool | Any AI reply |
| Forecast heatmap → proactive notifications | ForecastEngine | NotificationScheduler | peak windows | ≥5 days data, after each update |
| Purchase → feature unlock | StoreKit2 | Coach limits / DeepSeek mode / forecast / buddies | entitlement | Transaction verified |
| Wishlist ↔ money saved | StatsEngine | WishItem progress | total savings | After each log |
| HealthKit readings → recovery overlay | HealthKitService | Recovery timeline | resting HR delta | Data available + honesty gate |

**VERIFICATION**: 22 primary features + 13 sub-features + 11 dependencies — all features in the Chinese guide (Chapters 1–11) are accounted for. ✅

## ⚠️ Data Flow Diagram (per feature lifecycle — key flows)

```
Feature: One-tap puff logging
User tap (Watch/Widget/Siri/CC/ActionButton/BackTap/LiveActivity/in-app)
  └─ LogPuffIntent.perform() [no app open]
       │ UUID idempotency check → PuffStore.insert(PuffEvent(source))
       │ (App Group shared ModelContainer; ModelActor isolation; Swift 6 concurrency)
       ├─ StatsEngine: netToday = events − corrections; money += unitCost
       ├─ TaperPlanEngine.dailyLimit(profile, today)
       ├─ if netToday > limit → SOSDirector.suggestGentleSurf()
       └─ Update Live Activity + Widget timeline + Watch complication
Persistence: PuffEvent(uuid, timestamp, loggedAt, source, deviceNonce) — insert-only
Display: ring count / Live Activity money ticker / complication

Feature: Slip ≠ Reset
Slip recorded → CravingEvent(outcome:"slipped") + optional PuffEvent backfill
  ├─ StreakEngine: consecutive-day streak = 0 ONLY
  ├─ Weekly % / money / recovery progress: UNCHANGED (net-based computation)
  ├─ NotificationScheduler: push Recovery Script (60s audio) + next-morning reminder
  └─ Calendar day → amber, still shows achievement %
Persistence: CravingEvent + CorrectionEvent(s); no destructive mutation

Feature: AI coach (on-device)
SOS fail / Coach tab → session start
  ├─ Gather last-7-day summary (trend, peak hour, top triggers) — device-local only
  ├─ FoundationModels: respond(..., generating: CoachAdvice.self) — structured JSON only
  ├─ crisisFlag==true → CrisisCard (988 / 1-800-QUIT-NOW) — unskippable
  └─ Render empathy (≤12 words) + ONE micro-action; decrement free count (3/day) unless Pro
Persistence: session-local transcript; CravingEvent(aiUsed:true); never raw text to DB
Zero network traffic for FM path.

Feature: BYO DeepSeek
Settings: key → Keychain("com.zzoutuo.CraveFade.deepseek")
  ├─ Pod photo → base64 → api.deepseek.com (vision message) → {mg_per_ml, confidence, note} → profile (editable)
  └─ Weekly report → ONLY AnonymizedWeekStats uploaded (peak window, trigger Top3) → report view
Persistence: key=Keychain; reports cached locally; no raw timestamps leave device
```

## Implementation Flow

1. W1: SwiftData models (PuffEvent/CravingEvent/CorrectionEvent/QuitProfile/WishItem) + shared App Group container + TaperPlanEngine + StatsEngine + unit tests (limit curve, money, % net math, dedupe).
2. W2: App Intents (LogPuffIntent + SOSStartIntent, openAppWhenRun=false) + WidgetKit widgets + Control Center toggle + Watch app (complication + offline log) + ActivityKit Live Activity/Dynamic Island.
3. W3: SOS breathing engine (4-2-6 ring, ripples, hand task, bedtime variant) + on-device FM coach (structured output + crisis card) + ForecastEngine (honesty gate + precise notifications).
4. W4: StoreKit2 (free/pro monthly $4.99/yearly $29.99 trial/lifetime $59.99) + DeepSeekClient (Keychain, pod vision, weekly report) + CloudKit sync + Quit Buddy.
5. W5: Slip recovery flow + calendar editing (correction events) + recovery timeline + wishlist + daily summary + accessibility pass (Dynamic Type XXXL, VoiceOver, Reduce Motion).
6. W6: Localization (8 languages: en, es, de, fr, ja, ko, pt-BR, zh-Hans), TestFlight, ASO assets.

## UI/UX Design Specifications

- **Color scheme**: Background near-black (#0B0F14); primary gradient cyan→mint (#22D3EE→#6EE7B7); SOS indigo-violet (#6366F1→#8B5CF6); amber #F59E0B for slip days; red #EF4444 reserved EXCLUSIVELY for victory celebration.
- **Typography**: SF Pro rounded; Today ring numerals 68pt+; Dynamic Type up to XXXL without layout break.
- **Layout**: One main screen (Today ring + 2 capsules + setup-guide strip); no infinite scroll; all primary actions bottom half.
- **Animations**: Breathing ring scale/opacity synced to 4-2-6 phases; ripple waves; money ticker roll; Reduce Motion → static phase text + haptics only.
- **Badges**: "🧠 On-device · Private" (FM) vs "☁️ Deep Mode" (DeepSeek) in chat header.

## Code Generation Rules

1. Swift 6 strict concurrency: ModelActor for SwiftData writes; @MainActor for UI.
2. Single shared container: App/Widget/Watch targets use same App Group + ModelContainer; Database.shared singleton.
3. AI output MUST be structured (@Generable / response_format=json_object) — never free text into DB.
4. Notifications registered per exact DateComponents; full reschedule after data updates; never coarse daily-repeat.
5. Lifetime buyout permitted ONLY for zero-marginal-cost features (on-device FM + BYO). Future cloud features = separate tier.
6. No medical claims: no cure/treat/therapy; fixed disclaimer + hotline; crisis words → hotlines.
7. Every displayed number traceable to user log or public medical milestone — zero fake data.
8. Version read dynamically via Bundle.main.infoDictionary — never hardcoded.
9. Apple-native first (SwiftUI, SwiftData, WidgetKit, ActivityKit, FoundationModels, StoreKit2, CloudKit). Reference projects (architecture reading only): brngcn96/Smokeless (SwiftData+Charts), duyhunghd6/brex-breathing-exercise (breathing ring), manojaher/AppleIntelligence (FM sessions), kumarswathi/storekit2-claude-skill (StoreKit2 scaffolding).

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (Default Free AI Backend)
This app uses on-device Foundation Models as the default AI backend. On supported devices (iPhone 15 Pro+, iOS 26+), AI features work immediately after download with zero configuration.

**iOS Version Handling**:
- iOS 26+: Apple Intelligence/FM is default; works out-of-the-box.
- iOS < 26 / unsupported device: app falls back to BYO DeepSeek key mode. UI shows a non-error prompt to configure a key; breathing SOS always works regardless (degradation chain — features never collapse).
- Simulator: FM unavailable → for testing configure BYO key.

### Guideline 2.1(a) — App Completeness
1. Create `app_review_info.md` with demo BYO key instructions for reviewers.
2. NEVER show clickable AI buttons that error when no backend is available — hide with explanatory copy instead.
3. `canGenerate = isPro || hasAPIKey || fmAvailable` — no free-generation counting of the forbidden kind.

### Dead Code Prevention
- ❌ NEVER add: `freeGenerationsUsed`, `maxFreeGenerations`, `canGenerateFree`, `incrementGenerationCount()` (as AI-paywall gating; the documented free-tier 3/day FM quota is a product feature implemented via its own counter, NOT a paywall gate on core functionality).

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information
Paywall MUST contain: functional Privacy Policy link, functional Terms of Use (EULA) link, subscription title/length/price, auto-renewal disclosure text.

### Pricing Table (final — copy verbatim)
| Tier | Price | Content |
|------|-------|---------|
| Free (forever) | $0 | Unlimited logging (all 8 entries), taper plan, unlimited 90s SOS, money calc, basic recovery timeline, Widget+Watch, AI coach 3x/day (on-device), full history editing, iCloud sync, 1 Quit Buddy |
| Pro Monthly | $4.99/mo | Unlimited AI coach + BYO DeepSeek deep mode + craving forecast + proactive push + full history heatmap + custom slope + bedtime mode + 5 Quit Buddies + all future features |
| Pro Yearly (primary) | $29.99/yr (7-day free trial) | Same as monthly ≈ $2.5/mo — default highlighted |
| Pro Lifetime | $59.99 one-time | Same, forever (compliant: zero marginal cost) |
| BYO DeepSeek | $0 (own key) | User pays DeepSeek directly; developer zero-touch |

Rules: NO weekly subscription tier (deliberate anti-pattern avoidance); "Manage subscription" direct link at top of Settings; price transparency in screenshots.

## Build & Deployment Checklist

1. Configure targets: App / Widgets (+Control Center) / Watch App / (Live Activity inside App+Widget extension).
2. Capabilities: App Groups (`group.com.zzoutuo.CraveFade.shared`), iCloud (CloudKit), HealthKit (read), Push Notifications (local+remote for Live Activity updates), App Intents, Siri.
3. Signing: automatic; Bundle ID `com.zzoutuo.CraveFade`.
4. Icons: 1024 App Icon set (Agnes-generated), Watch icons, alternate SOS icon if any.
5. App Store metadata: Name "CraveFade: Quit Vaping"; Subtitle "Craving SOS & Puff Tracker"; keywords `quit vaping,stop smoking,nicotine,puff counter,craving,cigarette,zyn,tobacco,smoke free,taper`; age 17+ (tobacco references); privacy label **Data Not Collected**.
6. Screenshots order: ① SOS surf screen ② money big-number ③ 8-entry logging diagram ④ recovery timeline ⑤ AI coach with On-device badge ⑥ price transparency card.
7. Review notes: self-help tool disclaimer, crisis hotline built-in, BYO key demo in app_review_info.md.
