import Foundation
import CoreMotion
import Combine
import UIKit

struct MagSpike: Identifiable, Equatable, Codable {
    var id = UUID()
    var magnitude: Double
    var delta: Double
    var date: Date
    var pinned = false
}

@MainActor
final class MagnetometerService: ObservableObject {
    @Published var magnitude: Double = 0
    @Published var baseline: Double = 0
    @Published var delta: Double = 0
    @Published var isSpiking = false
    @Published var history: [Double] = []
    @Published var spikes: [MagSpike] = []
    @Published var ready = false
    @Published var available = true
    @Published var running = false
    @Published var peak: Double = 0

    private let motion = CMMotionManager()
    private var detector = MagSpikeDetector()
    private let maxHistory = 200

    func configure(from t: CatalogThresholds, mode: ScanMode) {
        var p = detector.params
        switch mode {
        case .quick: p.spikeDelta = t.magnetSpikeQuick
        case .balanced: p.spikeDelta = t.magnetSpikeBalanced
        case .thorough: p.spikeDelta = t.magnetSpikeThorough
        }
        p.hysteresis = t.magnetHysteresis
        p.warmupSamples = max(5, Int(t.magnetWarmupSeconds * 20))
        p.baselineN = t.magnetBaselineSamples
        p.needHits = t.magnetConsecutiveHits
        detector.params = p
    }

    func start(clearSpikes: Bool = true) {
        guard motion.isMagnetometerAvailable else { available = false; return }
        if running { return }
        available = true
        detector.reset(); history.removeAll(); peak = 0
        if clearSpikes { spikes.removeAll() }
        ready = false; isSpiking = false
        running = true
        motion.magnetometerUpdateInterval = 0.05
        motion.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let f = data?.magneticField else { return }
            self.ingest(MagSpikeDetector.magnitude(x: f.x, y: f.y, z: f.z))
        }
    }

    func stop() { motion.stopMagnetometerUpdates(); running = false }

    func ingest(_ mag: Double) {
        let ev = detector.feed(mag)
        magnitude = mag
        baseline = detector.baseline
        delta = detector.delta
        ready = detector.ready
        isSpiking = detector.isSpiking
        peak = max(peak, abs(delta))
        history.append(mag); if history.count > maxHistory { history.removeFirst() }
        if case let .spikeStarted(m, d) = ev {
            spikes.append(MagSpike(magnitude: m, delta: d, date: Date()))
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }

    func pinCurrent() {
        spikes.append(MagSpike(magnitude: magnitude, delta: delta, date: Date(), pinned: true))
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func recalibrate() { detector.reset(); history.removeAll(); peak = 0 }
}
