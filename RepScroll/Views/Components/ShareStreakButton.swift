import SwiftUI

struct ShareStreakButton: View {
    let streak: Int
    let todayReps: Int

    var body: some View {
        if streak > 0 {
            ShareLink(
                item: "I'm on a \(streak)-day RepScroll streak — \(todayReps) reps today. Reps before scroll. 💪",
                subject: Text("My RepScroll streak"),
                message: Text("Join me on RepScroll")
            ) {
                Label("Share streak", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RepScrollTheme.accent)
            }
        }
    }
}