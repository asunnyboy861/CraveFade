import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var health: HealthKitService
    @StateObject private var aiViewModel = AISettingsViewModel()
    @State private var showPaywallDirect = false

    private let supportURL = URL(string: "https://asunnyboy861.github.io/CraveFade/support.html")!
    private let privacyURL = URL(string: "https://asunnyboy861.github.io/CraveFade/privacy.html")!
    private let termsURL = URL(string: "https://asunnyboy861.github.io/CraveFade/terms.html")!

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                aiSection
                profileSection
                podScanSection
                healthSection
                supportSection
                legalSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear { aiViewModel.refresh() }
            .sheet(isPresented: $showPaywallDirect) { PaywallView() }
        }
    }

    private var proSection: some View {
        Section {
            if purchaseManager.isPro {
                Label("CraveFade Pro active — thank you!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.mint)
            } else {
                Button {
                    appState.showPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "bolt.fill")
                        .font(.headline)
                }
            }
            Link("Manage subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                .font(.subheadline)
        } header: {
            Text("Subscription")
        } footer: {
            Text("Free forever core. Price on the box. Cancel anytime.")
        }
    }

    private var aiSection: some View {
        Section {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.mint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(aiViewModel.fmAvailable ? "On-device AI ready" : "On-device AI unavailable")
                        .font(.headline)
                    Text(aiViewModel.fmAvailable
                         ? "Apple Intelligence handles your coach privately, offline."
                         : "Apple Intelligence requires iOS 26+. Configure your own API key for Deep Mode.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if aiViewModel.keyConfigured {
                HStack {
                    Label("Deep Mode key active", systemImage: "key.fill")
                        .font(.subheadline)
                        .foregroundStyle(.mint)
                    Spacer()
                    Button("Remove", role: .destructive) { aiViewModel.deleteKey() }
                        .font(.caption)
                }
            } else {
                SecureField("Paste your DeepSeek API key", text: $aiViewModel.apiKey)
                    .textContentType(.password)
                Button("Save API key") { aiViewModel.saveKey() }
                    .disabled(aiViewModel.apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text("AI Configuration")
        } footer: {
            Text("Your key is stored in the iOS Keychain and sent only to api.deepseek.com. CraveFade never sees your DeepSeek usage or charges you for API calls.")
        }
    }

    private var profileSection: some View {
        Section {
            if let profile = appState.profile {
                Stepper("Daily baseline: \(profile.baselinePuffs)", value: Binding(
                    get: { profile.baselinePuffs },
                    set: { newValue in
                        profile.baselinePuffs = newValue
                        appState.saveProfile()
                    }
                ), in: 10...400, step: 10)
                if profile.goal == .taper {
                    Stepper("Taper slope: \(Int(profile.taperPercent * 100))%/week", value: Binding(
                        get: { profile.taperPercent },
                        set: { newValue in
                            profile.taperPercent = min(0.20, max(0.10, newValue))
                            appState.saveProfile()
                        }
                    ), in: 0.10...0.20, step: 0.01)
                }
                TextField("Wish list goal (e.g. PS5)", text: Binding(
                    get: { profile.wishName },
                    set: { profile.wishName = $0 }
                ))
                HStack {
                    Text("Goal price")
                    Spacer()
                    TextField("0", value: Binding(
                        get: { profile.wishCost },
                        set: { newValue in
                            profile.wishCost = newValue
                            appState.saveProfile()
                        }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                }
            }
        } header: {
            Text("Your plan")
        } footer: {
            Text("Changing your plan never resets your history, money saved, or weekly win rate.")
        }
    }

    @ViewBuilder
    private var podScanSection: some View {
        if purchaseManager.isPro || AIConfiguration.hasAPIKey {
            PodScanSection()
        } else {
            Section {
                Label("Pod Scan is a Deep Mode feature", systemImage: "camera.viewfinder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } footer: {
                Text("Get Pro or add your own API key to scan pods and estimate nicotine content.")
            }
        }
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
                NavigationLink {
                    HealthKitInfoView()
                } label: {
                    Text("Learn More").font(.caption).foregroundStyle(.blue)
                }
            }
        } header: {
            HStack {
                Text("Apple Health (HealthKit)")
                Spacer()
                Image(systemName: "heart.text.square.fill").foregroundStyle(.red)
            }
        } footer: {
            Text("This app uses the HealthKit framework to read resting heart rate from the Apple Health app, only with your explicit permission. No health data is written.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var supportSection: some View {
        Section {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
            }
            Link("Support Page", destination: supportURL)
            if !health.authorized, health.isAvailable {
                Button("Enable Apple Health sync") { health.requestAuthorization() }
            }
        } header: {
            Text("Support")
        }
    }

    private var legalSection: some View {
        Section {
            Link("Privacy Policy", destination: privacyURL)
            Link("Terms of Use", destination: termsURL)
            Link("1-800-QUIT-NOW", destination: URL(string: "tel://18002731999")!)
        } header: {
            Text("Legal")
        } footer: {
            Text("CraveFade is a self-help tool, not medical advice. This disclaimer cannot be disabled.")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Slogan", value: "Cravings fade in 3 minutes.")
        } footer: {
            Text(appVersion)
        }
    }
}

struct PodScanSection: View {
    @EnvironmentObject private var appState: AppState
    @State private var photoItem: PhotosPickerItem?
    @State private var result: String?
    @State private var busy = false

    var body: some View {
        Section {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Scan a pod photo", systemImage: "camera.viewfinder")
            }
            .disabled(busy)
            if busy { ProgressView("Estimating…") }
            if let result {
                Text(result).font(.subheadline)
            }
        } header: {
            Text("Pod Scan (Deep Mode)")
        } footer: {
            Text("Estimates nicotine mg/ml from your pod photo. The estimate is a starting point — adjust your plan numbers manually anytime.")
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            busy = true
            result = nil
            Task {
                defer { busy = false }
                guard let data = try? await item.loadTransferable(type: Data.self) else {
                    result = "Couldn't load the photo."
                    return
                }
                do {
                    let estimate = try await CoachEngine.shared.analyzePodPhoto(jpegBase64: data.base64EncodedString())
                    result = String(format: "~%.0f mg/ml (confidence %.0f%%) — %@", estimate.mg_per_ml, estimate.confidence * 100, estimate.note)
                } catch {
                    result = "Scan failed. Check your API key and connection."
                }
                photoItem = nil
            }
        }
    }
}
