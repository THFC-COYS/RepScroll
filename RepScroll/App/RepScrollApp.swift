import SwiftUI
import CoreData

/// Root application entry point. Wires persistence, subscriptions, and app-wide state.
@main
struct RepScrollApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var notificationService = NotificationService()

    let persistenceController = PersistenceController.shared

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                .environmentObject(subscriptionService)
                .environmentObject(notificationService)
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