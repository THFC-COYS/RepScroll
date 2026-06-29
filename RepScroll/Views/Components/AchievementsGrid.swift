import SwiftUI

struct AchievementsGrid: View {
    let streak: Int
    let totalReps: Int

    private var gateUnlocks: Int { AchievementTracker.gateUnlockCount() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .foregroundStyle(RepScrollTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 10) {
                ForEach(Achievement.catalog) { achievement in
                    let unlocked = achievement.isUnlocked(streak: streak, totalReps: totalReps, gateUnlocks: gateUnlocks)
                    VStack(spacing: 6) {
                        Image(systemName: achievement.icon)
                            .font(.title3)
                            .foregroundStyle(unlocked ? RepScrollTheme.accentSecondary : RepScrollTheme.textSecondary.opacity(0.35))
                        Text(achievement.title)
                            .font(.caption2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(unlocked ? RepScrollTheme.textPrimary : RepScrollTheme.textSecondary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RepScrollTheme.surfaceElevated.opacity(unlocked ? 1 : 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(unlocked ? RepScrollTheme.accent.opacity(0.4) : .clear, lineWidth: 1)
                    )
                }
            }
        }
        .repScrollCard()
    }
}