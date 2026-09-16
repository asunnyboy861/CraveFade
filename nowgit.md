# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | CraveFade |
| **Git URL** | git@github.com:asunnyboy861/CraveFade.git |
| **Repo URL** | https://github.com/asunnyboy861/CraveFade |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/CraveFade/ | ✅ Active |
| Support | https://asunnyboy861.github.io/CraveFade/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/CraveFade/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/CraveFade/terms.html | ✅ Active |

## Repository Structure

```
CraveFade/
├── CraveFade/                     # Xcode project root
│   ├── CraveFade.xcodeproj/
│   └── CraveFade/                 # Swift source files
│       ├── CraveFadeApp.swift     # App entry + RootView + MainTabView
│       ├── Models.swift           # SwiftData: PuffEvent / CravingEvent / CorrectionEvent / QuitProfile / WishItem
│       ├── Engines.swift          # TaperPlanEngine / StatsEngine / ForecastEngine
│       ├── Services.swift         # Database (App Group) / KeychainHelper / NotificationScheduler / HealthKitService
│       ├── AI.swift               # AIConfiguration / DeepSeekService (BYO) / OnDeviceCoach (FM) / CoachEngine / CrisisCard
│       ├── AppState.swift         # PurchaseManager (StoreKit2) + AppState hub
│       ├── Intents.swift          # LogPuffIntent / SOSStartIntent / AppShortcuts
│       ├── OnboardingView.swift   # 4-question onboarding ≤60s + savings reveal
│       ├── TodayView.swift        # Ring screen + capsules + entry guide
│       ├── SOSView.swift          # 90s breathing surf + bedtime variant + hand task + victory
│       ├── CoachView.swift        # AI coach chat + quota + crisis card
│       ├── CalendarView.swift     # Month history + backfill/correction
│       ├── RecoveryView.swift     # Recovery timeline + wishlist + HealthKit section + HealthKitInfoView
│       ├── SettingsView.swift     # Pro / AI config / pod scan / HealthKit / support / legal / version
│       ├── PaywallView.swift      # $4.99mo / $29.99yr trial / $59.99 lifetime + legal links
│       └── ContactSupportView.swift # Feedback form → Cloudflare Workers backend
├── docs/                          # Policy pages (added in PHASE 7)
├── us.md / price.md / capabilities.md / icon.md / improvement_plan_1.md / app_review_info.md
├── nowgit.md
└── (excluded by .gitignore: .env, keytext*.md, COMPETITOR_REPORT.md, TR-*.MD Chinese guide)
```

## Quality Gates Passed Before Push
- Secret leak scan: PASS (hard gate)
- No tracked secrets: PASS
- iPhone 16 (iOS 26.4) build + run: PASS
- iPad Pro 13-inch (M5) build + run: PASS
- Unit tests: 9/9 PASS
