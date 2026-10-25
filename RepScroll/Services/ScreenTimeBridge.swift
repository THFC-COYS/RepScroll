import Foundation
import DeviceActivity
import os

/// Screen Time integration bridge (v1.1).
///
/// Mode is a runtime decision (see AppConfig.screenTimeIntegration):
/// .familyControls when the user has approved Screen Time authorization,
/// .simulation otherwise. In simulation every method here is a no-op and
/// the v1.0 gate UX runs untouched.
///
/// The heavy lifting lives in ShieldManager (RepScroll/Shared), which is
/// also compiled into the RepScrollMonitor extension: when an unlock
/// window's DeviceActivity interval ends, the extension re-applies shields
/// even if the app never runs again.
enum ScreenTimeBridge {
    private static let logger = Logger(subsystem: "com.repscroll.app", category: "ScreenTimeBridge")

    static var mode: ScreenTimeMode { AppConfig.screenTimeIntegration }

    static var isSimulation: Bool { mode == .simulation }

    /// Reconciles shields with the current unlock state: shields off while
    /// any unlock window is open, selection shielded otherwise. Safe to
    /// call on launch, on foreground, and whenever unlock state changes.
    static func refreshShields() {
        guard mode == .familyControls else { return }
        ShieldManager.refreshShields()
    }

    /// An unlock was granted (called from ScrollUnlockService.grantUnlock).
    /// Shields drop immediately, and a one-shot DeviceActivity window is
    /// scheduled so the monitor extension restores them at expiry.
    static func handleUnlockGranted(expiresAt: Date) {
        guard mode == .familyControls else { return }
        ShieldManager.clearShields()
        scheduleUnlockWindowEnd(at: expiresAt)
    }

    /// An unlock was revoked early. If other windows are still open, the
    /// monitor schedule is re-pointed at the latest remaining expiry;
    /// otherwise monitoring stops and shields go back up.
    static func handleUnlockRevoked() {
        guard mode == .familyControls else { return }
        if let latest = ShieldManager.latestUnlockExpiry() {
            ShieldManager.clearShields()
            scheduleUnlockWindowEnd(at: latest)
        } else {
            DeviceActivityCenter().stopMonitoring([.unlockWindow])
            refreshShields()
        }
    }

    private static func scheduleUnlockWindowEnd(at expiry: Date) {
        let now = Date()
        guard expiry > now else {
            refreshShields()
            return
        }
        let calendar = Calendar.current
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: calendar.dateComponents([.hour, .minute, .second], from: expiry),
            repeats: false
        )
        do {
            try DeviceActivityCenter().startMonitoring(.unlockWindow, during: schedule)
        } catch {
            // The app-side foreground reconciliation in RepScrollApp still
            // restores shields after expiry if scheduling fails.
            logger.error("Failed to schedule unlock window: \(error.localizedDescription, privacy: .public)")
        }
    }
}
