import Foundation

/// App Group bridge for Widget extension streak data.
enum WidgetDataStore {
    static let appGroupID = "group.com.pushscroll.shared"
    static let streakKey = "widget.currentStreak"
    static let todayRepsKey = "widget.todayReps"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func update(streak: Int, todayReps: Int) {
        defaults?.set(streak, forKey: streakKey)
        defaults?.set(todayReps, forKey: todayRepsKey)
    }

    static func read() -> (streak: Int, todayReps: Int) {
        let streak = defaults?.integer(forKey: streakKey) ?? 0
        let reps = defaults?.integer(forKey: todayRepsKey) ?? 0
        return (streak, reps)
    }
}