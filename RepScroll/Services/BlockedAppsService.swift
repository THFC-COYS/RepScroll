import Foundation
import os

/// The v1.0 placeholder app list, now backing simulation mode only.
///
/// v1.1 shipped real blocking: ScreenTimeService owns the Screen Time
/// authorization, the user picks real apps with FamilyActivityPicker, and
/// ShieldManager applies ManagedSettings shields from that selection.
/// This service remains for the simulation fallback (authorization not
/// determined or denied) and as the in-app entry points on Home.
@MainActor
final class BlockedAppsService: ObservableObject {
    @Published var enabledApps: Set<String> {
        didSet { persistEnabledApps() }
    }

    private let storageKey = "blockedApps.enabled"
    private let logger = Logger(subsystem: "com.repscroll.app", category: "BlockedApps")

    init() {
        if let saved = UserDefaults.standard.array(forKey: storageKey) as? [String] {
            enabledApps = Set(saved)
        } else {
            // Default: Instagram + TikTok enabled for demo
            enabledApps = AppConfig.defaultBlockedAppIDs
        }
    }

    var allApps: [BlockedApp] { BlockedApp.placeholders }

    var activeBlockedApps: [BlockedApp] {
        allApps.filter { enabledApps.contains($0.id) }
    }

    func isBlocked(bundleIdentifier: String) -> Bool {
        allApps.first { $0.bundleIdentifier == bundleIdentifier }
            .map { enabledApps.contains($0.id) } ?? false
    }

    func toggle(_ app: BlockedApp) {
        if enabledApps.contains(app.id) {
            enabledApps.remove(app.id)
        } else {
            enabledApps.insert(app.id)
        }
    }

    var usesSimulation: Bool { ScreenTimeBridge.isSimulation }

    private func persistEnabledApps() {
        UserDefaults.standard.set(Array(enabledApps), forKey: storageKey)
    }
}