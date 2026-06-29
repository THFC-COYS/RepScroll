import Foundation

/// Lightweight DTO for UI layers — decoupled from Core Data entities.
struct WorkoutSummary: Identifiable, Hashable {
    let id: UUID
    let exercise: ExerciseType
    let repsCompleted: Int
    let durationSeconds: Double
    let startedAt: Date
    let wasGateUnlock: Bool
    let blockedAppName: String?

    var formattedDate: String {
        startedAt.formatted(date: .abbreviated, time: .shortened)
    }

    var headline: String {
        if exercise == .plank {
            return "\(Int(durationSeconds))s plank"
        }
        return "\(repsCompleted) \(exercise.displayName.lowercased())"
    }
}

struct StreakStats: Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let totalSessions: Int
    let totalReps: Int
    let todayReps: Int
    let weeklySessions: Int
}