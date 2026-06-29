import SwiftUI
import AVFoundation

struct ChallengeView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ChallengeViewModel

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ChallengeViewModel(
            context: ctx,
            exercise: ExerciseType.pushUp,
            repGoal: 10
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PushScrollTheme.background.ignoresSafeArea()

                if viewModel.isSessionActive {
                    activeSession
                } else {
                    setupView
                }

                if viewModel.showCompletion {
                    completionOverlay
                }
            }
            .navigationTitle("Challenge")
            .onAppear {
                viewModel.exercise = appState.preferredExercise
                viewModel.repGoal = appState.dailyRepGoal
            }
            .onDisappear { viewModel.cleanup() }
        }
    }

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 20) {
                exercisePicker
                goalStepper
                instructionCard

                Button {
                    Task { await viewModel.startSession() }
                } label: {
                    Label("Start challenge", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlowButtonStyle())
            }
            .padding()
        }
    }

    private var exercisePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise")
                .font(.headline)
                .foregroundStyle(PushScrollTheme.textPrimary)

            HStack(spacing: 10) {
                ForEach(ExerciseType.allCases) { type in
                    Button {
                        viewModel.exercise = type
                        appState.preferredExercise = type
                        viewModel.repGoal = type.defaultGoal
                        appState.dailyRepGoal = type.defaultGoal
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.title3)
                            Text(type.displayName)
                                .font(.caption2.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(viewModel.exercise == type ? PushScrollTheme.accent.opacity(0.25) : PushScrollTheme.surfaceElevated)
                        .foregroundStyle(viewModel.exercise == type ? PushScrollTheme.accent : PushScrollTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(viewModel.exercise == type ? PushScrollTheme.accent : .clear, lineWidth: 1.5)
                        )
                    }
                }
            }
        }
        .pushScrollCard()
    }

    private var goalStepper: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.exercise == .plank ? "Goal (seconds)" : "Goal (reps)")
                .font(.headline)
                .foregroundStyle(PushScrollTheme.textPrimary)
            Stepper("\(viewModel.repGoal)", value: $viewModel.repGoal, in: 5...50, step: viewModel.exercise == .plank ? 15 : 5)
                .foregroundStyle(PushScrollTheme.textPrimary)
                .onChange(of: viewModel.repGoal) { _, v in appState.dailyRepGoal = v }
        }
        .pushScrollCard()
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How it works", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(PushScrollTheme.accentSecondary)
            Text(viewModel.exercise.instruction)
                .font(.subheadline)
                .foregroundStyle(PushScrollTheme.textSecondary)
        }
        .pushScrollCard()
    }

    private var activeSession: some View {
        ZStack {
            if viewModel.exercise.supportsVisionCounting {
                CameraPreviewView(session: viewModel.camera.session)
                    .ignoresSafeArea()

                // Pose overlay guides
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        viewModel.poseDetection.isBodyDetected ? PushScrollTheme.success : PushScrollTheme.accent,
                        lineWidth: 3
                    )
                    .padding(40)
                    .allowsHitTesting(false)
            } else {
                PushScrollTheme.surface.ignoresSafeArea()
                manualExerciseView
            }

            VStack {
                sessionHUD
                Spacer()
                sessionControls
            }
            .padding()
        }
    }

    private var sessionHUD: some View {
        VStack(spacing: 8) {
            Text(viewModel.exercise.displayName)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(PushScrollTheme.textSecondary)

            if viewModel.exercise == .plank {
                Text("\(viewModel.plankSeconds)s")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(PushScrollTheme.textPrimary)
            } else {
                Text("\(viewModel.currentReps)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(PushScrollTheme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring, value: viewModel.currentReps)
                Text("/ \(viewModel.repGoal) reps")
                    .font(.title3)
                    .foregroundStyle(PushScrollTheme.textSecondary)
            }

            ProgressView(value: viewModel.progress)
                .tint(PushScrollTheme.accent)
                .padding(.horizontal, 40)

            if viewModel.exercise.supportsVisionCounting {
                Text(viewModel.poseDetection.feedbackMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PushScrollTheme.accentSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 8)
    }

    private var manualExerciseView: some View {
        VStack(spacing: 24) {
            Image(systemName: viewModel.exercise.icon)
                .font(.system(size: 80))
                .foregroundStyle(PushScrollTheme.heroGradient)
            Text("\(viewModel.currentReps) / \(viewModel.repGoal)")
                .font(.largeTitle.weight(.bold))
            Button("Count rep") { viewModel.incrementManualRep() }
                .buttonStyle(GlowButtonStyle())
        }
    }

    private var sessionControls: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                viewModel.cleanup()
                viewModel.isSessionActive = false
            }
            .foregroundStyle(PushScrollTheme.textSecondary)

            Spacer()

            if viewModel.isGoalMet {
                Button("Finish") {
                    viewModel.endSession()
                }
                .buttonStyle(GlowButtonStyle(color: PushScrollTheme.success))
            }
        }
        .padding(.bottom, 20)
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            ConfettiView(isActive: viewModel.showCompletion)

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(PushScrollTheme.success)
                Text("Crushed it!")
                    .font(.largeTitle.weight(.bold))
                if let summary = viewModel.lastSummary {
                    Text(summary.headline)
                        .font(.title3)
                        .foregroundStyle(PushScrollTheme.textSecondary)
                }
                Button("Done") {
                    viewModel.showCompletion = false
                    viewModel.isSessionActive = false
                }
                .buttonStyle(GlowButtonStyle(color: PushScrollTheme.success))
            }
            .foregroundStyle(PushScrollTheme.textPrimary)
        }
    }
}