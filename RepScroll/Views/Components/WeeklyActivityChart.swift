import SwiftUI

/// 7-day activity bars for the history screen.
struct WeeklyActivityChart: View {
    let dailyReps: [Date: Int]

    private var lastSevenDays: [(day: String, reps: Int, isToday: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let label = offset == 0 ? "Today" : date.formatted(.dateTime.weekday(.abbreviated))
            let reps = dailyReps[date] ?? 0
            return (label, reps, offset == 0)
        }
    }

    private var maxReps: Int {
        max(lastSevenDays.map(\.reps).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 days")
                .font(.headline)
                .foregroundStyle(RepScrollTheme.textPrimary)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(lastSevenDays.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                item.isToday
                                    ? RepScrollTheme.heroGradient
                                    : LinearGradient(colors: [RepScrollTheme.surfaceElevated, RepScrollTheme.surface], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(height: max(8, CGFloat(item.reps) / CGFloat(maxReps) * 80))

                        Text(item.day)
                            .font(.caption2)
                            .foregroundStyle(item.isToday ? RepScrollTheme.accent : RepScrollTheme.textSecondary)

                        if item.reps > 0 {
                            Text("\(item.reps)")
                                .font(.caption2.weight(.bold).monospacedDigit())
                                .foregroundStyle(RepScrollTheme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120, alignment: .bottom)
        }
        .repScrollCard()
    }
}