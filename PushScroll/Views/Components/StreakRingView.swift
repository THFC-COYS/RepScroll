import SwiftUI

/// Animated circular streak indicator with motivational glow.
struct StreakRingView: View {
    let streak: Int
    let progress: Double
    var size: CGFloat = 160

    @State private var animateGlow = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(PushScrollTheme.surfaceElevated, lineWidth: 14)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    PushScrollTheme.heroGradient,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8), value: progress)

            Circle()
                .fill(PushScrollTheme.accent.opacity(animateGlow ? 0.15 : 0.05))
                .frame(width: size * 0.85, height: size * 0.85)
                .blur(radius: 12)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: animateGlow)

            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(PushScrollTheme.accent)
                Text("\(streak)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(PushScrollTheme.textPrimary)
                Text("day streak")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PushScrollTheme.textSecondary)
            }
        }
        .onAppear { animateGlow = true }
    }
}