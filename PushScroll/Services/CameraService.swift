import AVFoundation
import Combine
import os

/// Manages AVCaptureSession lifecycle, permissions, and frame delivery to pose detection.
final class CameraService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.pushscroll.camera.session")
    private let logger = Logger(subsystem: "com.pushscroll.app", category: "Camera")

    var onFrame: ((CMSampleBuffer, CGImagePropertyOrientation) -> Void)?

    override init() {
        super.init()
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
        return granted
    }

    func configure() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            defer { self.session.commitConfiguration() }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Front camera unavailable on this device."
                }
                return
            }

            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.addInput(input)

            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.pushscroll.camera.frames"))

            if self.session.canAddOutput(self.videoOutput) {
                self.session.outputs.forEach { self.session.removeOutput($0) }
                self.session.addOutput(self.videoOutput)
            }

            if let connection = self.videoOutput.connection(with: .video) {
                connection.videoRotationAngle = 90
                connection.isVideoMirrored = true
            }
        }
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onFrame?(sampleBuffer, .leftMirrored)
    }
}