import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var stats: StatsEngine

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ringSection
                    capsuleRow
                    entryGuideCard
                    peakCard
                    logButton
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Today")
            .onAppear { appState.rescheduleForecast() }
        }
    }

    private var progress: Double {
        guard stats.todayLimit > 0, stats.todayLimit != .max else { return 0 }
        return min(1, Double(stats.netPuffsToday) / Double(stats.todayLimit))
    }

    private var ringSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemFill), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [Color(red: 0.13, green: 0.83, blue: 0.93), Color(red: 0.43, green: 0.91, blue: 0.72)], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                VStack(spacing: 2) {
                    Text("\(stats.netPuffsToday)")
                        .font(.system(size: 68, weight: .bold, design: .rounded))
                    Text(limitText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 280, maxHeight: 280)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Today \(stats.netPuffsToday) puffs of \(limitText)")

            if overLimit {
                gentlePrompt
            }
        }
    }

    private var limitText: String {
        stats.todayLimit == .max ? "no cap yet" : "of \(stats.todayLimit) today"
    }

    private var overLimit: Bool {
        stats.todayLimit != .max && stats.netPuffsToday > stats.todayLimit
    }

    private var gentlePrompt: some View {
        VStack(spacing: 8) {
            Text("You've reached today's cap — a free 90-second surf?")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("Start surf") { appState.showSOS = true }
                .buttonStyle(.bordered)
                .tint(.mint)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var capsuleRow: some View {
        HStack(spacing: 12) {
            capsule(icon: "dollarsign.circle.fill", value: stats.moneySavedText, label: "saved")
            capsule(icon: "heart.circle.fill", value: "D\(stats.recoveryDays)", label: "recovery")
            capsule(icon: "flame.fill", value: "\(stats.currentStreak)", label: "day streak")
        }
    }

    private func capsule(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(.mint)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }

    private var entryGuideCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("The app that never asks you to open it")
            } icon: {
                Image(systemName: "externaldrive.badge.wifi")
            }
            .font(.headline.weight(.semibold))
            Text("Set up logging outside the app: add the Home Screen widget, use Control Center, ask Siri \"log a puff\", or assign the Action Button / Back Tap via the Shortcuts app. This app only shows you rewards.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var peakCard: some View {
        if !stats.peakHours.isEmpty {
            HStack {
                Label("Peak craving hours: \(stats.peakHours.map(String.init).joined(separator: ", ")):00", systemImage: "chart.bar.fill")
                    .font(.subheadline)
                Spacer()
            }
            .padding(14)
            .background(Color.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var logButton: some View {
        Button {
            appState.logPuff(source: .app)
        } label: {
            Label("Log a puff", systemImage: "hand.tap.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel("Log one puff")
    }
}
