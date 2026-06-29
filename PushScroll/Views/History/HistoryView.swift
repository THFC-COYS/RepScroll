import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var repository: WorkoutRepository

    init() {
        _repository = StateObject(wrappedValue: WorkoutRepository(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statsGrid
                    sessionList
                }
                .padding()
            }
            .background(PushScrollTheme.background)
            .navigationTitle("History")
            .onAppear { repository.refresh() }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            HistoryStatCard(title: "Current streak", value: "\(repository.stats.currentStreak)", icon: "flame.fill", color: PushScrollTheme.accent)
            HistoryStatCard(title: "Best streak", value: "\(repository.stats.longestStreak)", icon: "trophy.fill", color: PushScrollTheme.accentSecondary)
            HistoryStatCard(title: "Total sessions", value: "\(repository.stats.totalSessions)", icon: "figure.run", color: PushScrollTheme.success)
            HistoryStatCard(title: "Total reps", value: "\(repository.stats.totalReps)", icon: "number", color: .purple)
        }
    }

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent sessions")
                .font(.headline)
                .foregroundStyle(PushScrollTheme.textPrimary)

            if repository.recentSessions.isEmpty {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("Complete a challenge to see your history.")
                )
                .foregroundStyle(PushScrollTheme.textSecondary)
            } else {
                ForEach(repository.recentSessions) { session in
                    SessionRow(session: session)
                }
            }
        }
        .pushScrollCard()
    }
}

struct HistoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(PushScrollTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(PushScrollTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(PushScrollTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SessionRow: View {
    let session: WorkoutSummary

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: session.exercise.icon)
                .font(.title3)
                .foregroundStyle(PushScrollTheme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.headline)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PushScrollTheme.textPrimary)
                HStack(spacing: 6) {
                    Text(session.formattedDate)
                    if session.wasGateUnlock, let app = session.blockedAppName {
                        Text("· Unlocked \(app)")
                    }
                }
                .font(.caption)
                .foregroundStyle(PushScrollTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}