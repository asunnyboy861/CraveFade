import Foundation
import Combine
import FoundationModels

struct AIProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var endpoint: String
    var model: String
}

enum AIConfiguration {
    static let keychainService = "com.zzoutuo.CraveFade.ai"
    static let keychainAccount = "deepseek-api-key"

    static var defaultProfile: AIProfile {
        AIProfile(name: "DeepSeek", endpoint: "https://api.deepseek.com/chat/completions", model: "deepseek-chat")
    }

    static var hasAPIKey: Bool {
        !(KeychainHelper.readString(service: keychainService, account: keychainAccount) ?? "").isEmpty
    }

    static var apiKey: String? {
        let key = KeychainHelper.readString(service: keychainService, account: keychainAccount)
        return (key?.isEmpty ?? true) ? nil : key
    }

    static func saveAPIKey(_ key: String) {
        KeychainHelper.saveString(key, service: keychainService, account: keychainAccount)
    }

    static func deleteAPIKey() {
        KeychainHelper.delete(service: keychainService, account: keychainAccount)
    }

    static var fmAvailable: Bool {
        if #available(iOS 26.0, *) {
            return OnDeviceCoach.isAvailable
        }
        return false
    }
}

struct CoachAdvice: Codable, Equatable {
    var empathy: String
    var microAction: String
    var crisisFlag: Bool
}

struct WeekSummary {
    var puffsTrend: String = "stable"
    var peakHour: Int = -1
    var topTriggers: [String] = []
}

enum AIServiceError: LocalizedError {
    case noBackend
    case crisis

    var errorDescription: String? {
        switch self {
        case .noBackend: return "No AI backend available. Breathing SOS still works offline."
        case .crisis: return nil
        }
    }
}

protocol AIServiceProtocol {
    func advise(summary: WeekSummary, mood: String) async throws -> CoachAdvice
    func weeklyReport(stats: String) async throws -> String
    func analyzePodPhoto(jpegBase64: String) async throws -> PodEstimate
}

struct PodEstimate: Codable {
    var mg_per_ml: Double
    var confidence: Double
    var note: String
}

final class DeepSeekService: AIServiceProtocol {
    private var apiKey: String? { AIConfiguration.apiKey }

    private func request(body: [String: Any]) async throws -> Data {
        guard let apiKey else { throw AIServiceError.noBackend }
        guard let url = URL(string: AIConfiguration.defaultProfile.endpoint) else { throw AIServiceError.noBackend }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return data
    }

    private func content(from data: Data) throws -> String {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        throw AIServiceError.noBackend
    }

    private static let coachSystem = """
        You are CraveFade's craving coach. Tone: warm, no-shame, ultra-brief. \
        The user has about 3 minutes of craving. Give ONE tiny action, never lectures. \
        Never mention opening the app. If any self-harm signal appears, respond with exactly {"empathy":"","microAction":"","crisisFlag":true}. \
        Reply with STRICT JSON only: {"empathy":"one sentence, max 12 words","microAction":"one concrete 30-second replacement action","crisisFlag":false}
        """

    func advise(summary: WeekSummary, mood: String) async throws -> CoachAdvice {
        let prompt = "Week: \(summary.puffsTrend), peak hour: \(summary.peakHour), triggers: \(summary.topTriggers.joined(separator: ",")), mood: \(mood)"
        let body: [String: Any] = [
            "model": AIConfiguration.defaultProfile.model,
            "messages": [
                ["role": "system", "content": Self.coachSystem],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"]
        ]
        let text = try content(from: try await request(body: body))
        guard let advice = try? JSONDecoder().decode(CoachAdvice.self, from: Data(text.utf8)) else {
            throw AIServiceError.noBackend
        }
        if advice.crisisFlag { throw AIServiceError.crisis }
        return advice
    }

    func weeklyReport(stats: String) async throws -> String {
        let body: [String: Any] = [
            "model": "deepseek-reasoner",
            "messages": [
                ["role": "system", "content": "You write a supportive no-shame weekly quit-vaping report: trigger attribution, next-week strategy, health context. Never medical advice. If any self-harm signal appears, lead with a crisis line suggestion (988 or 1-800-QUIT-NOW)."],
                ["role": "user", "content": "Anonymous weekly aggregates: \(stats)"]
            ]
        ]
        return try content(from: try await request(body: body))
    }

    func analyzePodPhoto(jpegBase64: String) async throws -> PodEstimate {
        let body: [String: Any] = [
            "model": AIConfiguration.defaultProfile.model,
            "messages": [
                ["role": "system", "content": "You estimate vape pod nicotine content from photos. Reply STRICT JSON: {\"mg_per_ml\":number,\"confidence\":0-1,\"note\":string}. Never medical advice."],
                ["role": "user", "content": [
                    ["type": "text", "text": "Estimate this pod."],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(jpegBase64)"]]
                ]]
            ],
            "response_format": ["type": "json_object"]
        ]
        let text = try content(from: try await request(body: body))
        return try JSONDecoder().decode(PodEstimate.self, from: Data(text.utf8))
    }
}

@available(iOS 26.0, *)
enum OnDeviceCoach {
    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    static func advise(summary: WeekSummary, mood: String) async throws -> CoachAdvice {
        let session = LanguageModelSession(instructions: """
            You are CraveFade's craving coach. Tone: warm, no-shame, ultra-brief. \
            The user has ~3 minutes of craving. Give ONE tiny action, never lectures. \
            Context you receive: last-7-day summary only. Never ask to open the app. \
            If any self-harm signal appears: set crisisFlag=true and say nothing else.
            """)
        let response = try await session.respond(
            to: "Week: \(summary.puffsTrend), peak: \(summary.peakHour), triggers: \(summary.topTriggers.joined(separator: ",")), mood: \(mood)",
            generating: CoachAdviceGenerable.self
        )
        let advice = CoachAdvice(empathy: response.content.empathy, microAction: response.content.microAction, crisisFlag: response.content.crisisFlag)
        if advice.crisisFlag { throw AIServiceError.crisis }
        return advice
    }
}

@available(iOS 26.0, *)
@Generable
nonisolated struct CoachAdviceGenerable {
    @Guide(description: "One-sentence empathy, max 12 words")
    var empathy: String
    @Guide(description: "One concrete 30-second replacement action")
    var microAction: String
    var crisisFlag: Bool
}

@MainActor
final class CoachEngine: ObservableObject {
    static let shared = CoachEngine()
    @Published var backendLabel: String = "🧠 On-device · Private · Works offline"

    func isAvailable() -> Bool {
        AIConfiguration.fmAvailable || AIConfiguration.hasAPIKey
    }

    func advise(summary: WeekSummary, mood: String) async throws -> CoachAdvice {
        if #available(iOS 26.0, *), OnDeviceCoach.isAvailable {
            backendLabel = "🧠 On-device · Private · Works offline"
            do {
                return try await OnDeviceCoach.advise(summary: summary, mood: mood)
            } catch let error as AIServiceError {
                throw error
            } catch {
                if AIConfiguration.hasAPIKey {
                    backendLabel = "☁️ Deep Mode · Your own API key"
                    return try await DeepSeekService().advise(summary: summary, mood: mood)
                }
                throw error
            }
        }
        guard AIConfiguration.hasAPIKey else {
            backendLabel = "Breathing SOS still works offline"
            throw AIServiceError.noBackend
        }
        backendLabel = "☁️ Deep Mode · Your own API key"
        return try await DeepSeekService().advise(summary: summary, mood: mood)
    }

    func weeklyReport(stats: String) async throws -> String {
        try await DeepSeekService().weeklyReport(stats: stats)
    }

    func analyzePodPhoto(jpegBase64: String) async throws -> PodEstimate {
        try await DeepSeekService().analyzePodPhoto(jpegBase64: jpegBase64)
    }
}

@MainActor
final class AISettingsViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var keyConfigured: Bool = AIConfiguration.hasAPIKey
    @Published var fmAvailable: Bool = AIConfiguration.fmAvailable
    @Published var saveConfirmed = false

    func refresh() {
        keyConfigured = AIConfiguration.hasAPIKey
        fmAvailable = AIConfiguration.fmAvailable
    }

    func saveKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        AIConfiguration.saveAPIKey(trimmed)
        apiKey = ""
        refresh()
        saveConfirmed = true
    }

    func deleteKey() {
        AIConfiguration.deleteAPIKey()
        refresh()
        saveConfirmed = false
    }
}
