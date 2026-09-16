import AppIntents
import SwiftUI

struct LogPuffIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Puff"
    static let description = IntentDescription("Log one puff without opening the app.")
    static let openAppWhenRun = false

    @Parameter(title: "Source", default: "button") var source: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let sourceKind = LogSource(rawValue: source) ?? .button
        let result = AppState.shared.logPuff(source: sourceKind)
        let limitText = result.limit == .max ? "∞" : "\(result.limit)"
        return .result(dialog: IntentDialog(stringLiteral: "Logged · \(result.net)/\(limitText)"))
    }
}

struct SOSStartIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Craving SOS"
    static let description = IntentDescription("Open the 90-second craving surf.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.showSOS = true
        return .result()
    }
}

struct CraveFadeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogPuffIntent(),
            phrases: ["Log a puff in \(.applicationName)", "\(.applicationName) log a puff"],
            shortTitle: "Log a Puff",
            systemImageName: "hand.tap.fill"
        )
        AppShortcut(
            intent: SOSStartIntent(),
            phrases: ["Craving SOS in \(.applicationName)", "\(.applicationName) craving surf"],
            shortTitle: "Craving SOS",
            systemImageName: "waveform.path.ecg"
        )
    }
}
