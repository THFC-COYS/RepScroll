import AppIntents

/// Siri + Shortcuts: "Start my RepScroll challenge"
struct StartChallengeIntent: AppIntent {
    static let title: LocalizedStringResource = "Start RepScroll Challenge"
    static let description = IntentDescription("Open RepScroll and start an exercise challenge.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: "shortcut.startChallenge")
        return .result()
    }
}

struct RepScrollShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartChallengeIntent(),
            phrases: [
                "Start my \(.applicationName) challenge",
                "Do reps in \(.applicationName)",
                "Open \(.applicationName) workout",
            ],
            shortTitle: "Start challenge",
            systemImageName: "figure.strengthtraining.traditional"
        )
    }
}