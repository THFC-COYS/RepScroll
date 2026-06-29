import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @StateObject private var viewModel: HomeViewModel

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    streakCard
                    quickStart
                    blockedAppsSection
                    premiumBanner
                }
                .padding()
            }
            .background(RepScrollTheme.background)
            .navigationTitle("RepScroll")
            .onAppear { viewModel.refresh() }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RepScrollTheme.textPrimary)
                Text("Earn your scroll time.")
                    .font(.subheadline)
                    .foregroundStyle(RepScrollTheme.textSecondary)
            }
            Spacer()
            if subscriptionService.isPremium {
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

            Button {
                appState.selectedTab = .challenge
            } label: {
                HStack {
                    Image(systemName: appState.preferredExercise.icon)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("\(appState.dailyRepGoal) \(appState.preferredExercise.displayName)")
                            .font(.headline)
                        Text("Tap to start camera")
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
            Text("Blocked apps (simulation)")
                .font(.headline)
                .foregroundStyle(RepScrollTheme.textPrimary)
            Text("Tap to preview the gate screen. Full Screen Time integration ships in v1.1.")
                .font(.caption)
                .foregroundStyle(RepScrollTheme.textSecondary)

            ForEach(viewModel.blockedAppsService.activeBlockedApps) { app in
                Button {
                    appState.simulateBlockedAppLaunch(app)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: app.iconSystemName)
                            .font(.title2)
                            .foregroundStyle(Color(hex: app.accentHex))
                            .frame(width: 36)
                        Text("Open \(app.name)")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(RepScrollTheme.textSecondary)
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
                Button {
                    appState.showPaywall = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Go Premium")
                                .font(.headline)
                            Text("Unlimited gates · All exercises · Widgets")
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

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(RepScrollTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(RepScrollTheme.textSecondary)
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
}