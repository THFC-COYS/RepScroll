import SwiftUI

/// Compact today progress for challenge tab header area.
struct DailyGoalRing: View {
    let todayReps: Int
    let goal: Int

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(todayReps) / Double(goal))
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(RepScrollTheme.surfaceElevated, lineWidth: 4)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(RepScrollTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(RepScrollTheme.textPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's goal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RepScrollTheme.textSecondary)
                Text("\(todayReps) / \(goal) reps")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RepScrollTheme.textPrimary)
            }
            Spacer()
        }
        .repScrollCard()
    }
}