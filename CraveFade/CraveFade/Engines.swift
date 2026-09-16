import Foundation
import SwiftData
import Combine

enum TaperPlanEngine {
    static func dailyLimit(profile: QuitProfile, on day: Date, calendar: Calendar = .current) -> Int {
        switch profile.goal {
        case .quitNow: return 0
        case .observe: return .max
        case .taper:
            let start = calendar.startOfDay(for: profile.startDate)
            let target = calendar.startOfDay(for: day)
            guard target >= start else { return profile.baselinePuffs }
            let weekIndex = Double(calendar.dateComponents([.weekOfYear], from: start, to: target).weekOfYear ?? 0)
            let floorValue = max(0, Double(profile.baselinePuffs) * pow(1.0 - profile.taperPercent, weekIndex))
            return floorValue < 1 ? 0 : Int(floorValue.rounded(.up))
        }
    }

    static func projectedQuitDate(profile: QuitProfile) -> Date? {
        guard profile.goal == .taper else { return nil }
        var day = profile.startDate
        for _ in 0..<260 {
            if dailyLimit(profile: profile, on: day) <= 0 { return day }
            guard let next = Calendar.current.date(byAdding: .day, value: 7, to: day) else { return nil }
            day = next
        }
        return nil
    }
}

@MainActor
final class StatsEngine: ObservableObject {
    @Published var netPuffsToday: Int = 0
    @Published var moneySavedTotal: Double = 0
    @Published var weeklyAchievement: Double = 1.0
    @Published var winsCount: Int = 0
    @Published var currentStreak: Int = 0
    @Published var recoveryDays: Int = 0
    @Published var todayLimit: Int = 0
    @Published var peakHours: [Int] = []

    private var container: ModelContainer?
    private var profile: QuitProfile?

    func configure(container: ModelContainer, profile: QuitProfile?) {
        self.container = container
        self.profile = profile
        refresh()
    }

    func refresh() {
        guard let container, let profile else { return }
        let context = ModelContext(container)
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: .now)
        let allPuffs = (try? context.fetch(FetchDescriptor<PuffEvent>())) ?? []
        let corrections = (try? context.fetch(FetchDescriptor<CorrectionEvent>())) ?? []
        let correctionTargets = Set(corrections.map(\.targetUUID))
        let netAll = allPuffs.filter { !correctionTargets.contains($0.uuid) }
        netPuffsToday = netAll.filter { $0.timestamp >= dayStart }.count
        moneySavedTotal = Double(netAll.count) * profile.costPerPuff
        todayLimit = TaperPlanEngine.dailyLimit(profile: profile, on: .now)
        recoveryDays = max(0, cal.dateComponents([.day], from: cal.startOfDay(for: profile.startDate), to: dayStart).day ?? 0)

        var underDays = 0, totalDays = 0
        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: dayStart) else { continue }
            guard day >= cal.startOfDay(for: profile.startDate) else { continue }
            let dayEnd = cal.date(byAdding: .day, value: 1, to: day) ?? day
            let count = netAll.filter { $0.timestamp >= day && $0.timestamp < dayEnd }.count
            let limit = TaperPlanEngine.dailyLimit(profile: profile, on: day)
            if limit != .max {
                totalDays += 1
                if count <= limit { underDays += 1 }
            }
        }
        weeklyAchievement = totalDays == 0 ? 1.0 : Double(underDays) / Double(totalDays)

        let cravings = (try? context.fetch(FetchDescriptor<CravingEvent>())) ?? []
        winsCount = cravings.filter { $0.outcomeKind == .won }.count

        var streak = 0
        for offset in 0..<365 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: dayStart) else { break }
            let dayEnd = cal.date(byAdding: .day, value: 1, to: day) ?? day
            let slipped = cravings.contains { $0.outcomeKind == .slipped && $0.startedAt >= day && $0.startedAt < dayEnd }
            if slipped { break }
            streak += 1
        }
        currentStreak = streak

        var hourCounts = [Int: Int]()
        for puff in netAll {
            let hour = cal.component(.hour, from: puff.timestamp)
            hourCounts[hour, default: 0] += 1
        }
        peakHours = hourCounts.filter { $0.value >= 2 }.map(\.key).sorted()
    }

    func moneyThisSession(_ puffs: Int) -> Double {
        Double(puffs) * (profile?.costPerPuff ?? 0)
    }

    var moneySavedText: String {
        String(format: "$%.2f", moneySavedTotal)
    }
}

struct HourHeatmap {
    let hour: Int
    let count: Int
}

enum ForecastEngine {
    static func hourlyHeatmap(puffs: [PuffEvent], cravings: [CravingEvent]) -> [HourHeatmap] {
        let cal = Calendar.current
        var counts = [Int: Int]()
        for puff in puffs {
            let hour = cal.component(.hour, from: puff.timestamp)
            counts[hour, default: 0] += 1
        }
        for craving in cravings {
            let hour = cal.component(.hour, from: craving.startedAt)
            counts[hour, default: 0] += 1
        }
        return (0..<24).map { HourHeatmap(hour: $0, count: counts[$0] ?? 0) }
    }

    static func peakWindows(from heatmap: [HourHeatmap], minimumDataDays: Int = 5, oldestEvent: Date?) -> [Int] {
        guard let oldest = oldestEvent else { return [] }
        let days = max(0, Calendar.current.dateComponents([.day], from: oldest, to: .now).day ?? 0)
        guard days >= minimumDataDays else { return [] }
        let sorted = heatmap.sorted { $0.count > $1.count }
        guard let top = sorted.first, top.count >= 3 else { return [] }
        return sorted.filter { $0.count >= max(2, Int(Double(top.count) * 0.6)) }.map(\.hour)
    }
}
