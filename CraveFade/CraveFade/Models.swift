import Foundation
import SwiftData

enum QuitGoal: String, Codable, CaseIterable, Identifiable {
    case quitNow, taper, observe
    var id: String { rawValue }
    var title: String {
        switch self {
        case .quitNow: return "Quit today"
        case .taper: return "6-week taper"
        case .observe: return "Just track for now"
        }
    }
}

enum LogSource: String, Codable {
    case watch, widget, siri, button, app, liveActivity
}

@Model
final class PuffEvent {
    var uuid: UUID = UUID()
    var timestamp: Date = Date.now
    var loggedAt: Date = Date.now
    var source: String = LogSource.app.rawValue
    var deviceNonce: Int = 0
    init(uuid: UUID = UUID(), timestamp: Date = .now, source: LogSource, deviceNonce: Int = 0) {
        self.uuid = uuid
        self.timestamp = timestamp
        self.loggedAt = .now
        self.source = source.rawValue
        self.deviceNonce = deviceNonce
    }
}

@Model
final class CravingEvent {
    var uuid: UUID = UUID()
    var startedAt: Date = Date.now
    var outcome: String = OutcomeKind.won.rawValue
    var triggerTag: String? = nil
    var aiUsed: Bool = false
    init(outcome: String, triggerTag: String? = nil, aiUsed: Bool = false) {
        self.uuid = UUID()
        self.startedAt = .now
        self.outcome = outcome
        self.triggerTag = triggerTag
        self.aiUsed = aiUsed
    }
    var outcomeKind: OutcomeKind { OutcomeKind(rawValue: outcome) ?? .won }
}

enum OutcomeKind: String {
    case won, slipped, aiHelped = "ai_helped"
}

@Model
final class CorrectionEvent {
    var targetUUID: UUID = UUID()
    var createdAt: Date = Date.now
    init(targetUUID: UUID) {
        self.targetUUID = targetUUID
        self.createdAt = .now
    }
}

@Model
final class QuitProfile {
    var id: UUID = UUID()
    var baselinePuffs: Int = 100
    var costPerUnit: Double = 8.0
    var puffsPerUnit: Int = 600
    var goalRaw: String = QuitGoal.observe.rawValue
    var taperPercent: Double = 0.15
    var startDate: Date = Date.now
    var quitDate: Date? = nil
    var deviceType: String = "pod"
    var onboardingDone: Bool = false
    var wishName: String = ""
    var wishCost: Double = 0
    init() {}
    var goal: QuitGoal {
        get { QuitGoal(rawValue: goalRaw) ?? .observe }
        set { goalRaw = newValue.rawValue }
    }
    var costPerPuff: Double {
        guard puffsPerUnit > 0 else { return 0 }
        return costPerUnit / Double(puffsPerUnit)
    }
}

@Model
final class WishItem {
    var id: UUID = UUID()
    var name: String = ""
    var targetAmount: Double = 0
    var createdAt: Date = Date.now
    var isPrimary: Bool = false
    init(name: String, targetAmount: Double, isPrimary: Bool = false) {
        self.id = UUID()
        self.name = name
        self.targetAmount = targetAmount
        self.createdAt = .now
        self.isPrimary = isPrimary
    }
}
