// v1.1 — DeviceActivityMonitor extension (separate target, FamilyControls entitlement)
//
// import DeviceActivity
//
// final class RepScrollMonitor: DeviceActivityMonitor {
//     override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
//         let defaults = UserDefaults(suiteName: "group.com.repscroll.shared")
//         defaults?.set(event.rawValue, forKey: "pendingGateEvent")
//         // Main app reads flag and opens BlockedGateView via DeepLinkRouter
//     }
// }