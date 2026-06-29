import SwiftUI

struct ChallengeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ChallengeViewModel

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ChallengeViewModel(
            context: ctx,
            exercise: .pushUp,
            repGoal: 10
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RepScrollTheme.background.ignoresSafeArea()

                if viewModel.isSessionActive {
                    if viewModel.cameraDenied {
                        CameraPermissionView { Task { await viewModel.retryCamera() } }
                    } else {
                        activeSession
                    }
                } else {
                    setupView
                }

                if viewModel.showCompletion { completionOverlay }
            }
            .navigationTitle("Challenge")
            .onAppear {
                viewModel.configure(exercise: appState.preferredExercise, repGoal: appState.dailyRepGoal)
                viewModel.poseDetection.applySensitivity(appState.poseSensitivity)
            }
            .onChange(of: appState.poseSensitivity) { _, level in
                viewModel.poseDetection.applySensitivity(level)
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

                Button { Task { await viewModel.startSession() } } label: {
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
                .foregroundStyle(RepScrollTheme.textPrimary)

            HStack(spacing: 10) {
                ForEach(ExerciseType.allCases) { type in
                    Button {
                        viewModel.configure(exercise: type, repGoal: type.defaultGoal)
                        appState.preferredExercise = type
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
                        .background(viewModel.exercise == type ? RepScrollTheme.accent.opacity(0.25) : RepScrollTheme.surfaceElevated)
                        .foregroundStyle(viewModel.exercise == type ? RepScrollTheme.accent : RepScrollTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(viewModel.exercise == type ? RepScrollTheme.accent : .clear, lineWidth: 1.5)
                        )
                    }
                }
            }
        }
        .repScrollCard()
    }

    private var goalStepper: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.exercise == .plank ? "Goal (seconds)" : "Goal (reps)")
                .font(.headline)
                .foregroundStyle(RepScrollTheme.textPrimary)
            Stepper("\(viewModel.repGoal)", value: $viewModel.repGoal, in: 5...60, step: viewModel.exercise == .plank ? 15 : 5)
                .foregroundStyle(RepScrollTheme.textPrimary)
                .onChange(of: viewModel.repGoal) { _, v in
                    appState.dailyRepGoal = v
                    viewModel.poseDetection.targetReps = v
                }
        }
        .repScrollCard()
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How it works", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(RepScrollTheme.accentSecondary)
            Text(viewModel.exercise.instruction)
                .font(.subheadline)
                .foregroundStyle(RepScrollTheme.textSecondary)
        }
        .repScrollCard()
    }

    private var activeSession: some View {
        ZStack {
            CameraPreviewView(session: viewModel.camera.session)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    viewModel.poseDetection.isBodyDetected ? RepScrollTheme.success : RepScrollTheme.accent,
                    lineWidth: 3
                )
                .padding(40)
                .allowsHitTesting(false)

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
                .foregroundStyle(RepScrollTheme.textSecondary)

            Text("\(viewModel.currentReps)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(RepScrollTheme.textPrimary)
                .contentTransition(.numericText())
                .animation(.spring, value: viewModel.currentReps)

            Text(viewModel.exercise == .plank ? "/ \(viewModel.repGoal)s hold" : "/ \(viewModel.repGoal) reps")
                .font(.title3)
                .foregroundStyle(RepScrollTheme.textSecondary)

            ProgressView(value: viewModel.progress)
                .tint(RepScrollTheme.accent)
                .padding(.horizontal, 40)

            Text(viewModel.poseDetection.feedbackMessage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RepScrollTheme.accentSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
        .padding(.top, 8)
    }

    private var sessionControls: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                viewModel.cleanup()
                viewModel.isSessionActive = false
            }
            .foregroundStyle(RepScrollTheme.textSecondary)

            Spacer()

            if viewModel.isGoalMet {
                Button("Finish") { viewModel.endSession() }
                    .buttonStyle(GlowButtonStyle(color: RepScrollTheme.success))
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
                    .foregroundStyle(RepScrollTheme.success)
                Text("Crushed it!")
                    .font(.largeTitle.weight(.bold))
                if let summary = viewModel.lastSummary {
                    Text(summary.headline)
                        .font(.title3)
                        .foregroundStyle(RepScrollTheme.textSecondary)
                }
                Button("Done") {
                    viewModel.showCompletion = false
                    viewModel.isSessionActive = false
                }
                .buttonStyle(GlowButtonStyle(color: RepScrollTheme.success))
            }
            .foregroundStyle(RepScrollTheme.textPrimary)
        }
    }
}