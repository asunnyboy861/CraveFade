import SwiftUI

struct SOSView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var stats: StatsEngine
    @Environment(\.dismiss) private var dismiss

    @State private var remaining = 90
    @State private var phaseIndex = 0
    @State private var scale: CGFloat = 0.7
    @State private var timer: Timer?
    @State private var squeezeCount = 0
    @State private var finished = false
    @State private var stillWant = false
    @State private var slipped = false

    private let phases: [(name: String, seconds: Int)] = [("Inhale", 4), ("Hold", 2), ("Exhale", 6)]

    private var isBedtime: Bool {
        Calendar.current.component(.hour, from: .now) >= 22 || Calendar.current.component(.hour, from: .now) < 5
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.10, green: 0.08, blue: 0.24), Color(red: 0.16, green: 0.12, blue: 0.34)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if finished {
                victoryView
            } else if stillWant {
                CoachEmbedView(onDone: { outcome in
                    handleCoachOutcome(outcome)
                })
            } else {
                breathingView
            }
        }
        .onAppear(perform: startTimer)
        .onDisappear { timer?.invalidate() }
    }

    private var triggerTag: () -> String? {
        { isBedtime ? "bedtime" : nil }
    }

    private var breathingView: some View {
        VStack(spacing: 32) {
            Text(isBedtime ? "Sleep-aid surf" : "Ride the wave")
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundStyle(.white)
            Text("Most cravings fade in 3 minutes")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 14)
                    .frame(width: 240, height: 240)
                Circle()
                    .fill(RadialGradient(colors: [.indigo.opacity(0.55), .clear], center: .center, startRadius: 20, endRadius: 130))
                    .frame(width: 240, height: 240)
                    .scaleEffect(scale)
                Circle()
                    .stroke(.indigo.opacity(0.7), lineWidth: 4)
                    .frame(width: 240, height: 240)
                    .scaleEffect(scale)
                VStack(spacing: 6) {
                    Text(phases[phaseIndex].name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(remaining)s")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("90s total")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .animation(.easeInOut(duration: 1.2), value: scale)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Breathing \(phases[phaseIndex].name), \(remaining) seconds left")

            VStack(spacing: 8) {
                Image(systemName: "hand.draw.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.75))
                Text("Hands need help too — tap to squeeze")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(squeezeCount) squeezes")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                squeezeCount += 1
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }

            Button("I still want to vape") {
                timer?.invalidate()
                stillWant = true
            }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .buttonStyle(.bordered)
                .tint(.white)
                .accessibilityHint("Opens the AI coach for extra help")
        }
        .padding(24)
    }

    private var victoryView: some View {
        VStack(spacing: 20) {
            Text("Wave #\(stats.winsCount) crushed!")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.red)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.red)
                .accessibilityHidden(true)
            Text("This one saved \(String(format: "$%.2f", appState.stats.moneyThisSession(1)))")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
            Text("Cravings don't get crushed. They fade. 🌊")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.top, 12)
        }
        .padding(28)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            remaining -= 1
            let phase = phases[phaseIndex]
            switch phase.name {
            case "Inhale": scale = min(1.0, scale + 0.25 / Double(phase.seconds))
            case "Hold": break
            case "Exhale": scale = max(0.7, scale - 0.3 / Double(phase.seconds))
            default: break
            }
            if remaining <= 0 {
                timer?.invalidate()
                MainActor.assumeIsolated {
                    appState.recordCraving(outcome: .won, trigger: triggerTag())
                }
                finishWon(aiUsed: false)
            }
            if isPhaseEnd() {
                phaseIndex = (phaseIndex + 1) % phases.count
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
    }

    private func isPhaseEnd() -> Bool {
        let elapsed = 90 - remaining
        let cycle = phases.map(\.seconds).reduce(0, +)
        let inCycle = elapsed % cycle
        return inCycle == 0
    }

    private func handleCoachOutcome(_ outcome: String) {
        switch outcome {
        case "slipped":
            timer?.invalidate()
            appState.recordCraving(outcome: .slipped, trigger: triggerTag(), aiUsed: true)
            dismiss()
        case "ai_helped":
            timer?.invalidate()
            dismiss()
        default:
            stillWant = false
            startTimer()
        }
    }

    private func finishWon(aiUsed: Bool) {
        _ = aiUsed
        finished = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct CoachEmbedView: View {
    var onDone: (String) -> Void
    var body: some View {
        CoachView(mode: .embedded(onDone: onDone))
    }
}
