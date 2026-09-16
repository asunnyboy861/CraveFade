import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var stats: StatsEngine
    @EnvironmentObject private var health: HealthKitService

    @AppStorage("healthkitEnabled") private var healthkitEnabled = false
    @State private var showHealthInfo = false

    private let milestones: [(Int, String, String)] = [
        (0, "20 min", "Heart rate begins to drop"),
        (0, "12 hours", "Carbon monoxide level normalizes"),
        (0, "2 weeks", "Circulation and lung function improve"),
        (0, "1–9 months", "Lungs repair: cilia regrow, coughing decreases")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    moneyCard
                    wishlistSection
                    timelineSection
                    healthSection
                    disclaimer
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Progress")
            .onAppear { if healthkitEnabled { health.requestAuthorization() } }
        }
    }

    private var moneyCard: some View {
        VStack(spacing: 8) {
            Text("Watch the money come back")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(stats.moneySavedText)
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Color(red: 0.13, green: 0.83, blue: 0.93), Color(red: 0.43, green: 0.91, blue: 0.72)], startPoint: .leading, endPoint: .trailing)
                )
                .accessibilityLabel("Total saved \(stats.moneySavedText)")
            Text("\(stats.winsCount) cravings won · weekly win rate \(Int(stats.weeklyAchievement * 100))%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var wishlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wish list").font(.headline)
            if appState.profile?.wishName.isEmpty == false, let wish = appState.profile {
                let progress = wish.wishCost > 0 ? min(1, stats.moneySavedTotal / wish.wishCost) : 0
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(wish.wishName).font(.subheadline.weight(.medium))
                        Spacer()
                        Text(String(format: "$%.2f / $%.0f", stats.moneySavedTotal, wish.wishCost))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: progress)
                        .tint(.mint)
                }
            } else {
                Text("Add a goal in Settings — watch your savings flow into something you actually want.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your recovery timeline").font(.headline)
            ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: index == currentMilestoneIndex ? "circle.inset.filled" : "circle")
                        .foregroundStyle(index == currentMilestoneIndex ? .mint : .secondary)
                        .font(.title3)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(milestone.1).font(.subheadline.weight(.semibold))
                        Text(milestone.2).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(index == currentMilestoneIndex ? 10 : 0)
                .background(index == currentMilestoneIndex ? Color.mint.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var currentMilestoneIndex: Int {
        let days = stats.recoveryDays
        if days >= 30 { return 3 }
        if days >= 14 { return 2 }
        if days >= 1 { return 1 }
        return 0
    }

    private var healthSection: some View {
        Section {
            HStack {
                Image(systemName: "heart.circle.fill").foregroundStyle(.red).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HealthKit Integration").font(.headline)
                    Text("Sync resting heart rate to Apple Health via HealthKit").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showHealthInfo = true
                } label: {
                    Text("Learn More").font(.caption).foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
            Toggle("Sync HealthKit heart-rate insights", isOn: $healthkitEnabled)
                .onChange(of: healthkitEnabled) { _, enabled in
                    if enabled { health.requestAuthorization() }
                }
            if healthkitEnabled, let delta = health.restingHRDelta, delta > 0 {
                Label("Your resting heart rate dropped \(String(format: "%.1f", delta)) bpm", systemImage: "arrow.down.heart.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        } header: {
            HStack {
                Text("Apple Health (HealthKit)")
                Spacer()
                Image(systemName: "heart.text.square.fill").foregroundStyle(.red)
            }
        } footer: {
            Text("This app uses the HealthKit framework to read resting heart rate from the Apple Health app, only with your explicit permission, to show how your body recovers as puffs drop.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showHealthInfo) { HealthKitInfoView() }
    }

    private var disclaimer: some View {
        Text("CraveFade is a self-help tool, not medical advice. If you need support, call 1-800-QUIT-NOW.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

struct HealthKitInfoView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                    Text("HealthKit Integration").font(.title.bold())
                    Text("CraveFade integrates with Apple Health through the HealthKit framework to read your resting heart rate and sleep data, only with your explicit permission. This lets the app show real recovery signals — like a falling resting heart rate — as your puffs drop. The app never writes health data and never reads anything without your authorization.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
