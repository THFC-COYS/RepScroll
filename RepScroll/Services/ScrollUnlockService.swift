import Foundation
import Combine

/// Tracks temporary scroll access earned after completing exercise challenges.
///
/// Unlock expiries persist in the App Group suite (v1.1) so ShieldManager,
/// running in the app or the monitor extension, can reconcile system
/// shields against live unlock windows. Wiring to real blocking goes
/// through ScreenTimeBridge and is a no-op in simulation mode.
@MainActor
final class ScrollUnlockService: ObservableObject {
    static let shared = ScrollUnlockService()

    @Published private(set) var activeUnlocks: [String: Date] = [:]

    /// Must match ShieldManager.unlocksKey in the shared target code.
    private let storageKey = "scrollUnlocks.expiry"
    private let defaults: UserDefaults = UserDefaults(suiteName: AppConfig.appGroupIdentifier) ?? .standard
    private let defaultMinutes = AppConfig.freeUnlockMinutes

    init() {
        load()
        pruneExpired()
    }

    var unlockDurationMinutes: Int {
        UserDefaults.standard.object(forKey: "unlockMinutes") as? Int ?? defaultMinutes
    }

    func isUnlocked(appId: String) -> Bool {
        pruneExpired()
        guard let expiry = activeUnlocks[appId] else { return false }
        return expiry > Date()
    }

    func remainingSeconds(for appId: String) -> Int {
        guard let expiry = activeUnlocks[appId] else { return 0 }
        return max(0, Int(expiry.timeIntervalSinceNow))
    }

    func formattedRemaining(for appId: String) -> String {
        let secs = remainingSeconds(for: appId)
        if secs <= 0 { return "Expired" }
        let m = secs / 60
        let s = secs % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    func grantUnlock(appId: String, minutes: Int? = nil) {
        let duration = minutes ?? unlockDurationMinutes
        let expiry = Date().addingTimeInterval(TimeInterval(duration * 60))
        activeUnlocks[appId] = expiry
        persist()
        // Real mode: shields drop now; the monitor extension restores them
        // when the latest open window ends.
        if let latest = activeUnlocks.values.max() {
            ScreenTimeBridge.handleUnlockGranted(expiresAt: latest)
        }
    }

    func revoke(appId: String) {
        activeUnlocks.removeValue(forKey: appId)
        persist()
        ScreenTimeBridge.handleUnlockRevoked()
    }

    func pruneExpired() {
        let now = Date()
        let before = activeUnlocks.count
        activeUnlocks = activeUnlocks.filter { $0.value > now }
        if activeUnlocks.count != before {
            persist()
            // A window closed while the app was open: reconcile shields in
            // case the DeviceActivity callback has not landed yet.
            ScreenTimeBridge.refreshShields()
        }
    }

    private func load() {
        guard let raw = defaults.dictionary(forKey: storageKey) as? [String: TimeInterval] else { return }
        activeUnlocks = raw.mapValues { Date(timeIntervalSince1970: $0) }
    }

    private func persist() {
        let raw = activeUnlocks.mapValues { $0.timeIntervalSince1970 }
        defaults.set(raw, forKey: storageKey)
    }
}