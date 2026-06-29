import SwiftUI

struct AchievementToast: View {
    let achievement: Achievement
    @Binding var isShowing: Bool

    var body: some View {
        VStack(spacing: 0) {
            if isShowing {
                HStack(spacing: 14) {
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundStyle(RepScrollTheme.accentSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Achievement unlocked")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RepScrollTheme.textSecondary)
                        Text(achievement.title)
                            .font(.headline)
                            .foregroundStyle(RepScrollTheme.textPrimary)
                    }
                    Spacer()
                    Button {
                        withAnimation { isShowing = false }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(RepScrollTheme.textSecondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(RepScrollTheme.surfaceElevated)
                        .shadow(color: RepScrollTheme.accent.opacity(0.3), radius: 16, y: 8)
                )
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.spring(response: 0.45), value: isShowing)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { isShowing = false }
            }
        }
    }
}