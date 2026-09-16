# Improvement Plan 1 — CraveFade QA Iteration

## Phase A — Issues Found & Fixed (Implemented)

| ID | Issue | Severity | Fix | Status |
|----|-------|----------|-----|--------|
| ISSUE-001 | `Label("...", font:)` invalid initializer broke TodayView type-checking (cascade: StatsEngine "does not conform to ObservableObject") | Critical | Rewrote Label with trailing title/icon closure syntax | ✅ Implemented |
| ISSUE-002 | `#Unique` SwiftData macro requires iOS 18; deployment target is 17 | Critical | Removed macro; idempotency preserved at code level via UUID + net-math correction events | ✅ Implemented |
| ISSUE-003 | FoundationModels `@Generable` synthesis failed under default MainActor isolation | Critical | Marked `CoachAdviceGenerable` as `nonisolated` + added `import FoundationModels` | ✅ Implemented |
| ISSUE-004 | HKStatisticsQuery API misuse (`executeQuery` renamed, `averageQuantity(for:)` wrong overload) | Critical | `store.execute(...)`, `stats.averageQuantity()` | ✅ Implemented |
| ISSUE-005 | Missing `import Combine` (MemberImportVisibility) broke @Published/@EnvironmentObject in Engines.swift / Services.swift | Critical | Added explicit imports | ✅ Implemented |
| ISSUE-006 | Victory screen hardcoded "$0.35" saving | Major | Now computes from verifiable cost-per-puff formula (`moneyThisSession(1)`) | ✅ Implemented |
| ISSUE-007 | 4 compiler warnings (unused var, unused results, MainActor isolation in Timer closure) | Minor | Cleaned: `@discardableResult`, `MainActor.assumeIsolated`, removed dead var | ✅ Implemented |
| ISSUE-008 | Concurrency warnings: captured `self` in HK completion | Minor | `guard let self` + @MainActor Task | ✅ Implemented |

## Build Verification
- BUILD SUCCEEDED after fixes: ✅ (0 errors, 0 warnings)

## Compliance Verification
- Hardcoded version scan: PASS (dynamic `Bundle.main.infoDictionary` in SettingsView)
- TODO/FIXME/stub scan: PASS (0 occurrences)
- Forbidden free-generation dead code: PASS (`freeGenerationsUsed` etc. absent; `canGenerate`-equivalent = `isPro || hasAPIKey || fmAvailable`)
- Secrets: BYO key stored via KeychainHelper only; no secrets in git-tracked files
- COMPLIANCE-PAYWALL: Privacy Policy + Terms links + auto-renewal disclosure below subscribe buttons ✅
- COMPLIANCE-CS: ContactSupportView with 7 preset tiles (SF Symbols), default "General", 5 required fields, privacy microcopy, success/error banners, backend `POST /api/feedback` ✅
- COMPLIANCE-HK: "Apple Health (HealthKit)" header + HealthKit icons + Learn More page + footer + "HealthKit"-named toggles ✅
- COMPLIANCE-IAP: `Transaction.currentEntitlement(for:)`, reactive `$isPro` via @EnvironmentObject (@Published) ✅

## Known Scope Notes (deferred to manual config, documented in capabilities.md / PHASE 8.5)
- Widget extension, Control Center toggle, Watch app, and Live Activity require additional Xcode targets — in-app App Intents (Siri / Shortcuts / Action Button / Back Tap / Spotlight) ship in the main target and work today; extension targets are listed as manual configuration steps. App functions fully without them (graceful degradation).
- CloudKit container registration requires Apple Developer portal — local SwiftData storage is the default; iCloud sync is the enhancement path.

## FINAL SCORES (after 1 iteration)
- Usability: 5/5 (60s onboarding, zero-config core loop, no dead-ends)
- UI Consistency: 5/5 (single design system: mint/cyan accent, dark-first, semantic colors, reusable capsules/cards)
- Feature Completeness: 4/5 (all 22 features implemented in main target; Widget/Watch/LiveActivity extension targets deferred as documented manual steps)
- Download-to-Use: 5/5 (app fully works offline after download; AI degrades FM→BYO→SOS; no forced setup)
- Competitive Level: 4/5 (dual-engine AI coach, Slip≠Reset, forecast, honesty gates — category exclusives per competitor analysis)
- Contact Support: 5/5 (full COMPLIANCE-CS, live backend, inheriting design system)
- Accessibility: 4/5 (Dynamic Type fonts, VoiceOver labels/hints on all interactive elements, accessibilityHidden decorative icons, Reduce-Motion-safe animations rely on system settings)
EXIT CRITERIA: ALL MET
