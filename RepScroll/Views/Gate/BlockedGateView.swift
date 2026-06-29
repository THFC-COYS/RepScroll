import SwiftUI

struct BlockedGateView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var unlockService: ScrollUnlockService
    @Environment(\.dismiss) private var dismiss

    let blockedApp: BlockedApp
    @StateObject private var challengeVM: ChallengeViewModel
    @State private var phase: GatePhase = .blocked

    enum GatePhase { case blocked, exercising, unlocked, alreadyUnlocked }

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
            case .blocked: blockedScreen
            case .exercising: exerciseScreen
            case .unlocked: unlockedScreen
            case .alreadyUnlocked: alreadyUnlockedScreen
            }
        }
        .onAppear {
            unlockService.pruneExpired()
            if unlockService.isUnlocked(appId: blockedApp.id) {
                phase = .alreadyUnlocked
            }
            challengeVM.configure(exercise: .pushUp, repGoal: appState.dailyRepGoal)
        }
        .onDisappear { challengeVM.cleanup() }
    }

    private var blockedScreen: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: blockedApp.accentHex).opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: blockedApp.iconSystemName)
                    .font(.system(size: 52))
                    .foregroundStyle(Color(hex: blockedApp.accentHex))
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(RepScrollTheme.textPrimary)
                    .offset(x: 36, y: 36)
            }

            VStack(spacing: 12) {
                Text("\(blockedApp.name) is locked")
                    .font(.title.weight(.bold))
                Text("\(appState.dailyRepGoal) push-ups unlocks \(blockedApp.name) for \(unlockService.unlockDurationMinutes) minutes.")
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
                Label("Earn your scroll", systemImage: "figure.strengthtraining.traditional")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlowButtonStyle())
            .padding(.horizontal, 24)

            if !subscriptionService.isPremium {
                Button("Premium — unlimited daily gates") { appState.showPaywall = true }
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
            if challengeVM.cameraDenied {
                CameraPermissionView { Task { await challengeVM.retryCamera() } }
            } else {
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

                    if challengeVM.isGoalMet {
                        Button("Unlock \(blockedApp.name)") {
                            challengeVM.endSession(wasGateUnlock: true, blockedAppName: blockedApp.name)
                            let mins = subscriptionService.isPremium ? 30 : unlockService.unlockDurationMinutes
                            unlockService.grantUnlock(appId: blockedApp.id, minutes: mins)
                            phase = .unlocked
                        }
                        .buttonStyle(GlowButtonStyle(color: RepScrollTheme.success))
                        .padding(.bottom, 40)
                    }
                }
                .padding(.top, 60)
            }
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
            Text("\(subscriptionService.isPremium ? 30 : unlockService.unlockDurationMinutes) minutes of scroll time. You earned it.")
                .foregroundStyle(RepScrollTheme.textSecondary)
            Button("Open \(blockedApp.name)") {
                appState.completeGateChallenge()
                dismiss()
            }
            .buttonStyle(GlowButtonStyle(color: RepScrollTheme.success))
            Spacer()
        }
        .foregroundStyle(RepScrollTheme.textPrimary)
    }

    private var alreadyUnlockedScreen: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "clock.fill")
                .font(.system(size: 48))
                .foregroundStyle(RepScrollTheme.accentSecondary)
            Text("\(blockedApp.name) is still unlocked")
                .font(.title2.weight(.bold))
            Text("\(unlockService.formattedRemaining(for: blockedApp.id)) remaining")
                .font(.title3.monospacedDigit())
                .foregroundStyle(RepScrollTheme.accent)
            Button("Open \(blockedApp.name)") {
                appState.completeGateChallenge()
                dismiss()
            }
            .buttonStyle(GlowButtonStyle())
            Button("Do more reps anyway") { phase = .blocked }
                .foregroundStyle(RepScrollTheme.textSecondary)
            Spacer()
        }
        .foregroundStyle(RepScrollTheme.textPrimary)
    }
}