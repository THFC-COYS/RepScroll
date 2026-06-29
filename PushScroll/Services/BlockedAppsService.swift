import Foundation
import os

/// Placeholder service for social-app blocking integration.
///
/// Production expansion path:
/// 1. Request `com.apple.developer.family-controls` entitlement
/// 2. Use `FamilyControls` + `ManagedSettings` to shield selected apps
/// 3. Implement `DeviceActivityMonitor` extension to intercept launches
/// 4. Deep-link into PushScroll challenge flow via App Groups
///
/// Current build simulates the gate UX for demo and TestFlight review.
@MainActor
final class BlockedAppsService: ObservableObject {
    @Published var enabledApps: Set<String> {
        didSet { persistEnabledApps() }
    }

    private let storageKey = "blockedApps.enabled"
    private let logger = Logger(subsystem: "com.pushscroll.app", category: "BlockedApps")

    init() {
        if let saved = UserDefaults.standard.array(forKey: storageKey) as? [String] {
            enabledApps = Set(saved)
        } else {
            // Default: Instagram + TikTok enabled for demo
            enabledApps = Set(["instagram", "tiktok"])
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

    /// Simulates Screen Time intercept — production replaces with extension callback.
    func shouldChallengeBeforeOpening(app: BlockedApp, isPremium: Bool) -> Bool {
        guard enabledApps.contains(app.id) else { return false }
        // Free users get 1 gate/day; premium unlimited (placeholder logic)
        if isPremium { return true }
        let lastGate = UserDefaults.standard.object(forKey: "lastGateDate") as? Date
        let today = Calendar.current.startOfDay(for: Date())
        if let lastGate, Calendar.current.startOfDay(for: lastGate) == today {
            return false
        }
        return true
    }

    func recordGateUnlock() {
        UserDefaults.standard.set(Date(), forKey: "lastGateDate")
    }

    private func persistEnabledApps() {
        UserDefaults.standard.set(Array(enabledApps), forKey: storageKey)
    }
}