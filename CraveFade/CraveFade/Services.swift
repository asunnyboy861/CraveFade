import Foundation
import SwiftData
import UserNotifications
import HealthKit
import Combine

enum KeychainHelper {
    static func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func saveString(_ value: String, service: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        save(data, service: service, account: account)
    }

    static func readString(service: String, account: String) -> String? {
        guard let data = read(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

enum Database {
    static let appGroupID = "group.com.zzoutuo.CraveFade.shared"

    static func makeContainer() -> ModelContainer {
        let schema = Schema([PuffEvent.self, CravingEvent.self, CorrectionEvent.self, QuitProfile.self, WishItem.self])
        let config: ModelConfiguration
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            config = ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("CraveFade.sqlite"), cloudKitDatabase: .none)
        } else {
            config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        }
        return (try? ModelContainer(for: schema, configurations: [config]))
            ?? (try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)]))
    }

    static func loadProfile(context: ModelContext) -> QuitProfile? {
        var descriptor = FetchDescriptor<QuitProfile>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first { return existing }
        let profile = QuitProfile()
        context.insert(profile)
        try? context.save()
        return profile
    }
}

@MainActor
final class NotificationScheduler: ObservableObject {
    static let shared = NotificationScheduler()

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleDailySummary(hour: Int = 21, puffs: Int, money: String, toGo: Int) {
        let center = UNUserNotificationCenter.current()
        let ids = ["daily-summary"]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard toGo >= 0 else { return }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = 0
        guard let fireDate = Calendar.current.date(from: components), fireDate > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = "Today's summary"
        content.body = "Today: \(puffs) puffs · saved \(money) · \(toGo) to go"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: "daily-summary", content: content, trigger: trigger))
    }

    func scheduleRecoveryScript(after slipDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["recovery-script"])
        let content = UNMutableNotificationContent()
        content.title = "One slip doesn't kill your quit"
        content.body = "Your weekly win rate is still intact. Take 60 seconds for the comeback script."
        content.sound = .default
        if let fireDate = Calendar.current.date(byAdding: .hour, value: 1, to: slipDate), fireDate > .now {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireDate.timeIntervalSinceNow, repeats: false)
            center.add(UNNotificationRequest(identifier: "recovery-script", content: content, trigger: trigger))
        }
        var morning = Calendar.current.date(byAdding: .day, value: 1, to: slipDate) ?? .now
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: morning)
        comps.hour = 8
        comps.minute = 30
        if let fireDate = Calendar.current.date(from: comps), fireDate > .now {
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: "recovery-morning", content: content, trigger: trigger))
        }
        _ = morning
        morning = .now
    }

    func rescheduleProactiveNotifications(peakHours: [Int]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<24).map { "forecast-\($0)" })
        guard !peakHours.isEmpty else { return }
        for hour in peakHours.prefix(3) {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
            comps.hour = max(0, hour - 1)
            comps.minute = 30
            guard let fireDate = Calendar.current.date(from: comps), fireDate > .now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Your tough window is coming up"
            content.body = "Around \(hour):00 is one of your peak craving hours. A 90-second surf can carry you through."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: "forecast-\(hour)", content: content, trigger: trigger))
        }
    }
}

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    @Published var authorized = false
    @Published var restingHRDelta: Double?
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() {
        guard isAvailable else { return }
        let read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ].compactMap { $0 }.reduce(into: Set<HKObjectType>()) { $0.insert($1) }
        store.requestAuthorization(toShare: [], read: read) { [weak self] success, _ in
            guard let self else { return }
            Task { @MainActor in
                self.authorized = success
                if success { self.fetchRestingHRDelta() }
            }
        }
    }

    func fetchRestingHRDelta() {
        guard isAvailable,
              let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return }
        let cal = Calendar.current
        let end = Date.now
        guard let recentStart = cal.date(byAdding: .day, value: -7, to: end),
              let baselineStart = cal.date(byAdding: .day, value: -30, to: end) else { return }
        Task { @MainActor in
            let recent = await fetchAverage(type: type, start: recentStart, end: end)
            let baseline = await fetchAverage(type: type, start: baselineStart, end: recentStart)
            if let recent, let baseline, baseline > recent {
                restingHRDelta = baseline - recent
            }
        }
    }

    private func fetchAverage(type: HKQuantityType, start: Date, end: Date) async -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { continuation in
            store.execute(HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, _ in
                let value = statistics?.averageQuantity().map { $0.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
                continuation.resume(returning: value)
            })
        }
    }
}
