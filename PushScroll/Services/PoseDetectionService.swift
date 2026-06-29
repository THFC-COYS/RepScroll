import AVFoundation
import Vision
import Combine
import os

/// Push-up rep counter using Vision human body pose detection.
/// Tracks elbow angles and vertical shoulder movement to detect down/up phases.
@MainActor
final class PoseDetectionService: NSObject, ObservableObject {
    enum Phase: String {
        case unknown
        case up
        case down
    }

    @Published private(set) var repCount = 0
    @Published private(set) var phase: Phase = .unknown
    @Published private(set) var feedbackMessage = "Position yourself in frame"
    @Published private(set) var confidence: Float = 0
    @Published private(set) var isBodyDetected = false
    @Published var targetReps = 10

    private let sequenceHandler = VNSequenceRequestHandler()
    private var lastPhase: Phase = .unknown
    private var downConfirmed = false
    private let logger = Logger(subsystem: "com.pushscroll.app", category: "PoseDetection")

    /// Minimum elbow flexion (degrees) to register "down" position.
    private let downAngleThreshold: CGFloat = 95
    /// Elbow extension threshold for "up" position.
    private let upAngleThreshold: CGFloat = 155

    func reset() {
        repCount = 0
        phase = .unknown
        lastPhase = .unknown
        downConfirmed = false
        feedbackMessage = "Get into push-up position"
        confidence = 0
        isBodyDetected = false
    }

    /// Process a camera frame — call from AVCaptureVideoDataOutput delegate.
    nonisolated func process(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanBodyPoseRequest()
        do {
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: orientation)
            guard let observation = request.results?.first else {
                Task { @MainActor in
                    self.isBodyDetected = false
                    self.feedbackMessage = "Step back — full body not visible"
                }
                return
            }
            Task { @MainActor in
                self.analyzePushUp(observation: observation)
            }
        } catch {
            logger.error("Vision request failed: \(error.localizedDescription)")
        }
    }

    private func analyzePushUp(observation: VNHumanBodyPoseObservation) {
        guard let points = try? observation.recognizedPoints(.all) else {
            isBodyDetected = false
            return
        }

        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist
        ]

        let recognized = jointNames.compactMap { name -> (VNHumanBodyPoseObservation.JointName, VNRecognizedPoint)? in
            guard let point = points[name], point.confidence > 0.3 else { return nil }
            return (name, point)
        }

        guard recognized.count >= 4 else {
            isBodyDetected = false
            feedbackMessage = "Align shoulders and arms in view"
            return
        }

        isBodyDetected = true
        let avgConfidence = recognized.map(\.1.confidence).reduce(0, +) / Float(recognized.count)
        confidence = avgConfidence

        let leftAngle = elbowAngle(points: points, shoulder: .leftShoulder, elbow: .leftElbow, wrist: .leftWrist)
        let rightAngle = elbowAngle(points: points, shoulder: .rightShoulder, elbow: .rightElbow, wrist: .rightWrist)
        let elbowAngleAvg = (leftAngle + rightAngle) / 2

        let shoulderY = averageY(points: points, joints: [.leftShoulder, .rightShoulder])

        if elbowAngleAvg < downAngleThreshold {
            phase = .down
            if lastPhase == .up || lastPhase == .unknown {
                downConfirmed = true
            }
            feedbackMessage = "Good depth — now push up!"
        } else if elbowAngleAvg > upAngleThreshold {
            phase = .up
            if downConfirmed && lastPhase == .down {
                repCount += 1
                downConfirmed = false
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if repCount >= targetReps {
                    feedbackMessage = "Goal reached! Great work!"
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    feedbackMessage = "Rep \(repCount) — keep going!"
                }
            } else {
                feedbackMessage = "Lower down — chest toward floor"
            }
        } else {
            feedbackMessage = shoulderY > 0.55 ? "Lower your chest" : "Push through your palms"
        }

        lastPhase = phase
    }

    private func elbowAngle(
        points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        shoulder: VNHumanBodyPoseObservation.JointName,
        elbow: VNHumanBodyPoseObservation.JointName,
        wrist: VNHumanBodyPoseObservation.JointName
    ) -> CGFloat {
        guard let s = points[shoulder], let e = points[elbow], let w = points[wrist] else { return 180 }
        return angle(
            a: CGPoint(x: s.location.x, y: s.location.y),
            b: CGPoint(x: e.location.x, y: e.location.y),
            c: CGPoint(x: w.location.x, y: w.location.y)
        )
    }

    private func angle(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        let ab = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let cb = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = ab.dx * cb.dx + ab.dy * cb.dy
        let mag = hypot(ab.dx, ab.dy) * hypot(cb.dx, cb.dy)
        guard mag > 0 else { return 180 }
        let cosAngle = max(-1, min(1, dot / mag))
        return acos(cosAngle) * 180 / .pi
    }

    private func averageY(
        points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        joints: [VNHumanBodyPoseObservation.JointName]
    ) -> CGFloat {
        let values = joints.compactMap { points[$0]?.location.y }
        guard !values.isEmpty else { return 0.5 }
        return values.reduce(0, +) / CGFloat(values.count)
    }
}