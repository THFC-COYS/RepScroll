import WidgetKit
import SwiftUI

/// Home screen widget showing current streak and today's reps.
struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(RepScrollWidgetTheme.background, for: .widget)
        }
        .configurationDisplayName("RepScroll Streak")
        .description("Your current streak and reps today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let todayReps: Int
}

/// Reads streak data written by the main app via App Group UserDefaults.
private enum WidgetSharedData {
    static let appGroupID = "group.com.repscroll.shared"

    static func read() -> (streak: Int, todayReps: Int) {
        let defaults = UserDefaults(suiteName: appGroupID)
        return (defaults?.integer(forKey: "widget.currentStreak") ?? 0,
                defaults?.integer(forKey: "widget.todayReps") ?? 0)
    }
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: 7, todayReps: 10)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let data = WidgetSharedData.read()
        completion(StreakEntry(date: Date(), streak: data.streak, todayReps: data.todayReps))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let data = WidgetSharedData.read()
        let entry = StreakEntry(date: Date(), streak: data.streak, todayReps: data.todayReps)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct StreakWidgetView: View {
    let entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumLayout
        default:
            smallLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(RepScrollWidgetTheme.accent)
                Text("RepScroll")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RepScrollWidgetTheme.textSecondary)
            }
            Text("\(entry.streak)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(RepScrollWidgetTheme.textPrimary)
            Text("day streak")
                .font(.caption)
                .foregroundStyle(RepScrollWidgetTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumLayout: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.streak)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(RepScrollWidgetTheme.textPrimary)
                Text("day streak")
                    .font(.subheadline)
                    .foregroundStyle(RepScrollWidgetTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.todayReps)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(RepScrollWidgetTheme.accent)
                Text("reps today")
                    .font(.caption)
                    .foregroundStyle(RepScrollWidgetTheme.textSecondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

enum RepScrollWidgetTheme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.06)
    static let accent = Color(red: 1, green: 0.42, blue: 0.21)
    static let textPrimary = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.65)
}

@main
struct RepScrollWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
    }
}