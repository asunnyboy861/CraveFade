import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false

    private let privacyURL = URL(string: "https://asunnyboy861.github.io/CraveFade/privacy.html")!
    private let termsURL = URL(string: "https://asunnyboy861.github.io/CraveFade/terms.html")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 48))
                        .foregroundStyle(.mint)
                        .accessibilityHidden(true)
                    Text("CraveFade Pro")
                        .font(.largeTitle.bold())
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow("infinity", "Unlimited on-device AI coach")
                        featureRow("cloud.fill", "Deep Mode with your own API key")
                        featureRow("chart.bar.fill", "Craving forecast & proactive nudges")
                        featureRow("moon.stars.fill", "Full history heatmap & custom slope")
                        featureRow("person.2.fill", "5 Quit Buddies")
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))

                    if purchaseManager.isLoading {
                        ProgressView()
                    } else if let yearly = purchaseManager.yearlyProduct {
                        subscribeButton(yearly, primary: true)
                    }
                    if let monthly = purchaseManager.monthlyProduct {
                        subscribeButton(monthly, primary: false)
                    }
                    if let lifetime = purchaseManager.lifetimeProduct {
                        subscribeButton(lifetime, primary: false)
                    }

                    Button("Restore Purchases") {
                        Task { await purchaseManager.restorePurchases() }
                    }
                    .font(.footnote)

                    if let error = purchaseManager.loadError {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }

                    VStack(spacing: 10) {
                        Text("Pro renews automatically: $4.99/month or $29.99/year with a 7-day free trial. The $59.99 Lifetime plan is a one-time purchase. Cancel anytime at least 24 hours before renewal in your App Store account settings. CraveFade Pro never gates your core quit tools.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: privacyURL)
                                .font(.caption2)
                            Link("Terms of Use", destination: termsURL)
                                .font(.caption2)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await purchaseManager.loadProducts() }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.mint).frame(width: 24)
            Text(text).font(.subheadline)
        }
    }

    private func subscribeButton(_ product: Product, primary: Bool) -> some View {
        Button {
            purchasing = true
            Task {
                _ = await purchaseManager.purchase(product)
                purchasing = false
            }
        } label: {
            VStack(spacing: 2) {
                Text(primary ? "Start 7-day free trial" : product.displayName)
                    .font(.headline)
                Text(subtitle(product))
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(primary ? .mint : .secondary)
        .disabled(purchasing)
        .accessibilityLabel("\(product.displayName), \(subtitle(product))")
    }

    private func subtitle(_ product: Product) -> String {
        switch product.id {
        case PurchaseManager.monthlyID: return "$4.99 per month"
        case PurchaseManager.yearlyID: return "$29.99 per year · ~$2.50/month"
        case PurchaseManager.lifetimeID: return "$59.99 once · forever"
        default: return product.displayPrice
        }
    }
}
