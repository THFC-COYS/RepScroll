import SwiftUI

struct BlockedGateView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var unlockService: ScrollUnlockService
    @Environment(\.dismiss) private var dismiss

    let blockedApp: BlockedApp
    @StateObject private var challengeVM: ChallengeViewModel
    @State private var phase: GatePhase = .blocked

    enum GatePhase {
        case blocked
        case exercising
        case unlocked
        case alreadyUnlocked
        case freeLimitReached
    }

    init(blockedApp: BlockedApp) {
        self.blockedApp = blockedApp
        _challengeVM = StateObject(wrappedValue: ChallengeViewModel(
            context: PersistenceController.shared.container.viewContext,
            exercise: AppConfig.gateExercise,
            repGoal: AppConfig.gateRepGoal
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
            case .freeLimitReached: freeLimitScreen
            }
        }
        .onAppear {
            unlockService.pruneExpired()
            challengeVM.configure(exercise: AppConfig.gateExercise, repGoal: AppConfig.gateRepGoal)
            challengeVM.poseDetection.applySensitivity(appState.poseSensitivity)

            if unlockService.isUnlocked(appId: blockedApp.id) {
                phase = .alreadyUnlocked
            } else if !FreeTierLimiter.canStartGateChallenge(isPremium: subscriptionService.isPremium) {
                phase = .freeLimitReached
            }
        }
        .onDisappear { challengeVM.cleanup() }
    }

    private var blockedScreen: some View {
        VStack(spacing: 28) {
            Spacer()
            gateIcon
            VStack(spacing: 12) {
                Text("\(blockedApp.name) is locked")
                    .font(.title.weight(.bold))
                Text("\(AppConfig.gateRepGoal) push-ups unlocks \(blockedApp.name) for \(unlockMinutes) minutes.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RepScrollTheme.textSecondary)
                if !subscriptionService.isPremium {
                    Text("\(FreeTierLimiter.gatesRemainingToday(isPremium: false)) free gate left today")
                        .font(.caption)
                        .foregroundStyle(RepScrollTheme.accentSecondary)
                }
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
                Button("Premium — unlimited gates") { appState.showPaywall = true }
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

    private var freeLimitScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "hourglass")
                .font(.system(size: 52))
                .foregroundStyle(RepScrollTheme.accentSecondary)
            Text("Free gate used today")
                .font(.title2.weight(.bold))
            Text("You get \(AppConfig.freeGateChallengesPerDay) app unlock challenge per day on the free plan. Come back tomorrow or go Premium.")
                .multilineTextAlignment(.center)
                .foregroundStyle(RepScrollTheme.textSecondary)
                .padding(.horizontal, 32)
            Button("Go Premium") { appState.showPaywall = true }
                .buttonStyle(GlowButtonStyle())
            Button("Close") {
                dismiss()
                appState.completeGateChallenge()
            }
            .foregroundStyle(RepScrollTheme.textSecondary)
            Spacer()
        }
        .foregroundStyle(RepScrollTheme.textPrimary)
    }

    private var exerciseScreen: some View {
        ZStack {
            if challengeVM.cameraDenied {
                CameraPermissionView { Task { await challengeVM.retryCamera() } }
            } else {
                CameraPreviewView(session: challengeVM.camera.session).ignoresSafeArea()
                VStack {
                    Text("\(challengeVM.poseDetection.repCount) / \(AppConfig.gateRepGoal)")
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
                            unlockService.grantUnlock(appId: blockedApp.id, minutes: unlockMinutes)
                            FreeTierLimiter.recordGateChallenge()
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
            Text("\(unlockMinutes) minutes of scroll time. You earned it.")
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
            Spacer()
        }
        .foregroundStyle(RepScrollTheme.textPrimary)
    }

    private var gateIcon: some View {
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
    }

    private var unlockMinutes: Int {
        subscriptionService.isPremium ? AppConfig.premiumUnlockMinutes : AppConfig.freeUnlockMinutes
    }
}