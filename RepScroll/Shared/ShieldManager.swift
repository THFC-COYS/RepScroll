import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

/// Single source of truth for Screen Time shield state (v1.1).
///
/// This file is compiled into the app, the RepScrollMonitor extension, and
/// any future Screen Time extension target. It must not reference app-only
/// types (AppConfig, services, views): extensions link it standalone.
///
/// Data flow:
/// - The user's FamilyActivitySelection is stored, JSON-encoded, in the App
///   Group UserDefaults suite so every process reads the same selection.
/// - Unlock expiries written by ScrollUnlockService live in the same suite
///   (key `scrollUnlocks.expiry`, app id -> epoch seconds), so the monitor
///   extension can tell whether an unlock window is still open.
/// - ManagedSettingsStore() writes go to the system-managed settings store
///   shared by the app and its extensions, so shields applied from any of
///   them take effect device-wide.
enum ShieldManager {
    /// Must match AppConfig.appGroupIdentifier in the app target.
    static let appGroupIdentifier = "group.com.repscroll.shared"
    static let selectionKey = "screenTime.familyActivitySelection"
    static let unlocksKey = "scrollUnlocks.expiry"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Selection persistence

    static func loadSelection() -> FamilyActivitySelection? {
        guard let data = sharedDefaults?.data(forKey: selectionKey) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    static func saveSelection(_ selection: FamilyActivitySelection) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        sharedDefaults?.set(data, forKey: selectionKey)
    }

    static var hasSelection: Bool {
        guard let selection = loadSelection() else { return false }
        return !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    // MARK: - Unlock state (written by ScrollUnlockService in the app)

    static func hasActiveUnlock(now: Date = Date()) -> Bool {
        latestUnlockExpiry(now: now) != nil
    }

    static func latestUnlockExpiry(now: Date = Date()) -> Date? {
        guard let raw = sharedDefaults?.dictionary(forKey: unlocksKey) as? [String: TimeInterval] else {
            return nil
        }
        return raw.values
            .map { Date(timeIntervalSince1970: $0) }
            .filter { $0 > now }
            .max()
    }

    // MARK: - Shield application

    /// Shields everything in the saved selection. With no selection, shields
    /// are cleared instead: RepScroll never blocks what the user did not pick.
    static func applyShields() {
        let store = ManagedSettingsStore()
        guard let selection = loadSelection(), hasSelection else {
            clearShields()
            return
        }
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    static func clearShields() {
        let store = ManagedSettingsStore()
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    /// Reconciles device shield state with the unlock state in shared
    /// storage: an active unlock window means no shields, otherwise the
    /// selection is shielded. Called by the app on launch/foreground and by
    /// the monitor extension when a DeviceActivity interval ends.
    static func refreshShields() {
        if hasActiveUnlock() {
            clearShields()
        } else {
            applyShields()
        }
    }
}

/// DeviceActivity names shared by the app (scheduling) and the monitor
/// extension (callbacks).
extension DeviceActivityName {
    /// The one-shot window scheduled while an unlock is active. When it
    /// ends, RepScrollMonitor re-applies shields via ShieldManager.
    static let unlockWindow = DeviceActivityName("unlockWindow")
}
