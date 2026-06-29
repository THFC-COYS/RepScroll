// v1.1 — Add as DeviceActivityMonitor extension target (not main app).
// import DeviceActivity
//
// final class RepScrollMonitor: DeviceActivityMonitor {
//     override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
//         let defaults = UserDefaults(suiteName: "group.com.repscroll.shared")
//         defaults?.set(event.rawValue, forKey: "pendingGateEvent")
//     }
// }