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
            "Stand back from the camera. Squat until thighs are parallel, then stand. Vision counting coming soon — tap to count for now."
        case .plank:
            "Hold a straight plank. Timer tracks your hold. Keep shoulders, hips, and ankles aligned."
        }
    }

    var supportsVisionCounting: Bool {
        self == .pushUp
    }

    var defaultGoal: Int {
        switch self {
        case .pushUp: 10
        case .squat: 15
        case .plank: 60 // seconds
        }
    }
}