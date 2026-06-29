import AVFoundation
import Vision
import Combine
import UIKit
import os

/// On-device pose engine for push-ups, squats, and plank hold detection.
@MainActor
final class PoseDetectionService: NSObject, ObservableObject {
    enum Phase: String { case unknown, up, down, holding }

    @Published private(set) var repCount = 0
    @Published private(set) var phase: Phase = .unknown
    @Published private(set) var feedbackMessage = "Position yourself in frame"
    @Published private(set) var confidence: Float = 0
    @Published private(set) var isBodyDetected = false
    @Published private(set) var plankHoldSeconds = 0
    @Published var targetReps = 10
    @Published var exerciseMode: ExerciseType = .pushUp

    nonisolated(unsafe) private let sequenceHandler = VNSequenceRequestHandler()
    private var lastPhase: Phase = .unknown
    private var downConfirmed = false
    private var lastRepDate: Date?
    private var plankAccumulator: TimeInterval = 0
    private var lastPlankTick: Date?
    private var plankGoalNotified = false
    private let logger = Logger(subsystem: "com.repscroll.app", category: "PoseDetection")

    private var sensitivity: PoseSensitivity = AppConfig.defaultPoseSensitivity
    private var repCooldown: TimeInterval { AppConfig.repCooldownSeconds }
    private var downAngleThreshold: CGFloat { sensitivity.pushUpDownAngle }
    private var upAngleThreshold: CGFloat { sensitivity.pushUpUpAngle }
    private var squatDownKnee: CGFloat { sensitivity.squatDownKnee }
    private var squatUpKnee: CGFloat { sensitivity.squatUpKnee }
    private var plankTolerance: CGFloat { sensitivity.plankAlignmentTolerance }

    func applySensitivity(_ level: PoseSensitivity) {
        sensitivity = level
    }

    func reset() {
        repCount = 0
        phase = .unknown
        lastPhase = .unknown
        downConfirmed = false
        lastRepDate = nil
        plankAccumulator = 0
        lastPlankTick = nil
        plankHoldSeconds = 0
        plankGoalNotified = false
        confidence = 0
        isBodyDetected = false
        feedbackMessage = promptForMode()
    }

    private func promptForMode() -> String {
        switch exerciseMode {
        case .pushUp: "Get into push-up position"
        case .squat: "Step back — full body visible"
        case .plank: "Hold a straight plank in frame"
        }
    }

    nonisolated func process(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanBodyPoseRequest()
        do {
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: orientation)
            guard let observation = request.results?.first else {
                Task { @MainActor in
                    self.isBodyDetected = false
                    self.feedbackMessage = "Step back — body not visible"
                    self.tickPlank(active: false)
                }
                return
            }
            Task { @MainActor in
                switch self.exerciseMode {
                case .pushUp: self.analyzePushUp(observation: observation)
                case .squat: self.analyzeSquat(observation: observation)
                case .plank: self.analyzePlank(observation: observation)
                }
            }
        } catch {
            logger.error("Vision failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Push-ups

    private func analyzePushUp(observation: VNHumanBodyPoseObservation) {
        guard let points = try? observation.recognizedPoints(.all) else {
            isBodyDetected = false
            return
        }

        guard jointConfidence(points, [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow]) >= 4 else {
            isBodyDetected = false
            feedbackMessage = "Align shoulders and arms in view"
            return
        }

        isBodyDetected = true
        confidence = averageConfidence(points, [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist])

        let elbowAvg = (
            kneeAngle(points, .leftShoulder, .leftElbow, .leftWrist) +
            kneeAngle(points, .rightShoulder, .rightElbow, .rightWrist)
        ) / 2

        if elbowAvg < downAngleThreshold {
            phase = .down
            if lastPhase == .up || lastPhase == .unknown { downConfirmed = true }
            feedbackMessage = "Good depth — push up!"
        } else if elbowAvg > upAngleThreshold {
            phase = .up
            if downConfirmed && lastPhase == .down { registerRep() }
            else { feedbackMessage = "Lower chest toward floor" }
        } else {
            feedbackMessage = "Keep steady — full range of motion"
        }
        lastPhase = phase
    }

    // MARK: - Squats

    private func analyzeSquat(observation: VNHumanBodyPoseObservation) {
        guard let points = try? observation.recognizedPoints(.all) else {
            isBodyDetected = false
            return
        }

        let joints: [VNHumanBodyPoseObservation.JointName] = [
            .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle
        ]
        guard jointConfidence(points, joints) >= 4 else {
            isBodyDetected = false
            feedbackMessage = "Show hips, knees, and ankles"
            return
        }

        isBodyDetected = true
        confidence = averageConfidence(points, joints)

        let kneeAvg = (
            kneeAngle(points, .leftHip, .leftKnee, .leftAnkle) +
            kneeAngle(points, .rightHip, .rightKnee, .rightAnkle)
        ) / 2

        if kneeAvg < squatDownKnee {
            phase = .down
            if lastPhase == .up || lastPhase == .unknown { downConfirmed = true }
            feedbackMessage = "Deep squat — now stand!"
        } else if kneeAvg > squatUpKnee {
            phase = .up
            if downConfirmed && lastPhase == .down { registerRep() }
            else { feedbackMessage = "Squat until thighs parallel" }
        } else {
            feedbackMessage = "Control the descent"
        }
        lastPhase = phase
    }

    // MARK: - Plank

    private func analyzePlank(observation: VNHumanBodyPoseObservation) {
        guard let points = try? observation.recognizedPoints(.all) else {
            isBodyDetected = false
            return
        }

        let joints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftHip, .rightHip, .leftAnkle, .rightAnkle
        ]
        guard jointConfidence(points, joints) >= 4 else {
            isBodyDetected = false
            feedbackMessage = "Side view works best for plank"
            tickPlank(active: false)
            return
        }

        isBodyDetected = true
        confidence = averageConfidence(points, joints)

        let shoulderY = averageY(points, [.leftShoulder, .rightShoulder])
        let hipY = averageY(points, [.leftHip, .rightHip])
        let ankleY = averageY(points, [.leftAnkle, .rightAnkle])
        let deviation = abs((shoulderY + ankleY) / 2 - hipY)

        if deviation < plankTolerance {
            phase = .holding
            tickPlank(active: true)
            feedbackMessage = "Solid plank — \(plankHoldSeconds)s"
            if plankHoldSeconds >= targetReps {
                feedbackMessage = "Plank goal reached!"
                if !plankGoalNotified {
                    plankGoalNotified = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        } else {
            phase = .unknown
            tickPlank(active: false)
            feedbackMessage = hipY > shoulderY + 0.05 ? "Lift hips — straight line" : "Engage core — don't sag"
        }
    }

    private func tickPlank(active: Bool) {
        let now = Date()
        if active {
            if let last = lastPlankTick {
                plankAccumulator += now.timeIntervalSince(last)
                if plankAccumulator >= 1 {
                    let added = Int(plankAccumulator)
                    plankHoldSeconds += added
                    plankAccumulator -= TimeInterval(added)
                    if added > 0 { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
                }
            }
            lastPlankTick = now
        } else {
            lastPlankTick = nil
        }
    }

    // MARK: - Rep registration

    private func registerRep() {
        let now = Date()
        if let last = lastRepDate, now.timeIntervalSince(last) < repCooldown { return }

        downConfirmed = false
        lastRepDate = now
        repCount += 1
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if repCount >= targetReps {
            feedbackMessage = "Goal reached! Great work!"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            feedbackMessage = "Rep \(repCount) — keep going!"
        }
    }

    // MARK: - Geometry helpers

    private func jointConfidence(
        _ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        _ joints: [VNHumanBodyPoseObservation.JointName]
    ) -> Int {
        joints.filter { (points[$0]?.confidence ?? 0) > 0.3 }.count
    }

    private func averageConfidence(
        _ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        _ joints: [VNHumanBodyPoseObservation.JointName]
    ) -> Float {
        let vals = joints.compactMap { points[$0]?.confidence }
        guard !vals.isEmpty else { return 0 }
        return vals.reduce(0, +) / Float(vals.count)
    }

    private func kneeAngle(
        _ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        _ a: VNHumanBodyPoseObservation.JointName,
        _ b: VNHumanBodyPoseObservation.JointName,
        _ c: VNHumanBodyPoseObservation.JointName
    ) -> CGFloat {
        guard let pa = points[a], let pb = points[b], let pc = points[c] else { return 180 }
        return angle(
            a: CGPoint(x: pa.location.x, y: pa.location.y),
            b: CGPoint(x: pb.location.x, y: pb.location.y),
            c: CGPoint(x: pc.location.x, y: pc.location.y)
        )
    }

    private func averageY(
        _ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        _ joints: [VNHumanBodyPoseObservation.JointName]
    ) -> CGFloat {
        let vals = joints.compactMap { points[$0]?.location.y }
        guard !vals.isEmpty else { return 0.5 }
        return vals.reduce(0, +) / CGFloat(vals.count)
    }

    private func angle(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        let ab = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let cb = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = ab.dx * cb.dx + ab.dy * cb.dy
        let mag = hypot(ab.dx, ab.dy) * hypot(cb.dx, cb.dy)
        guard mag > 0 else { return 180 }
        return acos(max(-1, min(1, dot / mag))) * 180 / .pi
    }
}