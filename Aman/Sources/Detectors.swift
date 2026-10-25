import Foundation
import CoreGraphics

// MARK: - Magnetometer spike detector (pure, testable)

struct MagSpikeDetector {
    struct Params: Equatable {
        var spikeDelta: Double = 18
        var hysteresis: Double = 8
        var warmupSamples: Int = 30      // 1.5 s @ 20 Hz
        var baselineN: Int = 40
        var needHits: Int = 3
    }
    enum Event: Equatable { case none, spikeStarted(magnitude: Double, delta: Double), spikeEnded }

    var params: Params
    private(set) var window: [Double] = []
    private(set) var baseline: Double = 0
    private(set) var delta: Double = 0
    private(set) var isSpiking = false
    private(set) var count = 0
    private var hits = 0

    init(params: Params = Params()) { self.params = params }

    var ready: Bool { count >= params.warmupSamples }

    static func magnitude(x: Double, y: Double, z: Double) -> Double { (x*x + y*y + z*z).squareRoot() }

    /// Feed one magnitude sample (µT). Baseline only absorbs non-spike samples so a
    /// sustained anomaly does not get "learned" away.
    mutating func feed(_ mag: Double) -> Event {
        count += 1
        if !ready {
            window.append(mag); if window.count > params.baselineN { window.removeFirst() }
            baseline = window.reduce(0, +) / Double(window.count)
            delta = 0
            return .none
        }
        delta = mag - baseline
        let ad = abs(delta)
        var ev: Event = .none
        if ad >= params.spikeDelta {
            hits += 1
            if hits >= params.needHits, !isSpiking { isSpiking = true; ev = .spikeStarted(magnitude: mag, delta: delta) }
        } else {
            hits = 0
            if isSpiking, ad < params.hysteresis { isSpiking = false; ev = .spikeEnded }
        }
        if !isSpiking && ad < params.spikeDelta {
            window.append(mag); if window.count > params.baselineN { window.removeFirst() }
            baseline = window.reduce(0, +) / Double(window.count)
        }
        return ev
    }

    mutating func reset() { self = MagSpikeDetector(params: params) }
}

// MARK: - Lens glint blob detector (pure, testable)

struct GlintBlob: Equatable {
    var cx: CGFloat   // 0...1
    var cy: CGFloat
    var pixels: Int
    var fill: Double
}

enum GlintDetector {
    struct Params: Equatable {
        var lumaThreshold: Double = 0.96
        var minCluster = 2
        var maxCluster = 80
        var maxSide = 14
        var minFill = 0.45
    }

    /// `luma` is row-major, values 0...1, size w*h.
    static func detect(luma: [Double], width w: Int, height h: Int, params p: Params) -> [GlintBlob] {
        guard w > 0, h > 0, luma.count >= w*h else { return [] }
        var bright = [Bool](repeating: false, count: w*h)
        for i in 0..<(w*h) where luma[i] >= p.lumaThreshold { bright[i] = true }
        var seen = [Bool](repeating: false, count: w*h)
        var out: [GlintBlob] = []
        for start in 0..<(w*h) where bright[start] && !seen[start] {
            var stack = [start]; seen[start] = true
            var n = 0, minX = w, maxX = 0, minY = h, maxY = 0
            while let k = stack.popLast() {
                n += 1
                let x = k % w, y = k / w
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
                if n > p.maxCluster * 4 { continue } // large region, keep draining but will be rejected
                for (dx, dy) in [(1,0),(-1,0),(0,1),(0,-1)] {
                    let nx = x+dx, ny = y+dy
                    guard nx >= 0, ny >= 0, nx < w, ny < h else { continue }
                    let nk = ny*w + nx
                    if bright[nk] && !seen[nk] { seen[nk] = true; stack.append(nk) }
                }
            }
            let bw = maxX-minX+1, bh = maxY-minY+1
            let fill = Double(n) / Double(bw*bh)
            if n >= p.minCluster, n <= p.maxCluster, max(bw, bh) <= p.maxSide, fill >= p.minFill {
                out.append(GlintBlob(cx: (CGFloat(minX+maxX)/2 + 0.5)/CGFloat(w),
                                     cy: (CGFloat(minY+maxY)/2 + 0.5)/CGFloat(h),
                                     pixels: n, fill: fill))
            }
        }
        return out
    }
}

/// Tracks blobs across frames; persistent, steady, small, round spots score higher (0...100).
struct GlintTracker {
    struct Track: Equatable { var id: Int; var x: CGFloat; var y: CGFloat; var frames: Int; var miss: Int; var drift: CGFloat; var score: Double }
    private(set) var tracks: [Track] = []
    private var nextId = 1
    var matchRadius: CGFloat = 0.045
    var maxMiss = 15

    mutating func update(_ blobs: [GlintBlob]) {
        var used = Set<Int>()
        for b in blobs {
            var best: Int?; var bestD = CGFloat.greatestFiniteMagnitude
            for (i, t) in tracks.enumerated() where !used.contains(i) {
                let d = hypot(t.x - b.cx, t.y - b.cy)
                if d < matchRadius && d < bestD { bestD = d; best = i }
            }
            if let i = best {
                tracks[i].drift = tracks[i].drift * 0.7 + bestD * 0.3
                tracks[i].x = b.cx; tracks[i].y = b.cy; tracks[i].frames += 1; tracks[i].miss = 0
                tracks[i].score = Self.score(frames: tracks[i].frames, drift: tracks[i].drift, fill: b.fill, pixels: b.pixels)
                used.insert(i)
            } else {
                tracks.append(Track(id: nextId, x: b.cx, y: b.cy, frames: 1, miss: 0, drift: 0,
                                    score: Self.score(frames: 1, drift: 0, fill: b.fill, pixels: b.pixels)))
                used.insert(tracks.count - 1); nextId += 1
            }
        }
        for i in tracks.indices where !used.contains(i) { tracks[i].miss += 1 }
        tracks.removeAll { $0.miss >= maxMiss }
        tracks.sort { $0.score > $1.score }
    }

    static func score(frames: Int, drift: CGFloat, fill: Double, pixels: Int) -> Double {
        let persistence = min(40, Double(frames) / 30 * 40)
        let steady: Double = drift < 0.004 ? 25 : drift < 0.01 ? 15 : drift < 0.02 ? 5 : 0
        let round: Double = fill >= 0.7 ? 15 : fill >= 0.55 ? 8 : 0
        let small: Double = pixels <= 20 ? 10 : 5
        return persistence + steady + round + small
    }

    mutating func reset() { tracks = []; nextId = 1 }
}

// MARK: - BLE presence tracking (hot/cold)

struct RSSISmoother {
    private(set) var value: Double?
    var alpha = 0.3
    mutating func feed(_ rssi: Int) -> Double {
        let v = value.map { $0 * (1 - alpha) + Double(rssi) * alpha } ?? Double(rssi)
        value = v; return v
    }
    static func proximity(_ rssi: Double) -> String {
        if rssi >= -50 { return L("قريب جدًا", "Very close") }
        if rssi >= -65 { return L("قريب", "Close") }
        if rssi >= -80 { return L("بنفس المكان تقريبًا", "Nearby") }
        return L("بعيد", "Far")
    }
}
