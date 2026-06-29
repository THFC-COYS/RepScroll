import CoreData
import Foundation
import os

/// Persists and queries workout sessions; computes streaks and aggregate stats.
@MainActor
final class WorkoutRepository: ObservableObject {
    private let context: NSManagedObjectContext
    private let logger = Logger(subsystem: "com.repscroll.app", category: "WorkoutRepository")

    @Published private(set) var stats = StreakStats(
        currentStreak: 0, longestStreak: 0, totalSessions: 0,
        totalReps: 0, todayReps: 0, weeklySessions: 0
    )
    @Published private(set) var recentSessions: [WorkoutSummary] = []
    @Published private(set) var dailyRepsLast7Days: [Date: Int] = [:]

    init(context: NSManagedObjectContext) {
        self.context = context
        refresh()
    }

    func refresh() {
        recentSessions = fetchRecent(limit: 50)
        stats = computeStats()
        dailyRepsLast7Days = computeDailyReps(days: 7)
        WidgetDataStore.update(streak: stats.currentStreak, todayReps: stats.todayReps)
    }

    func computeDailyReps(days: Int) -> [Date: Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [Date: Int] = [:]

        let request = WorkoutSessionEntity.fetchRequest()
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
        request.predicate = NSPredicate(format: "startedAt >= %@", start as NSDate)

        guard let sessions = try? context.fetch(request) else { return result }
        for session in sessions {
            guard let startedAt = session.startedAt else { continue }
            let day = calendar.startOfDay(for: startedAt)
            result[day, default: 0] += Int(session.repsCompleted)
        }
        return result
    }

    @discardableResult
    func saveSession(
        exercise: ExerciseType,
        reps: Int,
        duration: TimeInterval,
        wasGateUnlock: Bool = false,
        blockedAppName: String? = nil
    ) -> WorkoutSummary {
        let entity = WorkoutSessionEntity(context: context)
        entity.id = UUID()
        entity.exerciseType = exercise.rawValue
        entity.repsCompleted = Int32(reps)
        entity.durationSeconds = duration
        entity.startedAt = Date()
        entity.wasGateUnlock = wasGateUnlock
        entity.blockedAppName = blockedAppName

        PersistenceController.shared.save(context: context)
        refresh()

        if wasGateUnlock {
            AchievementTracker.recordGateUnlock()
        }

        let newAchievements = AchievementTracker.evaluate(streak: stats.currentStreak, totalReps: stats.totalReps)
        if let first = newAchievements.first {
            NotificationCenter.default.post(
                name: .repScrollAchievementUnlocked,
                object: nil,
                userInfo: ["achievementId": first.id]
            )
        }
        ReviewPromptService.considerPrompt(streak: stats.currentStreak, totalSessions: stats.totalSessions)

        return WorkoutSummary(
            id: entity.id ?? UUID(),
            exercise: exercise,
            repsCompleted: reps,
            durationSeconds: duration,
            startedAt: entity.startedAt ?? Date(),
            wasGateUnlock: wasGateUnlock,
            blockedAppName: blockedAppName
        )
    }

    private func fetchRecent(limit: Int) -> [WorkoutSummary] {
        let request = WorkoutSessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSessionEntity.startedAt, ascending: false)]
        request.fetchLimit = limit

        do {
            let results = try context.fetch(request)
            return results.compactMap { entity in
                guard let id = entity.id,
                      let typeRaw = entity.exerciseType,
                      let exercise = ExerciseType(rawValue: typeRaw),
                      let startedAt = entity.startedAt else { return nil }
                return WorkoutSummary(
                    id: id,
                    exercise: exercise,
                    repsCompleted: Int(entity.repsCompleted),
                    durationSeconds: entity.durationSeconds,
                    startedAt: startedAt,
                    wasGateUnlock: entity.wasGateUnlock,
                    blockedAppName: entity.blockedAppName
                )
            }
        } catch {
            logger.error("Fetch failed: \(error.localizedDescription)")
            return []
        }
    }

    private func computeStats() -> StreakStats {
        let request = WorkoutSessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSessionEntity.startedAt, ascending: false)]

        guard let sessions = try? context.fetch(request), !sessions.isEmpty else {
            return StreakStats(currentStreak: 0, longestStreak: 0, totalSessions: 0, totalReps: 0, todayReps: 0, weeklySessions: 0)
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

        var uniqueDays = Set<Date>()
        var totalReps = 0
        var todayReps = 0
        var weeklySessions = 0

        for session in sessions {
            guard let startedAt = session.startedAt else { continue }
            let day = calendar.startOfDay(for: startedAt)
            uniqueDays.insert(day)
            totalReps += Int(session.repsCompleted)
            if day == today { todayReps += Int(session.repsCompleted) }
            if startedAt >= weekAgo { weeklySessions += 1 }
        }

        let sortedDays = uniqueDays.sorted(by: >)
        let currentStreak = calculateCurrentStreak(from: sortedDays, calendar: calendar)
        let longestStreak = calculateLongestStreak(from: sortedDays.sorted(), calendar: calendar)

        return StreakStats(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalSessions: sessions.count,
            totalReps: totalReps,
            todayReps: todayReps,
            weeklySessions: weeklySessions
        )
    }

    private func calculateCurrentStreak(from sortedDays: [Date], calendar: Calendar) -> Int {
        guard let first = sortedDays.first else { return 0 }
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard first == today || first == yesterday else { return 0 }

        var streak = 0
        var expected = first
        for day in sortedDays {
            if day == expected {
                streak += 1
                expected = calendar.date(byAdding: .day, value: -1, to: expected)!
            } else if day < expected {
                break
            }
        }
        return streak
    }

    private func calculateLongestStreak(from sortedDays: [Date], calendar: Calendar) -> Int {
        guard !sortedDays.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for i in 1..<sortedDays.count {
            let prev = sortedDays[i - 1]
            let next = sortedDays[i]
            if let gap = calendar.dateComponents([.day], from: next, to: prev).day, gap == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }
}