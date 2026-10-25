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
    @Published var marks: [LensMark] = []

    let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "aman.lens")
    private var tracks: [String: (x: CGFloat, y: CGFloat, frames: Int, miss: Int, score: Double)] = [:]
    private var frame = 0
    private var lumaThreshold: Double = 0.96
    private var minCluster = 2
    private var maxCluster = 80
    private var minFill = 0.45

    func configure(from t: CatalogThresholds) {
        lumaThreshold = t.lensLumaThreshold
        minCluster = t.lensMinCluster
        maxCluster = t.lensMaxCluster
        minFill = t.lensMinFill
    }

    func start() async {
        let ok = await AVCaptureDevice.requestAccess(for: .video)
        guard ok else { permissionDenied = true; return }
        permissionDenied = false
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

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
        tracks.removeAll()
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

    nonisolated private func process(buffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let w = CVPixelBufferGetWidth(buffer)
        let h = CVPixelBufferGetHeight(buffer)
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return }
        let stride = CVPixelBufferGetBytesPerRow(buffer)
        let scale = max(1, w / 160)
        let sw = w / scale, sh = h / scale

        // Collect bright pixels
        var bright: [(Int,Int)] = []
        bright.reserveCapacity(256)
        for y in 0..<sh {
            for x in 0..<sw {
                let px = base.advanced(by: y*scale*stride + x*scale*4)
                let b = Double(px.load(as: UInt8.self))
                let g = Double(px.advanced(by: 1).load(as: UInt8.self))
                let r = Double(px.advanced(by: 2).load(as: UInt8.self))
                let luma = (0.2126*r + 0.7152*g + 0.0722*b) / 255.0
                if luma >= 0.96 { bright.append((x,y)) }
            }
        }
        // Flood-fill clusters (simple)
        var visited = Set<Int>()
        func key(_ x:Int,_ y:Int)->Int { y*sw + x }
        var clusters: [(cx:CGFloat,cy:CGFloat,count:Int,w:Int,h:Int,fill:Double)] = []
        let brightSet = Set(bright.map { key($0.0,$0.1) })
        for (x,y) in bright {
            let k = key(x,y)
            if visited.contains(k) { continue }
            var stack = [(x,y)]
            visited.insert(k)
            var cells: [(Int,Int)] = []
            var minX=x,maxX=x,minY=y,maxY=y
            while let (cx,cy) = stack.popLast() {
                cells.append((cx,cy))
                minX=min(minX,cx); maxX=max(maxX,cx); minY=min(minY,cy); maxY=max(maxY,cy)
                for (dx,dy) in [(1,0),(-1,0),(0,1),(0,-1)] {
                    let nx=cx+dx, ny=cy+dy
                    let nk=key(nx,ny)
                    if nx>=0, ny>=0, nx<sw, ny<sh, brightSet.contains(nk), !visited.contains(nk) {
                        visited.insert(nk); stack.append((nx,ny))
                    }
                }
            }
            let bw = maxX-minX+1, bh = maxY-minY+1
            let box = bw*bh
            let fill = box > 0 ? Double(cells.count)/Double(box) : 0
            if cells.count >= 2 && cells.count <= 80 && max(bw,bh) <= 14 && fill >= 0.45 {
                let cx = CGFloat(minX+maxX)/2/CGFloat(sw)
                let cy = CGFloat(minY+maxY)/2/CGFloat(sh)
                clusters.append((cx,cy,cells.count,bw,bh,fill))
            }
        }

        Task { @MainActor in
            self.merge(clusters: clusters)
        }
    }

    private func merge(clusters: [(cx:CGFloat,cy:CGFloat,count:Int,w:Int,h:Int,fill:Double)]) {
        frame += 1
        var claimed = Set<String>()
        for c in clusters {
            // match existing
            var best: String?
            var bestD = CGFloat.greatestFiniteMagnitude
            for (id, t) in tracks {
                let d = hypot(t.x - c.cx, t.y - c.cy)
                if d < 0.045, d < bestD { bestD = d; best = id }
            }
            let roundness = c.fill
            let sizeScore = c.count <= 20 ? 10.0 : 5.0
            if let id = best, var t = tracks[id] {
                t.x = c.cx; t.y = c.cy; t.frames += 1; t.miss = 0
                t.score = min(100, Double(t.frames)/30.0*40 + roundness*15 + sizeScore)
                tracks[id] = t
                claimed.insert(id)
            } else {
                let id = UUID().uuidString
                tracks[id] = (c.cx, c.cy, 1, 0, roundness*15 + sizeScore)
                claimed.insert(id)
            }
        }
        for id in tracks.keys {
            if !claimed.contains(id) {
                tracks[id]?.miss += 1
            }
        }
        tracks = tracks.filter { $0.value.miss < 15 }
        candidates = tracks.map {
            GlintCandidate(id: $0.key, x: $0.value.x, y: $0.value.y, score: $0.value.score, frames: $0.value.frames)
        }.sorted { $0.score > $1.score }
    }
}

extension LensGlintService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        process(buffer: buf)
    }
}
