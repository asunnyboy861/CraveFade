import SwiftUI

struct CoachView: View {
    enum Mode {
        case standard
        case embedded(onDone: (String) -> Void)
    }
    var mode: Mode = .standard

    @EnvironmentObject private var appState: AppState
    @State private var messages: [CoachMessage] = []
    @State private var input = ""
    @State private var busy = false
    @State private var showCrisis = false

    struct CoachMessage: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBadge
                if !appState.canUseCoach() {
                    quotaCard
                }
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if messages.isEmpty { introBubble }
                        ForEach(messages) { message in
                            bubble(message)
                        }
                        if busy { ProgressView("Thinking…").padding() }
                    }
                    .padding(16)
                }
                inputBar
            }
            .background(Color(.systemBackground))
            .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if case .embedded = mode {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back to surf") { onDone("won") }
                    }
                }
            }
            .sheet(isPresented: $showCrisis) { CrisisCardView() }
        }
    }

    private func onDone(_ outcome: String) {
        if case .embedded(let callback) = mode { callback(outcome) }
    }

    private var headerBadge: some View {
        Text(CoachEngine.shared.backendLabel)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground), in: Capsule())
            .padding(.top, 8)
    }

    private var quotaCard: some View {
        VStack(spacing: 6) {
            Text("Free on-device coach: \(max(0, 3 - appState.coachSessionsToday)) of 3 chats left today")
                .font(.footnote)
            Button("Go unlimited with Pro") { appState.showPaywall = true }
                .font(.footnote.weight(.semibold))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var introBubble: some View {
        bubble(CoachMessage(text: "I'm your craving coach. Tell me where you are and how you feel — we'll ride this out together.", isUser: false))
    }

    private func bubble(_ message: CoachMessage) -> some View {
        HStack {
            if message.isUser { Spacer() }
            Text(message.text)
                .padding(12)
                .background(message.isUser ? Color.mint.opacity(0.25) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            if !message.isUser { Spacer() }
        }
        .accessibilityElement(children: .combine)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("How are you feeling?", text: $input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
            Button {
                send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(busy || input.trimmingCharacters(in: .whitespaces).isEmpty || !appState.canUseCoach())
            .accessibilityLabel("Send to coach")
        }
        .padding(12)
    }

    private func send() {
        let mood = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !mood.isEmpty else { return }
        messages.append(CoachMessage(text: mood, isUser: true))
        input = ""
        busy = true
        let summary = appState.weekSummary()
        Task {
            do {
                appState.consumeCoachSession()
                let advice = try await CoachEngine.shared.advise(summary: summary, mood: mood)
                messages.append(CoachMessage(text: "\(advice.empathy) → \(advice.microAction)", isUser: false))
                appState.recordCraving(outcome: .aiHelped, aiUsed: true)
            } catch AIServiceError.crisis {
                showCrisis = true
            } catch {
                messages.append(CoachMessage(text: "I couldn't reach a coach backend. The 90-second breathing surf works offline — want to try it?", isUser: false))
            }
            busy = false
            if case .embedded = mode {
                onDone("ai_helped")
            }
        }
    }
}

struct CrisisCardView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "phone.fill")
                .font(.system(size: 52))
                .foregroundStyle(.red)
            Text("You're not alone")
                .font(.largeTitle.bold())
            Text("If you're thinking about hurting yourself, please reach out right now — free, confidential, 24/7.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Link(destination: URL(string: "tel://988")!) {
                Label("Call or text 988", systemImage: "phone.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            Link(destination: URL(string: "tel://18002731999")!) {
                Label("1-800-QUIT-NOW", systemImage: "phone.down.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            Button("Close") { dismiss() }
                .padding(.top, 8)
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}
