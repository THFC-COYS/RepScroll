import SwiftUI

/// Routes between onboarding, main tabs, paywall, and blocked-app gate overlay.
struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .sheet(isPresented: $appState.showPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $appState.showBlockedGate) {
            if let app = appState.pendingBlockedApp {
                BlockedGateView(blockedApp: app)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.icon) }
                .tag(AppTab.home)

            ChallengeView()
                .tabItem { Label(AppTab.challenge.title, systemImage: AppTab.challenge.icon) }
                .tag(AppTab.challenge)

            HistoryView()
                .tabItem { Label(AppTab.history.title, systemImage: AppTab.history.icon) }
                .tag(AppTab.history)

            SettingsView()
                .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.icon) }
                .tag(AppTab.settings)
        }
        .tint(RepScrollTheme.accent)
    }
}