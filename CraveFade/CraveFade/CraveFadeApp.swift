import SwiftUI
import SwiftData

@main
struct CraveFadeApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appState.stats)
                .environmentObject(appState.purchaseManager)
                .modelContainer(appState.container)
                .preferredColorScheme(.dark)
                .tint(Color(red: 0.13, green: 0.83, blue: 0.93))
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.onboardingComplete {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .fullScreenCover(isPresented: $appState.showSOS) {
            SOSView()
        }
        .sheet(isPresented: $appState.showPaywall) {
            PaywallView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "circle.circle.fill") }
            CoachView()
                .tabItem { Label("Coach", systemImage: "bubble.left.and.text.bubble.right.fill") }
            CalendarView()
                .tabItem { Label("History", systemImage: "calendar") }
            RecoveryView()
                .tabItem { Label("Progress", systemImage: "heart.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
