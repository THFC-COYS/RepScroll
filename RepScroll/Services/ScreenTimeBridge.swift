import Foundation

/// Screen Time integration bridge.
///
/// **Decision (v1.0):** `AppConfig.screenTimeIntegration = .simulation`
/// Gate UX is triggered manually from Home. TestFlight reviewers see full flow.
///
/// **v1.1:** Flip to `.familyControls` after Apple approves entitlement.
/// Requires: FamilyControls, ManagedSettings, DeviceActivityMonitor extension.
enum ScreenTimeBridge {
    static var mode: ScreenTimeMode { AppConfig.screenTimeIntegration }

    static var isSimulation: Bool { mode == .simulation }

    /// v1.1 — request authorization and apply shields to bundle IDs.
    static func enableShields(for bundleIDs: [String]) async throws {
        guard mode == .familyControls else { return }
        // FamilyControls.AuthorizationCenter.shared.requestAuthorization(...)
        // ManagedSettingsStore().shield.applications = ...
    }

    static func disableShields() {
        guard mode == .familyControls else { return }
    }
}