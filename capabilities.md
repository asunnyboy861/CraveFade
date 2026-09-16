# Capabilities Configuration — CraveFade

## Analysis
Based on operation guide analysis (keywords found: iCloud/CloudKit 同步, HealthKit 静息心率, Watch 表盘, Widget/控制中心, Live Activity/灵动岛, 通知, Siri/App Intents, 订阅 IAP, 相机拍照识别烟弹):

- App Groups — required for shared SwiftData container across App/Widget/Watch
- iCloud (CloudKit) — free sync mirror + entitlement restore + Quit Buddy
- HealthKit — read-only resting HR / sleep correlation
- Push Notifications — local precise scheduling + Live Activity updates
- App Intents / Siri — one-tap logging from Siri/Shortcuts/Action Button/Back Tap
- In-App Purchase — StoreKit2 subscription group + lifetime buyout
- Camera/Photo Library — pod photo nicotine estimation (BYO DeepSeek)
- Watch App — complication + independent logging
- Background Modes — not required beyond system-provided (Live Activity push uses push capability)

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| App Groups (`group.com.zzoutuo.CraveFade.shared`) | ✅ Configured | Entitlements file + project settings |
| HealthKit | ✅ Configured | Entitlements file |
| Push Notifications (aps-environment) | ✅ Configured | Entitlements file |
| Siri / App Intents | ✅ Configured | Entitlements file |
| iCloud (CloudKit entitlement) | ✅ Configured | Entitlements file |
| Camera usage | ✅ Configured | NSCameraUsageDescription added by code-gen phase (GENERATE_INFOPLIST_FILE=YES) |
| Bundle ID | ✅ Fixed to `com.zzoutuo.CraveFade` | project.pbxproj |
| Entitlements wiring | ✅ `CODE_SIGN_ENTITLEMENTS = CraveFade/CraveFade.entitlements` | project.pbxproj |
| Development Team | ✅ JP4TN5PTS3 (already set by user) | project.pbxproj |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| CloudKit container registration | ⏳ Pending (Apple Developer portal only) | developer.apple.com → Certificates, IDs & Profiles → Identifiers → enable iCloud on `com.zzoutuo.CraveFade` → create container `iCloud.com.zzoutuo.CraveFade`. App works fully on local storage until then (graceful degradation). |
| IAP products in App Store Connect | ⏳ Pending (requires paid program UI) | Create `pro.monthly` $4.99, `pro.yearly` $29.99 (7-day trial), `pro.lifetime` $59.99 after app record exists. |

## No Configuration Needed
- Location Services — not used
- Family Sharing — not used
- Sign in with Apple — not used (iCloud account only)

## Verification
- Build succeeded after configuration: see PHASE 6 build report
- All entitlements correct: ✅ (file created and wired into both Debug/Release of app target)
