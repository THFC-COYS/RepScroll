import SwiftUI

/// Shown when camera access is denied — guides user to Settings.
struct CameraPermissionView: View {
    var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(RepScrollTheme.accent)

            Text("Camera access needed")
                .font(.title2.weight(.bold))
                .foregroundStyle(RepScrollTheme.textPrimary)

            Text("RepScroll counts reps on-device using your front camera. Nothing is recorded or uploaded.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(RepScrollTheme.textSecondary)
                .padding(.horizontal, 24)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(GlowButtonStyle())

            Button("Try again", action: onRetry)
                .font(.subheadline)
                .foregroundStyle(RepScrollTheme.textSecondary)
        }
        .padding()
    }
}