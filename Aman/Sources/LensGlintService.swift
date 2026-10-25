import Foundation
import AVFoundation
import UIKit
import Combine

struct GlintCandidate: Identifiable, Equatable {
    var id: String
    var x: CGFloat   // 0...1
    var y: CGFloat
    var score: Double
    var frames: Int
}

/// Native reimplementation of pwnsy-style glint heuristics (threshold + small round persistent clusters).
@MainActor
final class LensGlintService: NSObject, ObservableObject {
    @Published var candidates: [GlintCandidate] = []
    @Published var running = false
    @Published var torchOn = false
    @Published var permissionDenied = false
    @Published var cameraAvailable = true
    @Published var marks: [LensMark] = []

    let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "aman.lens")
    private var tracker = GlintTracker()
    private var lastAlertId: String?
    nonisolated(unsafe) private var params = GlintDetector.Params()

    func configure(from t: CatalogThresholds) {
        params = GlintDetector.Params(lumaThreshold: t.lensLumaThreshold, minCluster: t.lensMinCluster,
                                      maxCluster: t.lensMaxCluster, maxSide: 14, minFill: t.lensMinFill)
    }

    func start() async {
        let ok = await AVCaptureDevice.requestAccess(for: .video)
        guard ok else { permissionDenied = true; return }
        permissionDenied = false
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { cameraAvailable = false; return }
        cameraAvailable = true

        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        if session.canAddInput(input) { session.addInput(input) }
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()

        queue.async { [weak self] in self?.session.startRunning() }
        running = true
        setTorch(true)
    }

    func stop() {
        setTorch(false)
        queue.async { [weak self] in self?.session.stopRunning() }
        running = false
        tracker.reset()
        candidates = []
    }

    func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        if on, device.isTorchModeSupported(.on) {
            try? device.setTorchModeOn(level: 1.0)
            torchOn = true
        } else {
            device.torchMode = .off
            torchOn = false
        }
        device.unlockForConfiguration()
    }

    func markTop() {
        if let c = candidates.first {
            marks.append(LensMark(note: L("لمعة عند \(Int(c.x*100))٪ × \(Int(c.y*100))٪",
                                           "Glint at \(Int(c.x*100))% × \(Int(c.y*100))%")))
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        } else {
            marks.append(LensMark(note: L("اشتباه يدوي", "Manual mark")))
        }
    }

    nonisolated private func process(buffer: CVPixelBuffer, params: GlintDetector.Params) {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let w = CVPixelBufferGetWidth(buffer), h = CVPixelBufferGetHeight(buffer)
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return }
        let stride = CVPixelBufferGetBytesPerRow(buffer)
        let scale = max(1, w / 160)
        let sw = w / scale, sh = h / scale
        var luma = [Double](repeating: 0, count: sw*sh)
        let ptr = base.assumingMemoryBound(to: UInt8.self)
        for y in 0..<sh {
            let row = y*scale*stride
            for x in 0..<sw {
                let o = row + x*scale*4
                let b = Double(ptr[o]), g = Double(ptr[o+1]), r = Double(ptr[o+2])
                luma[y*sw+x] = (0.2126*r + 0.7152*g + 0.0722*b) / 255.0
            }
        }
        let blobs = GlintDetector.detect(luma: luma, width: sw, height: sh, params: params)
        Task { @MainActor in self.apply(blobs) }
    }

    private func apply(_ blobs: [GlintBlob]) {
        tracker.update(blobs)
        candidates = tracker.tracks.prefix(8).map {
            GlintCandidate(id: String($0.id), x: $0.x, y: $0.y, score: $0.score, frames: $0.frames)
        }
        if let top = candidates.first, top.score >= 60, top.id != lastAlertId {
            lastAlertId = top.id
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }
}

extension LensGlintService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        process(buffer: buf, params: params)
    }
}
