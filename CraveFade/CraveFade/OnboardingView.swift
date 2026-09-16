import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var step = 0
    @State private var deviceType = "pod"
    @State private var dailyPuffs = 100.0
    @State private var costPerUnit = 8.0
    @State private var puffsPerUnit = 600
    @State private var goal: QuitGoal = .taper
    @State private var showSavings = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.04, green: 0.06, blue: 0.08), Color(red: 0.05, green: 0.15, blue: 0.18)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 28) {
                if showSavings {
                    planReveal
                } else {
                    questionView
                }
            }
            .padding(28)
        }
    }

    private var questionView: some View {
        VStack(alignment: .leading, spacing: 28) {
            ProgressView(value: Double(step + 1), total: 4)
                .tint(.mint)
            Text(questionTitle)
                .font(.system(.largeTitle, design: .rounded).bold())
            Spacer()
            questionContent
            Spacer()
            Button {
                next()
            } label: {
                Text(step == 3 ? "Build my plan" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(step == 2 && costPerUnit <= 0)
            .accessibilityLabel(step == 3 ? "Build my plan" : "Continue to next question")
        }
    }

    private var questionTitle: String {
        switch step {
        case 0: return "What do you vape?"
        case 1: return "Puffs per day?"
        case 2: return "What does one pod cost?"
        case 3: return "What's your goal?"
        default: return ""
        }
    }

    @ViewBuilder
    private var questionContent: some View {
        switch step {
        case 0:
            HStack(spacing: 12) {
                deviceCard("Disposables", icon: "rectangle.righthanded.inset.filled", value: "disposable")
                deviceCard("Pods", icon: "oval.portrait.fill", value: "pod")
                deviceCard("Refillable", icon: "drop.fill", value: "refillable")
            }
        case 1:
            VStack(spacing: 16) {
                Text("\(Int(dailyPuffs))")
                    .font(.system(size: 68, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.mint)
                Slider(value: $dailyPuffs, in: 10...400, step: 10)
                HStack {
                    ForEach([50, 100, 200, 300], id: \.self) { preset in
                        Button("\(preset)") { dailyPuffs = Double(preset) }
                            .buttonStyle(.bordered)
                            .tint(dailyPuffs == Double(preset) ? .mint : .gray)
                    }
                }
            }
        case 2:
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    Text("$")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("8.00", value: $costPerUnit, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                Stepper("Puffs per pod: \(puffsPerUnit)", value: $puffsPerUnit, in: 100...3000, step: 50)
                    .font(.headline)
            }
        case 3:
            VStack(spacing: 12) {
                ForEach(QuitGoal.allCases) { g in
                    Button {
                        goal = g
                    } label: {
                        HStack {
                            Image(systemName: goal == g ? "largecircle.fill.circle" : "circle")
                            Text(g.title).font(.headline)
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Goal: \(g.title)")
                }
            }
        default:
            EmptyView()
        }
    }

    private func deviceCard(_ title: String, icon: String, value: String) -> some View {
        Button {
            deviceType = value
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(deviceType == value ? Color.mint.opacity(0.25) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(deviceType == value ? Color.mint : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Device type: \(title)")
    }

    private var projectedSavings: Double {
        let perPuff = puffsPerUnit > 0 ? costPerUnit / Double(puffsPerUnit) : 0
        let weeklyDecline = pow(1.0 - 0.15, 6.0)
        let avgCut = Double(Int(dailyPuffs)) * (1.0 - weeklyDecline) / 2.0
        return avgCut * 42 * perPuff
    }

    private var planReveal: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 56))
                .foregroundStyle(Color.mint)
                .accessibilityHidden(true)
            Text("Your plan is ready")
                .font(.system(.largeTitle, design: .rounded).bold())
            VStack(spacing: 8) {
                Text("This plan will save you")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(String(format: "$%,.0f", projectedSavings))
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 0.13, green: 0.83, blue: 0.93), Color(red: 0.43, green: 0.91, blue: 0.72)], startPoint: .leading, endPoint: .trailing)
                    )
                    .minimumScaleFactor(0.5)
                if goal == .taper {
                    Text("Daily cap eases down ~15% each week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
            Button {
                applyPlan()
            } label: {
                Text("Start Day 1 🎉")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Start day one")
        }
    }

    private func next() {
        if step < 3 {
            step += 1
        } else {
            withAnimation { showSavings = true }
        }
    }

    private func applyPlan() {
        let profile = appState.profile ?? QuitProfile()
        profile.deviceType = deviceType
        profile.baselinePuffs = Int(dailyPuffs)
        profile.costPerUnit = costPerUnit
        profile.puffsPerUnit = puffsPerUnit
        profile.goal = goal
        profile.startDate = .now
        profile.onboardingDone = true
        appState.profile = profile
        appState.saveProfile()
        NotificationScheduler.shared.requestAuthorization()
    }
}
