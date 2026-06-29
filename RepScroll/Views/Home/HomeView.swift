import SwiftUI
import CoreData

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var unlockService: ScrollUnlockService
    @StateObject private var viewModel: HomeViewModel
    @State private var tick = Date()

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    if AppConfig.screenTimeIntegration == .simulation { simulationBanner }
                    if dailyGoalMet { dailyGoalBanner }
                    streakCard
                    ShareStreakButton(streak: viewModel.repository.stats.currentStreak, todayReps: viewModel.repository.stats.todayReps)
                    UnlockStatusCard(unlockService: unlockService, blockedApps: viewModel.blockedAppsService.activeBlockedApps)
                    AchievementsGrid(streak: viewModel.repository.stats.currentStreak, totalReps: viewModel.repository.stats.totalReps)
                    quickStart
                    blockedAppsSection
                    premiumBanner
                }
                .padding()
            }
            .background(RepScrollTheme.background)
            .navigationTitle("RepScroll")
            .onAppear { viewModel.refresh() }
            .onReceive(NotificationCenter.default.publisher(for: .repScrollSessionCompleted)) { _ in
                viewModel.refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: .repScrollAchievementUnlocked)) { note in
                guard let id = note.userInfo?["achievementId"] as? String,
                      let achievement = Achievement.catalog.first(where: { $0.id == id }) else { return }
                appState.pendingAchievement = achievement
                appState.showAchievementToast = true
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                tick = Date()
                unlockService.pruneExpired()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RepScrollTheme.textPrimary)
                Text(motivationalLine)
                    .font(.subheadline)
                    .foregroundStyle(RepScrollTheme.textSecondary)
            }
            Spacer()
            if !subscriptionService.isPremium {
                Text("\(FreeTierLimiter.gatesRemainingToday(isPremium: false)) gate left today")
                    .font(.caption2)
                    .foregroundStyle(RepScrollTheme.textSecondary)
            } else {
                Label("Pro", systemImage: "crown.fill")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RepScrollTheme.accent.opacity(0.2))
                    .foregroundStyle(RepScrollTheme.accentSecondary)
                    .clipShape(Capsule())
            }
        }
    }

    private var streakCard: some View {
        VStack(spacing: 16) {
            StreakRingView(
                streak: viewModel.repository.stats.currentStreak,
                progress: min(1, Double(viewModel.repository.stats.todayReps) / Double(max(1, appState.dailyRepGoal)))
            )

            HStack(spacing: 24) {
                statPill(value: "\(viewModel.repository.stats.todayReps)", label: "Today")
                statPill(value: "\(viewModel.repository.stats.weeklySessions)", label: "This week")
                statPill(value: "\(viewModel.repository.stats.totalReps)", label: "All reps")
            }
        }
        .repScrollCard()
    }

    private var quickStart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick challenge")
                .font(.headline)
                .foregroundStyle(RepScrollTheme.textPrimary)

            Button { appState.selectedTab = .challenge } label: {
                HStack {
                    Image(systemName: appState.preferredExercise.icon)
                        .font(.title2)
                        .foregroundStyle(RepScrollTheme.accent)
                    VStack(alignment: .leading) {
                        Text(goalLabel)
                            .font(.headline)
                        Text("AI rep counting · on-device")
                            .font(.caption)
                            .foregroundStyle(RepScrollTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(RepScrollTheme.textPrimary)
                .padding()
                .background(RepScrollTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .repScrollCard()
    }

    private var blockedAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protected apps")
                .font(.headline)
                .foregroundStyle(RepScrollTheme.textPrimary)
            Text("Tap to simulate opening a blocked app — you'll need reps first.")
                .font(.caption)
                .foregroundStyle(RepScrollTheme.textSecondary)

            ForEach(viewModel.blockedAppsService.activeBlockedApps) { app in
                Button { appState.launchBlockedApp(app) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: app.iconSystemName)
                            .font(.title2)
                            .foregroundStyle(Color(hex: app.accentHex))
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .font(.subheadline.weight(.medium))
                            if unlockService.isUnlocked(appId: app.id) {
                                Text("Unlocked · \(unlockService.formattedRemaining(for: app.id))")
                                    .font(.caption)
                                    .foregroundStyle(RepScrollTheme.success)
                            } else {
                                Text("Locked — reps required")
                                    .font(.caption)
                                    .foregroundStyle(RepScrollTheme.textSecondary)
                            }
                        }
                        Spacer()
                        Image(systemName: unlockService.isUnlocked(appId: app.id) ? "lock.open.fill" : "lock.fill")
                            .font(.caption)
                            .foregroundStyle(unlockService.isUnlocked(appId: app.id) ? RepScrollTheme.success : RepScrollTheme.textSecondary)
                    }
                    .foregroundStyle(RepScrollTheme.textPrimary)
                    .padding(.vertical, 8)
                }
            }
        }
        .repScrollCard()
    }

    private var premiumBanner: some View {
        Group {
            if !subscriptionService.isPremium {
                Button { appState.showPaywall = true } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Go Premium")
                                .font(.headline)
                            Text("Unlimited gates · longer unlock windows")
                                .font(.caption)
                                .foregroundStyle(RepScrollTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "crown.fill")
                            .foregroundStyle(RepScrollTheme.accentSecondary)
                    }
                    .foregroundStyle(RepScrollTheme.textPrimary)
                }
                .repScrollCard()
            }
        }
    }

    private var goalLabel: String {
        if appState.preferredExercise == .plank {
            return "\(appState.dailyRepGoal)s \(appState.preferredExercise.displayName)"
        }
        return "\(appState.dailyRepGoal) \(appState.preferredExercise.displayName)"
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(RepScrollTheme.textPrimary)
            Text(label).font(.caption2).foregroundStyle(RepScrollTheme.textSecondary)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var simulationBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(RepScrollTheme.accentSecondary)
            Text("v1.0 preview — tap a protected app below to try the gate flow. System-level blocking comes in v1.1.")
                .font(.caption)
                .foregroundStyle(RepScrollTheme.textSecondary)
        }
        .foregroundStyle(RepScrollTheme.textPrimary)
        .repScrollCard()
    }

    private var dailyGoalMet: Bool {
        viewModel.repository.stats.todayReps >= appState.dailyRepGoal
    }

    private var dailyGoalBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(RepScrollTheme.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily goal crushed")
                    .font(.subheadline.weight(.semibold))
                Text("You hit \(appState.dailyRepGoal) reps today. Earn scroll time or stack more.")
                    .font(.caption)
                    .foregroundStyle(RepScrollTheme.textSecondary)
            }
            Spacer()
        }
        .foregroundStyle(RepScrollTheme.textPrimary)
        .repScrollCard()
    }

    private var motivationalLine: String {
        if viewModel.repository.stats.currentStreak >= 7 {
            return "🔥 \(viewModel.repository.stats.currentStreak)-day streak — don't break it."
        }
        if viewModel.repository.stats.todayReps >= appState.dailyRepGoal {
            return "Daily goal crushed. Earn more scroll time?"
        }
        return "Reps before scroll. Every time."
    }
}