import Foundation

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let requiredStreak: Int

    static let catalog: [Achievement] = [
        Achievement(id: "streak_3", title: "Warming up", subtitle: "3-day streak", icon: "flame", requiredStreak: 3),
        Achievement(id: "streak_7", title: "On fire", subtitle: "7-day streak", icon: "flame.fill", requiredStreak: 7),
        Achievement(id: "streak_14", title: "Unstoppable", subtitle: "14-day streak", icon: "bolt.fill", requiredStreak: 14),
        Achievement(id: "streak_30", title: "Legend", subtitle: "30-day streak", icon: "crown.fill", requiredStreak: 30),
        Achievement(id: "reps_100", title: "Century", subtitle: "100 total reps", icon: "100.circle.fill", requiredStreak: 0),
        Achievement(id: "reps_500", title: "Machine", subtitle: "500 total reps", icon: "figure.strengthtraining.traditional", requiredStreak: 0),
        Achievement(id: "gates_10", title: "Gate keeper", subtitle: "10 app unlocks", icon: "lock.open.fill", requiredStreak: 0),
    ]

    func isUnlocked(streak: Int, totalReps: Int, gateUnlocks: Int) -> Bool {
        switch id {
        case "streak_3": return streak >= 3
        case "streak_7": return streak >= 7
        case "streak_14": return streak >= 14
        case "streak_30": return streak >= 30
        case "reps_100": return totalReps >= 100
        case "reps_500": return totalReps >= 500
        case "gates_10": return gateUnlocks >= 10
        default: return false
        }
    }
}

@MainActor
enum AchievementTracker {
    private static let unlockedKey = "achievements.unlocked"

    static func unlockedIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: unlockedKey) ?? [])
    }

    static func gateUnlockCount() -> Int {
        UserDefaults.standard.integer(forKey: "achievements.gateUnlocks")
    }

    static func recordGateUnlock() {
        let n = gateUnlockCount() + 1
        UserDefaults.standard.set(n, forKey: "achievements.gateUnlocks")
    }

    /// Returns newly unlocked achievements since last check.
    static func evaluate(streak: Int, totalReps: Int) -> [Achievement] {
        let gates = gateUnlockCount()
        var stored = unlockedIDs()
        var newly: [Achievement] = []

        for achievement in Achievement.catalog where achievement.isUnlocked(streak: streak, totalReps: totalReps, gateUnlocks: gates) {
            if !stored.contains(achievement.id) {
                stored.insert(achievement.id)
                newly.append(achievement)
            }
        }

        if !newly.isEmpty {
            UserDefaults.standard.set(Array(stored), forKey: unlockedKey)
        }
        return newly
    }
}