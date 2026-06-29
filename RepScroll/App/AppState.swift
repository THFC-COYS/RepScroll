import SwiftUI
import Combine

/// Global navigation and onboarding state shared across the app.
@MainActor
final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("dailyRepGoal") var dailyRepGoal = AppConfig.defaultDailyRepGoal
    @AppStorage("preferredExercise") private var preferredExerciseRaw = AppConfig.gateExercise.rawValue
    @AppStorage("reminderHour") var reminderHour = AppConfig.defaultReminderHour
    @AppStorage("reminderMinute") var reminderMinute = AppConfig.defaultReminderMinute
    @AppStorage("poseSensitivity") var poseSensitivityRaw = AppConfig.defaultPoseSensitivity.rawValue

    var poseSensitivity: PoseSensitivity {
        get { PoseSensitivity(rawValue: poseSensitivityRaw) ?? AppConfig.defaultPoseSensitivity }
        set { poseSensitivityRaw = newValue.rawValue }
    }
    @AppStorage("remindersEnabled") var remindersEnabled = false

    @Published var selectedTab: AppTab = .home
    @Published var showPaywall = false
    @Published var showBlockedGate = false
    @Published var pendingBlockedApp: BlockedApp?

    var preferredExercise: ExerciseType {
        get { ExerciseType(rawValue: preferredExerciseRaw) ?? .pushUp }
        set { preferredExerciseRaw = newValue.rawValue }
    }

    func launchBlockedApp(_ app: BlockedApp) {
        pendingBlockedApp = app
        showBlockedGate = true
    }

    func completeGateChallenge() {
        showBlockedGate = false
        pendingBlockedApp = nil
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case challenge
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .challenge: "Challenge"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "flame.fill"
        case .challenge: "camera.fill"
        case .history: "chart.bar.fill"
        case .settings: "gearshape.fill"
        }
    }
}