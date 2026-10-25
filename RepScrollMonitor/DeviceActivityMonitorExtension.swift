import DeviceActivity
import Foundation

/// DeviceActivityMonitor extension (target: RepScrollMonitor).
///
/// The system wakes this extension when a monitored DeviceActivity
/// interval starts or ends, even while RepScroll itself is not running.
/// RepScroll schedules exactly one interval: the unlock window
/// (DeviceActivityName.unlockWindow), opened by ScreenTimeBridge in the
/// app each time the user earns scroll time.
///
/// Shield logic lives in ShieldManager (RepScroll/Shared), compiled into
/// this target as well, and reads the selection and unlock state from the
/// App Group suite.
final class RepScrollMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // An unlock window opened. The app already cleared the shields
        // when it granted the unlock, so there is nothing to do here.
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == .unlockWindow else { return }
        // The unlock window closed: put the shields back. ShieldManager
        // re-checks shared unlock state first, so a newer unlock granted
        // after this window was scheduled is never overridden.
        ShieldManager.refreshShields()
    }
}
