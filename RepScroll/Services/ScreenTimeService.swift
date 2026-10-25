import Foundation
import Combine
import FamilyControls
import os

/// App-side owner of Screen Time authorization and the user's protected-app
/// selection (v1.1).
///
/// Authorization lives in the system (AuthorizationCenter), and the
/// selection is persisted by ShieldManager into the App Group suite, so the
/// app and the extensions always act on the same state. When authorization
/// is approved, AppConfig.screenTimeIntegration resolves to .familyControls
/// and blocking is real. In every other state the app runs the v1.0
/// simulation: the gate flow still works end to end, it just does not
/// shield other apps.
@MainActor
final class ScreenTimeService: ObservableObject {
    static let shared = ScreenTimeService()

    @Published private(set) var authorizationStatus: AuthorizationStatus

    /// The user's protected apps/categories/domains. Persisted to the App
    /// Group on every change; changing it re-applies shields immediately
    /// (unless an unlock window is currently open).
    @Published var selection: FamilyActivitySelection {
        didSet {
            ShieldManager.saveSelection(selection)
            ScreenTimeBridge.refreshShields()
        }
    }

    private let logger = Logger(subsystem: "com.repscroll.app", category: "ScreenTime")

    init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        selection = ShieldManager.loadSelection() ?? FamilyActivitySelection()
    }

    var isApproved: Bool { authorizationStatus == .approved }
    var isDenied: Bool { authorizationStatus == .denied }
    var isNotDetermined: Bool { authorizationStatus == .notDetermined }

    /// True unless real blocking is active. Mirrors ScreenTimeBridge so
    /// views can observe it through this service's published state.
    var isSimulationMode: Bool { ScreenTimeBridge.isSimulation }

    var selectedCount: Int {
        selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    /// Presents the system Screen Time authorization prompt for this app
    /// (individual mode: the user protects their own device). On approval,
    /// shields go up right away for whatever selection already exists.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            logger.error("Screen Time authorization failed: \(error.localizedDescription, privacy: .public)")
        }
        refreshAuthorizationStatus()
        if isApproved {
            ScreenTimeBridge.refreshShields()
        }
        return isApproved
    }
}
