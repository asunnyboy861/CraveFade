import Foundation
import StoreKit
import Combine
import SwiftData

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isPro: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?

    static let monthlyID = "com.zzoutuo.CraveFade.pro.monthly"
    static let yearlyID = "com.zzoutuo.CraveFade.pro.yearly"
    static let lifetimeID = "com.zzoutuo.CraveFade.pro.lifetime"

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts(); await checkPurchased() }
    }

    deinit { transactionListener?.cancel() }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [Self.monthlyID, Self.yearlyID, Self.lifetimeID])
            loadError = nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await checkPurchased()
                    return true
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPurchased()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func checkPurchased() async {
        var pro = false
        for id in [Self.monthlyID, Self.yearlyID, Self.lifetimeID] {
            if let result = await Transaction.currentEntitlement(for: id),
               case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                pro = true
                break
            }
        }
        isPro = pro
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.checkPurchased()
                    }
                }
            }
        }
    }

    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var lifetimeProduct: Product? { products.first { $0.id == Self.lifetimeID } }
}

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var profile: QuitProfile?
    @Published var showSOS = false
    @Published var showPaywall = false
    @Published var onboardingComplete = false
    @Published var coachSessionsToday = 0

    let container: ModelContainer
    let stats = StatsEngine()
    let purchaseManager = PurchaseManager.shared

    private init() {
        container = Database.makeContainer()
        let context = ModelContext(container)
        profile = Database.loadProfile(context: context)
        onboardingComplete = profile?.onboardingDone ?? false
        stats.configure(container: container, profile: profile)
        loadCoachQuota()
    }

    func saveProfile() {
        guard let profile else { return }
        let context = ModelContext(container)
        context.insert(profile)
        try? context.save()
        onboardingComplete = profile.onboardingDone
        stats.configure(container: container, profile: profile)
        rescheduleForecast()
    }

    @discardableResult
    func logPuff(source: LogSource, at date: Date = .now) -> (net: Int, limit: Int) {
        guard let profile else { return (0, 0) }
        let context = ModelContext(container)
        context.insert(PuffEvent(timestamp: date, source: source))
        try? context.save()
        stats.refresh()
        let limit = TaperPlanEngine.dailyLimit(profile: profile, on: date)
        if stats.netPuffsToday > limit {
            NotificationScheduler.shared.scheduleDailySummary(
                hour: 21, puffs: stats.netPuffsToday,
                money: stats.moneySavedText,
                toGo: max(0, limit - stats.netPuffsToday)
            )
        }
        return (stats.netPuffsToday, limit)
    }

    func recordCraving(outcome: OutcomeKind, trigger: String? = nil, aiUsed: Bool = false) {
        let context = ModelContext(container)
        context.insert(CravingEvent(outcome: outcome.rawValue, triggerTag: trigger, aiUsed: aiUsed))
        try? context.save()
        stats.refresh()
        if outcome == .slipped {
            NotificationScheduler.shared.scheduleRecoveryScript(after: .now)
        }
    }

    func correctPuff(_ event: PuffEvent) {
        let context = ModelContext(container)
        context.insert(CorrectionEvent(targetUUID: event.uuid))
        try? context.save()
        stats.refresh()
    }

    func events(on day: Date) -> [PuffEvent] {
        let context = ModelContext(container)
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let all = (try? context.fetch(FetchDescriptor<PuffEvent>())) ?? []
        return all.filter { $0.timestamp >= start && $0.timestamp < end }.sorted { $0.timestamp > $1.timestamp }
    }

    func allPuffs() -> [PuffEvent] {
        let context = ModelContext(container)
        return ((try? context.fetch(FetchDescriptor<PuffEvent>())) ?? []).sorted { $0.timestamp > $1.timestamp }
    }

    func allCravings() -> [CravingEvent] {
        let context = ModelContext(container)
        return ((try? context.fetch(FetchDescriptor<CravingEvent>())) ?? []).sorted { $0.startedAt > $1.startedAt }
    }

    func netPuffs(on day: Date) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let puffs = allPuffs().filter { $0.timestamp >= start && $0.timestamp < end }
        let corrected = Set(allCorrections().map(\.targetUUID))
        return puffs.filter { !corrected.contains($0.uuid) }.count
    }

    func allCorrections() -> [CorrectionEvent] {
        let context = ModelContext(container)
        return (try? context.fetch(FetchDescriptor<CorrectionEvent>())) ?? []
    }

    func weekSummary() -> WeekSummary {
        var summary = WeekSummary()
        let puffs = allPuffs()
        if let oldest = puffs.map(\.timestamp).min() {
            let days = max(1, Calendar.current.dateComponents([.day], from: oldest, to: .now).day ?? 1)
            let recent = netPuffs(on: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now)
            let earlier = netPuffs(on: Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now)
            summary.puffsTrend = recent < earlier ? "declining" : (recent > earlier ? "rising" : "stable")
            summary.peakHour = ForecastEngine.peakWindows(from: ForecastEngine.hourlyHeatmap(puffs: puffs, cravings: allCravings()), minimumDataDays: 1, oldestEvent: oldest).first ?? -1
            _ = days
        }
        summary.topTriggers = Array(Dictionary(grouping: allCravings().compactMap(\.triggerTag), by: { $0 })
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
            .prefix(3).map(\.0))
        return summary
    }

    func rescheduleForecast() {
        guard let profile, profile.onboardingDone else { return }
        let puffs = allPuffs()
        guard let oldest = puffs.map(\.timestamp).min() else { return }
        let peaks = ForecastEngine.peakWindows(
            from: ForecastEngine.hourlyHeatmap(puffs: puffs, cravings: allCravings()),
            minimumDataDays: 5,
            oldestEvent: oldest
        )
        stats.peakHours = peaks
        NotificationScheduler.shared.rescheduleProactiveNotifications(peakHours: peaks)
    }

    private func loadCoachQuota() {
        let key = "coachQuota.\(Self.quotaDayKey())"
        coachSessionsToday = UserDefaults.standard.integer(forKey: key)
    }

    func canUseCoach() -> Bool {
        purchaseManager.isPro || AIConfiguration.hasAPIKey || coachSessionsToday < 3
    }

    func consumeCoachSession() {
        guard !purchaseManager.isPro, !AIConfiguration.hasAPIKey else { return }
        let key = "coachQuota.\(Self.quotaDayKey())"
        let stored = UserDefaults.standard.integer(forKey: key)
        if stored != coachSessionsToday {
            coachSessionsToday = stored
        }
        coachSessionsToday += 1
        UserDefaults.standard.set(coachSessionsToday, forKey: key)
    }

    private static func quotaDayKey() -> String {
        Calendar.current.dateComponents([.year, .month, .day], from: .now).description
    }
}
