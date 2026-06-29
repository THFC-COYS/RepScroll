import SwiftUI

/// Simulates the intercept screen when a blocked social app is opened.
struct BlockedGateView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let blockedApp: BlockedApp
    @StateObject private var challengeVM: ChallengeViewModel
    @State private var phase: GatePhase = .blocked

    enum GatePhase {
        case blocked
        case exercising
        case unlocked
    }

    init(blockedApp: BlockedApp) {
        self.blockedApp = blockedApp
        _challengeVM = StateObject(wrappedValue: ChallengeViewModel(
            context: PersistenceController.shared.container.viewContext,
            exercise: .pushUp,
            repGoal: 10
        ))
    }

    var body: some View {
        ZStack {
            RepScrollTheme.background.ignoresSafeArea()

            switch phase {
            case .blocked:
                blockedScreen
            case .exercising:
                exerciseScreen
            case .unlocked:
                unlockedScreen
            }
        }
        .onDisappear { challengeVM.cleanup() }
    }

    private var blockedScreen: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: blockedApp.iconSystemName)
                .font(.system(size: 64))
                .foregroundStyle(Color(hex: blockedApp.accentHex))

            VStack(spacing: 12) {
                Text("\(blockedApp.name) is locked")
                    .font(.title.weight(.bold))
                Text("Do \(appState.dailyRepGoal) push-ups to earn \(blockedApp.name) for 15 minutes.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RepScrollTheme.textSecondary)
            }
            .foregroundStyle(RepScrollTheme.textPrimary)
            .padding(.horizontal, 32)

            Button {
                phase = .exercising
                Task { await challengeVM.startSession() }
            } label: {
                Label("Start push-ups", systemImage: "figure.strengthtraining.traditional")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlowButtonStyle())
            .padding(.horizontal, 24)

            if !subscriptionService.isPremium {
                Button("Go Premium for unlimited gates") {
                    appState.showPaywall = true
                }
                .font(.subheadline)
                .foregroundStyle(RepScrollTheme.accentSecondary)
            }

            Button("Not now") {
                dismiss()
                appState.completeGateChallenge()
            }
            .foregroundStyle(RepScrollTheme.textSecondary)

            Spacer()
        }
    }

    private var exerciseScreen: some View {
        ZStack {
            CameraPreviewView(session: challengeVM.camera.session)
                .ignoresSafeArea()

            VStack {
                Text("\(challengeVM.poseDetection.repCount) / \(challengeVM.repGoal)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)

                Text(challengeVM.poseDetection.feedbackMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                Spacer()

                if challengeVM.poseDetection.repCount >= challengeVM.repGoal {
                    Button("Unlock \(blockedApp.name)") {
                        challengeVM.endSession(wasGateUnlock: true, blockedAppName: blockedApp.name)
                        phase = .unlocked
                    }
                    .buttonStyle(GlowButtonStyle(color: RepScrollTheme.success))
                    .padding(.bottom, 40)
                }
            }
            .padding(.top, 60)
        }
    }

    private var unlockedScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            ConfettiView(isActive: true)
            Image(systemName: "lock.open.fill")
                .font(.system(size: 56))
                .foregroundStyle(RepScrollTheme.success)
            Text("\(blockedApp.name) unlocked!")
                .font(.title.weight(.bold))
            Text("You earned 15 minutes. Use it wisely.")
                .foregroundStyle(RepScrollTheme.textSecondary)
            Button("Open \(blockedApp.name)") {
                BlockedAppsService().recordGateUnlock()
                appState.completeGateChallenge()
                dismiss()
            }
            .buttonStyle(GlowButtonStyle(color: RepScrollTheme.success))
            Spacer()
        }
        .foregroundStyle(RepScrollTheme.textPrimary)
    }
}