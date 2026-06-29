import Foundation

/// Handles repscroll:// URLs and notification deep links.
enum DeepLinkRouter {
    enum Destination: Equatable {
        case home
        case challenge
        case history
        case settings
        case paywall
        case gate(appId: String)
    }

    static func parse(url: URL) -> Destination? {
        guard url.scheme?.lowercased() == "repscroll" else { return nil }
        let host = url.host?.lowercased() ?? ""
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()

        switch host {
        case "challenge", "workout":
            return .challenge
        case "history", "stats":
            return .history
        case "settings":
            return .settings
        case "premium", "paywall":
            return .paywall
        case "gate", "unlock":
            let appId = path.isEmpty ? (URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "app" })?.value) : path
            if let appId { return .gate(appId: appId) }
            return nil
        case "home", "":
            return .home
        default:
            return .home
        }
    }

    @MainActor
    static func route(_ destination: Destination, appState: AppState, blockedApps: BlockedAppsService) {
        switch destination {
        case .home:
            appState.selectedTab = .home
        case .challenge:
            appState.selectedTab = .challenge
        case .history:
            appState.selectedTab = .history
        case .settings:
            appState.selectedTab = .settings
        case .paywall:
            appState.showPaywall = true
        case .gate(let appId):
            if let app = blockedApps.allApps.first(where: { $0.id == appId }) {
                appState.launchBlockedApp(app)
            }
        }
    }
}