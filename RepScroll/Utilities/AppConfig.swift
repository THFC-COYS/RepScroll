import Foundation

// MARK: - Locked product decisions (MVP v1.0)
// These are the canonical specs — no user choice required at launch.

enum AppConfig {
    // ① Platform: iOS 18+, SwiftUI, Swift 6, dark-only, iPhone-only
    static let appName = "RepScroll"
    static let appVersion = "1.0.0"
    static let minimumIOSVersion = 18.0
    static let bundleIdentifier = "com.repscroll.app"
    static let appGroupIdentifier = "group.com.repscroll.shared"
    static let supportsIPad = false
    static let colorScheme: ColorSchemeDecision = .darkOnly

    // ② Vision: front camera, on-device pose, all three exercises
    static let cameraPosition: CameraPosition = .front
    static let repCooldownSeconds: TimeInterval = 0.55
    static let defaultPoseSensitivity: PoseSensitivity = .normal
    static let gateExercise: ExerciseType = .pushUp
    static let gateRepGoal = 10

    // ③ Core Data: local persistence, no CloudKit sync in v1
    static let persistenceMode: PersistenceMode = .localOnly
    static let maxHistorySessions = 200

    // ④ StoreKit: monthly + yearly, 7-day trial on monthly
    static let monthlyProductID = "com.repscroll.premium.monthly"
    static let yearlyProductID = "com.repscroll.premium.yearly"
    static let monthlyPriceDisplay = "$6.99/mo"
    static let yearlyPriceDisplay = "$49/yr"
    static let monthlyFreeTrialDays = 7
    static let premiumUnlockMinutes = 30
    static let freeUnlockMinutes = 15

    // ⑤ UI: energetic dark theme, motivational micro-copy
    static let defaultDailyRepGoal = 10
    static let defaultPlankGoalSeconds = 60
    static let defaultSquatGoal = 15

    // ⑥ Features: onboarding → home → challenge → gate → history
    static let defaultBlockedAppIDs: Set<String> = ["instagram", "tiktok", "x"]
    static let freeGateChallengesPerDay = 1
    static let screenTimeIntegration: ScreenTimeMode = .simulation

    // ⑦ Widget: streak + today reps, hourly refresh
    static let widgetRefreshIntervalHours = 1
    static let widgetShowsTodayReps = true

    // ⑧ Notifications: opt-in, 8 AM default, fixed copy
    static let defaultReminderHour = 8
    static let defaultReminderMinute = 0
    static let remindersOptIn = true
    static let reminderTitle = "RepScroll"
    static let reminderBody = "10 reps before the scroll. Your streak is waiting."

    // URLs — GitHub Pages (enable Pages on repo, source: /docs)
    static let privacyPolicyURL = "https://thfc-coys.github.io/RepScroll/privacy.html"
    static let termsURL = "https://thfc-coys.github.io/RepScroll/terms.html"
    static let supportURL = "https://github.com/THFC-COYS/RepScroll/issues"
    static let supportEmail = "support@repscroll.app"
}

enum ColorSchemeDecision { case darkOnly }
enum CameraPosition { case front, back }
enum PersistenceMode { case localOnly }
enum ScreenTimeMode { case simulation, familyControls }

/// Pose detection strictness — affects angle thresholds.
enum PoseSensitivity: String, CaseIterable, Identifiable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .normal: "Normal"
        case .hard: "Strict"
        }
    }

    var pushUpDownAngle: CGFloat {
        switch self {
        case .easy: 110
        case .normal: 95
        case .hard: 85
        }
    }

    var pushUpUpAngle: CGFloat {
        switch self {
        case .easy: 145
        case .normal: 155
        case .hard: 165
        }
    }

    var squatDownKnee: CGFloat {
        switch self {
        case .easy: 115
        case .normal: 105
        case .hard: 95
        }
    }

    var squatUpKnee: CGFloat {
        switch self {
        case .easy: 145
        case .normal: 155
        case .hard: 165
        }
    }

    var plankAlignmentTolerance: CGFloat {
        switch self {
        case .easy: 0.09
        case .normal: 0.06
        case .hard: 0.04
        }
    }
}