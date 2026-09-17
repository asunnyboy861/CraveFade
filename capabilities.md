# CraveFade — 配置文档

生成时间：2026-09-16

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强功能**。不配置这些项，App 仍可正常使用所有核心功能（记录、减量计划、90秒呼吸冲浪、端侧AI教练3次/天、省钱计算、历史编辑、恢复时间线、预测推送、IAP购买流程）。配置后获得更好体验。

### 🟡 Capabilities 增强配置

#### 1. iCloud CloudKit 容器 — 跨设备同步

**增强功能**：数据跨 iPhone/iPad 同步（当前代码为本地优先，`cloudKitDatabase: .none`）
**不配置的影响**：数据仅存本机，App 完全正常，换机需重新开始
**当前状态**：App 使用本地 SwiftData 存储，无需配置即可正常使用

**已自动配置部分**：
- ✅ App Groups `group.com.zzoutuo.CraveFade.shared` 已配置
- ⚠️ iCloud entitlements **已从项目中移除**（2026-09-17）：未注册的 CloudKit 容器声明会阻断分发签名（IDEDistribution error 0），代码本就使用本地存储。启用同步前请先完成下方第 1-4 步注册容器，再在 Xcode → Signing & Capabilities 重新添加 iCloud 能力。

**如需启用同步，请手动配置**：
1. 打开 [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers**
2. 找到 `com.zzoutuo.CraveFade`（没有则新建 App ID）→ 勾选 **iCloud**（勾选 **CloudKit**）与 **Push Notifications**
3. 进入 **CloudKit Container** 页面 → 点 **"+"** 创建容器，名称填 `iCloud.com.zzoutuo.CraveFade`
4. 将容器与 App ID 关联
5. 代码切换：`Services.swift` 的 `Database.makeContainer()` 中把 `cloudKitDatabase: .none` 改为 `.private("iCloud.com.zzoutuo.CraveFade")`（同时模型属性已全部带默认值，满足 CloudKit 要求）
6. ⚠️ 重新 Build 验证

#### 2. Widget / Watch / Live Activity 扩展 Target（可选开发）

**增强功能**：桌面 Widget、控制中心按钮、Watch 表盘记录、锁屏 Live Activity 实时省钱滚动（指南"8入口"完整形态）
**不配置的影响**：App Intents 已在主 App 内实现 Siri（"Hey Siri, log a puff"）/ 快捷指令 / Action Button / 背敲 4 个免开 App 入口，核心体验已可用
**当前状态**：未创建扩展 target

**如需启用**：在 Xcode 中 File → New → Target 依次添加 **Widget Extension**（勾选 Include Configuration App Intent）与 **Watch App for Existing iOS App**，复用 `LogPuffIntent`/`SOSStartIntent` 与共享的 App Group 容器即可。

---

### 🔵 IAP StoreKit 配置（订阅上线必需）

**影响功能**：不在 App Store Connect 创建产品，付费墙将显示"Unable to load purchase options"，用户无法完成购买（免费功能不受影响）

**已自动配置部分**：
- ✅ `PurchaseManager.swift`（StoreKit 2，`Transaction.currentEntitlement(for:)`，3 个产品 ID 与 price.md 一致）
- ✅ Paywall 含隐私政策/Terms 链接 + 自动续订披露；Settings 顶部"Manage subscription"直通入口

**配置步骤**：
1. App Store Connect → 你的 App → **Features** → **In-App Purchases**（订阅需先创建订阅组 `CraveFade Pro`）
2. 按下表创建产品：

| 产品 | Reference Name | Product ID | 价格 |
|------|---------------|-----------|------|
| 月付 | CraveFade Pro Monthly | `com.zzoutuo.CraveFade.pro.monthly` | $4.99/月 |
| 年付 | CraveFade Pro Annual | `com.zzoutuo.CraveFade.pro.yearly` | $29.99/年（7天免费试用） |
| 终身 | CraveFade Pro Lifetime | `com.zzoutuo.CraveFade.pro.lifetime` | $59.99 一次性（Non-Consumable） |

3. Display Name / Description 从 `price.md` 复制（已验证字符限制 ≤35/≤55）
4. 年付产品在订阅属性中配置 **7-day Free Trial**  introductory offer
5. ⚠️ 年付与月付必须放在**同一订阅组**；终身买断类型选 **Non-Consumable**
6. 本地测试：Xcode → File → New → File → **StoreKit Configuration File**，添加同名产品后 Edit Scheme → Run → Options 勾选该配置文件即可沙盒测试
7. 在 App 内 Settings → **Restore Purchases** 验证恢复流程

---

### 🟢 App Store Connect 审核信息配置（提交前）

**影响功能**：不配置可能导致 Guideline 2.1(a)（App 完整性）拒绝

**配置步骤**：
1. App Store Connect → 你的 App → **App Review Information**
2. **Notes** 字段：粘贴 `app_review_info.md` 内容（含 AI/HealthKit/危机热线合规声明 + 模拟器测试提示）
3. **Privacy Policy URL**：`https://asunnyboy861.github.io/CraveFade/privacy.html`
4. Terms of Use (EULA)：`https://asunnyboy861.github.io/CraveFade/terms.html`（或使用标准 Apple EULA 并在描述中附链接）
5. Support URL：`https://asunnyboy861.github.io/CraveFade/support.html`
6. 隐私标签选择 **Data Not Collected**
7. 年龄分级 17+（烟草内容）

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| App Groups | `group.com.zzoutuo.CraveFade.shared`，主 App 共享容器（SwiftData App Group URL + 降级回退） | ✅ 已配置 |
| HealthKit | 只读静息心率，entitlement + UI 合规标识（图标/Learn More/footer） | ✅ 已配置 |
| Push Notifications | aps-environment 已声明，本地精确通知已实现 | ✅ 已配置 |
| Siri / App Intents | LogPuffIntent + SOSStartIntent + AppShortcuts（Siri/快捷指令/ActionButton/背敲） | ✅ 已配置 |
| Camera/Photo Library | PhotosPicker 烟弹扫描 | ✅ 已配置 |
| In-App Purchase | StoreKit 2 代码 + 合规付费墙 | ✅ 已配置（产品创建见上方手动项） |
| Bundle ID 修正 | `com.zzoutuo.CraveFade` | ✅ 已完成 |
| App 图标 | Agnes 生成 1024px 无 alpha，universal/dark/tinted | ✅ 已完成 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers，`POST https://feedback-board.iocompile67692.workers.dev/api/feedback` | ✅ 已部署对接 |
| 出站网络 | 后端为 HTTPS，默认放行，无 ATS 障碍 | ✅ 可用 |
| AI 端点 | 用户 BYO Key 直连 api.deepseek.com，Key 存 Keychain，开发者服务器零经手 | ✅ 已实现 |
| 危机热线 | 988 / 1-800-QUIT-NOW 内置不可关闭 | ✅ 已实现 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 数据基座 | SwiftData 事件不可变体系（PuffEvent/CravingEvent/CorrectionEvent）+ UUID 幂等 | ✅ 已完成 |
| TaperPlanEngine / StatsEngine / ForecastEngine | 减量曲线/省钱/达成率/诚实门槛预测，单元测试 9/9 通过 | ✅ 已完成 |
| SOS 呼吸引擎 | 90秒 4-2-6 圆环 + 睡前变体 + 手部任务 + 胜利编号 | ✅ 已完成 |
| AI 双引擎 | 端侧 FM（iOS 26 门控，免费3次/天）→ BYO DeepSeek → 纯呼吸 SOS 降级链 | ✅ 已完成 |
| ContactSupportView | 7 主题磁贴 + 5 必填字段 + 成功/失败反馈 | ✅ 已完成 |
| QA 迭代 | improvement_plan_1.md：8 issues 全修复，构建 0 错误 0 警告 | ✅ 已完成 |

### 💡 使用提示（非开发者配置，App 内操作即可）

**AI 功能**：iPhone 15 Pro+ / iOS 26+ 设备开箱即用（Apple Intelligence 端侧推理，免费无网络）。其他设备可在 **Settings → AI Configuration** 粘贴自己的 DeepSeek API Key 解锁 Deep Mode（周报 + 烟弹扫描 + 无限教练）。这是用户操作，非开发者配置。

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/CraveFade（main） | ✅ 已推送 |
| GitHub Pages | /docs 部署，Landing/Support/Privacy/Terms 四页 | ✅ 已启用 |
| Landing Page | App Store ID 为占位符（上架后替换即可变为真实下载按钮） | ✅ 已部署 |
| App Store 元数据 | keytext.md 全部验证通过（保密文件，不入库） | ✅ 已生成 |
| 定价配置 | price.md（订阅组 + 终身买断合规论证） | ✅ 已生成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据，"Auto-Configured"/"Manual"内容已重组到上方 Section 一、二。

### Analysis

关键词检测命中：iCloud/CloudKit 同步、HealthKit 静息心率、Watch 表盘、Widget/控制中心、Live Activity/灵动岛、通知、Siri/App Intents、订阅 IAP、相机拍照识别烟弹。

### No Configuration Needed

- Location Services — 未使用
- Family Sharing — 未使用
- Sign in with Apple — 未使用（仅 iCloud 账户）

### Verification

- PHASE 2 构建：✅ BUILD SUCCEEDED
- PHASE 6 iPhone 16 (iOS 26.4) 构建+运行：✅（修复 SwiftData CloudKit 默认集成崩溃：全部模型属性补默认值 + 显式 `cloudKitDatabase: .none`）
- PHASE 6 iPad Pro 13-inch (M5) 构建+运行：✅
- 单元测试：9/9 通过
