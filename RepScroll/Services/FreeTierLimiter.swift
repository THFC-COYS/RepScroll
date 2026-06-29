import Foundation

/// Enforces free-tier gate limits. Premium bypasses.
@MainActor
enum FreeTierLimiter {
    private static let gateCountKey = "freeTier.gateCount"
    private static let gateDateKey = "freeTier.gateDate"

    static func gatesRemainingToday(isPremium: Bool) -> Int {
        if isPremium { return .max }
        resetIfNewDay()
        let used = UserDefaults.standard.integer(forKey: gateCountKey)
        return max(0, AppConfig.freeGateChallengesPerDay - used)
    }

    static func canStartGateChallenge(isPremium: Bool) -> Bool {
        gatesRemainingToday(isPremium: isPremium) > 0
    }

    static func recordGateChallenge() {
        resetIfNewDay()
        let used = UserDefaults.standard.integer(forKey: gateCountKey)
        UserDefaults.standard.set(used + 1, forKey: gateCountKey)
    }

    private static func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let stored = UserDefaults.standard.object(forKey: gateDateKey) as? Date
        if stored != today {
            UserDefaults.standard.set(0, forKey: gateCountKey)
            UserDefaults.standard.set(today, forKey: gateDateKey)
        }
    }
}