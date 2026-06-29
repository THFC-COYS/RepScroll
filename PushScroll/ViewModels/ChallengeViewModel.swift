import SwiftUI
import CoreData
import Combine

@MainActor
final class ChallengeViewModel: ObservableObject {
    @Published var exercise: ExerciseType
    @Published var repGoal: Int
    @Published var manualRepCount = 0
    @Published var plankSeconds = 0
    @Published var isSessionActive = false
    @Published var sessionStart: Date?
    @Published var showCompletion = false
    @Published var lastSummary: WorkoutSummary?

    let poseDetection = PoseDetectionService()
    let camera = CameraService()
    private let repository: WorkoutRepository
    private var plankTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var currentReps: Int {
        exercise == .pushUp ? poseDetection.repCount : manualRepCount
    }

    var progress: Double {
        guard repGoal > 0 else { return 0 }
        if exercise == .plank {
            return min(1, Double(plankSeconds) / Double(repGoal))
        }
        return min(1, Double(currentReps) / Double(repGoal))
    }

    var isGoalMet: Bool {
        if exercise == .plank { return plankSeconds >= repGoal }
        return currentReps >= repGoal
    }

    init(context: NSManagedObjectContext, exercise: ExerciseType, repGoal: Int) {
        self.exercise = exercise
        self.repGoal = repGoal
        self.repository = WorkoutRepository(context: context)
        poseDetection.targetReps = repGoal

        camera.onFrame = { [weak poseDetection] buffer, orientation in
            poseDetection?.process(sampleBuffer: buffer, orientation: orientation)
        }
    }

    func startSession() async {
        manualRepCount = 0
        plankSeconds = 0
        poseDetection.reset()
        poseDetection.targetReps = repGoal
        sessionStart = Date()
        isSessionActive = true
        showCompletion = false

        if exercise.supportsVisionCounting {
            if camera.authorizationStatus != .authorized {
                let granted = await camera.requestPermission()
                guard granted else { return }
            }
            camera.configure()
            camera.start()
        } else if exercise == .plank {
            startPlankTimer()
        }
    }

    func endSession(wasGateUnlock: Bool = false, blockedAppName: String? = nil) {
        camera.stop()
        plankTimer?.invalidate()
        plankTimer = nil
        isSessionActive = false

        let duration = sessionStart.map { Date().timeIntervalSince($0) } ?? 0
        let reps = exercise == .plank ? plankSeconds : currentReps

        guard reps > 0 || duration > 5 else { return }

        lastSummary = repository.saveSession(
            exercise: exercise,
            reps: reps,
            duration: duration,
            wasGateUnlock: wasGateUnlock,
            blockedAppName: blockedAppName
        )
        showCompletion = true
    }

    func incrementManualRep() {
        manualRepCount += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func startPlankTimer() {
        plankTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.plankSeconds += 1
                if self.plankSeconds >= self.repGoal {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    func cleanup() {
        camera.stop()
        plankTimer?.invalidate()
    }
}