import Foundation

/// Supported exercise types. Push-ups have full Vision rep counting; others use timed/manual flows.
enum ExerciseType: String, CaseIterable, Codable, Identifiable {
    case pushUp
    case squat
    case plank

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pushUp: "Push-ups"
        case .squat: "Squats"
        case .plank: "Plank"
        }
    }

    var icon: String {
        switch self {
        case .pushUp: "figure.strengthtraining.traditional"
        case .squat: "figure.cross.training"
        case .plank: "figure.core.training"
        }
    }

    var instruction: String {
        switch self {
        case .pushUp:
            "Place your phone on the floor facing you. Keep your full body in frame. Lower until elbows bend past 90°, then push up."
        case .squat:
            "Stand 6 feet back, full body in frame. Squat until thighs are parallel — Vision counts each rep."
        case .plank:
            "Side plank or front plank — keep shoulders, hips, and ankles in a straight line. Timer runs while form is solid."
        }
    }

    var supportsVisionCounting: Bool {
        switch self {
        case .pushUp, .squat, .plank: true
        }
    }

    var defaultGoal: Int {
        switch self {
        case .pushUp: AppConfig.defaultDailyRepGoal
        case .squat: AppConfig.defaultSquatGoal
        case .plank: AppConfig.defaultPlankGoalSeconds
        }
    }
}