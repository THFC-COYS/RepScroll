import SwiftUI

/// Shows apps currently unlocked after completing challenges.
struct UnlockStatusCard: View {
    @ObservedObject var unlockService: ScrollUnlockService
    let blockedApps: [BlockedApp]

    var body: some View {
        let unlocked = blockedApps.filter { unlockService.isUnlocked(appId: $0.id) }

        if unlocked.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Label("Scroll time earned", systemImage: "lock.open.fill")
                    .font(.headline)
                    .foregroundStyle(RepScrollTheme.success)

                ForEach(unlocked) { app in
                    HStack {
                        Image(systemName: app.iconSystemName)
                            .foregroundStyle(Color(hex: app.accentHex))
                        Text(app.name)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(unlockService.formattedRemaining(for: app.id))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(RepScrollTheme.accentSecondary)
                    }
                    .foregroundStyle(RepScrollTheme.textPrimary)
                }
            }
            .repScrollCard()
        }
    }
}