import SwiftUI
import CoreData

/// Root application entry point. Wires persistence, subscriptions, and app-wide state.
@main
struct RepScrollApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var unlockService = ScrollUnlockService.shared

    let persistenceController = PersistenceController.shared

    init() {
        Self.applyFirstLaunchDefaults()
        configureAppearance()
    }

    private static func applyFirstLaunchDefaults() {
        let key = "didApplyLaunchDefaults"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(AppConfig.freeUnlockMinutes, forKey: "unlockMinutes")
        UserDefaults.standard.set(true, forKey: key)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                .environmentObject(subscriptionService)
                .environmentObject(notificationService)
                .environmentObject(unlockService)
                .preferredColorScheme(.dark)
                .task {
                    await subscriptionService.loadProducts()
                    await subscriptionService.refreshEntitlements()
                }
        }
    }

    private func configureAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(RepScrollTheme.textPrimary)
        ]
    }
}