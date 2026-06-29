import SwiftUI
import CoreData
import AVFoundation

@MainActor
final class ChallengeViewModel: ObservableObject {
    @Published var exercise: ExerciseType
    @Published var repGoal: Int
    @Published var isSessionActive = false
    @Published var sessionStart: Date?
    @Published var showCompletion = false
    @Published var lastSummary: WorkoutSummary?
    @Published var cameraDenied = false
    @Published var sessionError: String?

    let poseDetection = PoseDetectionService()
    let camera = CameraService()
    private let repository: WorkoutRepository

    var currentReps: Int {
        exercise == .plank ? poseDetection.plankHoldSeconds : poseDetection.repCount
    }

    var progress: Double {
        guard repGoal > 0 else { return 0 }
        return min(1, Double(currentReps) / Double(repGoal))
    }

    var isGoalMet: Bool { currentReps >= repGoal }

    init(context: NSManagedObjectContext, exercise: ExerciseType, repGoal: Int) {
        self.exercise = exercise
        self.repGoal = repGoal
        self.repository = WorkoutRepository(context: context)
        poseDetection.targetReps = repGoal
        poseDetection.exerciseMode = exercise

        camera.onFrame = { [weak poseDetection] buffer, orientation in
            poseDetection?.process(sampleBuffer: buffer, orientation: orientation)
        }
    }

    func configure(exercise: ExerciseType, repGoal: Int) {
        self.exercise = exercise
        self.repGoal = repGoal
        poseDetection.exerciseMode = exercise
        poseDetection.targetReps = repGoal
    }

    func startSession() async {
        cameraDenied = false
        sessionError = nil
        poseDetection.reset()
        poseDetection.exerciseMode = exercise
        poseDetection.targetReps = repGoal
        sessionStart = Date()
        showCompletion = false

        if exercise.supportsVisionCounting {
            if camera.authorizationStatus == .denied || camera.authorizationStatus == .restricted {
                cameraDenied = true
                isSessionActive = true
                return
            }
            if camera.authorizationStatus != .authorized {
                let granted = await camera.requestPermission()
                guard granted else {
                    cameraDenied = true
                    isSessionActive = true
                    return
                }
            }
            camera.configure()
            camera.start()
        }

        isSessionActive = true
    }

    func retryCamera() async {
        cameraDenied = false
        await startSession()
    }

    func endSession(wasGateUnlock: Bool = false, blockedAppName: String? = nil) {
        camera.stop()
        isSessionActive = false

        let duration = sessionStart.map { Date().timeIntervalSince($0) } ?? 0
        let reps = currentReps

        guard reps > 0 || duration > 5 else { return }

        lastSummary = repository.saveSession(
            exercise: exercise,
            reps: reps,
            duration: duration,
            wasGateUnlock: wasGateUnlock,
            blockedAppName: blockedAppName
        )
        showCompletion = true
        NotificationCenter.default.post(name: .repScrollSessionCompleted, object: nil)
    }

    func cleanup() {
        camera.stop()
    }
}