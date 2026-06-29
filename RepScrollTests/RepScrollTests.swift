import XCTest
@testable import RepScroll

@MainActor
final class FreeTierLimiterTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "freeTier.gateCount")
        UserDefaults.standard.removeObject(forKey: "freeTier.gateDate")
    }

    func testFreeUserGetsOneGatePerDay() {
        XCTAssertTrue(FreeTierLimiter.canStartGateChallenge(isPremium: false))
        FreeTierLimiter.recordGateChallenge()
        XCTAssertFalse(FreeTierLimiter.canStartGateChallenge(isPremium: false))
        XCTAssertEqual(FreeTierLimiter.gatesRemainingToday(isPremium: false), 0)
    }

    func testPremiumHasUnlimitedGates() {
        FreeTierLimiter.recordGateChallenge()
        FreeTierLimiter.recordGateChallenge()
        XCTAssertTrue(FreeTierLimiter.canStartGateChallenge(isPremium: true))
    }
}

@MainActor
final class DeepLinkRouterTests: XCTestCase {
    func testChallengeLink() {
        let url = URL(string: "repscroll://challenge")!
        XCTAssertEqual(DeepLinkRouter.parse(url: url), .challenge)
    }

    func testGateLink() {
        let url = URL(string: "repscroll://gate/instagram")!
        XCTAssertEqual(DeepLinkRouter.parse(url: url), .gate(appId: "instagram"))
    }
}

final class PoseSensitivityTests: XCTestCase {
    func testStrictIsHarderThanEasy() {
        XCTAssertLessThan(PoseSensitivity.hard.pushUpDownAngle, PoseSensitivity.easy.pushUpDownAngle)
        XCTAssertGreaterThan(PoseSensitivity.hard.pushUpUpAngle, PoseSensitivity.easy.pushUpUpAngle)
    }
}

@MainActor
final class AchievementTrackerTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "achievements.unlocked")
        UserDefaults.standard.removeObject(forKey: "achievements.gateUnlocks")
    }

    func testStreakAchievementUnlocksOnce() {
        let first = AchievementTracker.evaluate(streak: 3, totalReps: 0)
        XCTAssertEqual(first.map(\.id), ["streak_3"])
        let second = AchievementTracker.evaluate(streak: 3, totalReps: 0)
        XCTAssertTrue(second.isEmpty)
    }

    func testRepAchievement() {
        let unlocked = AchievementTracker.evaluate(streak: 0, totalReps: 100)
        XCTAssertEqual(unlocked.first?.id, "reps_100")
    }
}