import Foundation
import CoreMotion
import Combine
import UIKit

struct MagSpike: Identifiable, Equatable {
    var id = UUID()
    var magnitude: Double
    var delta: Double
    var date: Date
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

    private let motion = CMMotionManager()
    private var samples: [Double] = []
    private var consecutive = 0
    private var spikeDelta: Double = 18
    private var hysteresis: Double = 8
    private var warmup: TimeInterval = 1.5
    private var baselineN = 40
    private var needHits = 3
    private var startedAt: Date?
    private let maxHistory = 120

    func configure(from t: CatalogThresholds, mode: ScanMode) {
        switch mode {
        case .quick: spikeDelta = t.magnetSpikeQuick
        case .balanced: spikeDelta = t.magnetSpikeBalanced
        case .thorough: spikeDelta = t.magnetSpikeThorough
        }
        hysteresis = t.magnetHysteresis
        warmup = t.magnetWarmupSeconds
        baselineN = t.magnetBaselineSamples
        needHits = t.magnetConsecutiveHits
    }

    func start() {
        guard motion.isMagnetometerAvailable else { available = false; return }
        available = true
        samples.removeAll(); history.removeAll(); spikes.removeAll()
        ready = false; isSpiking = false; consecutive = 0
        startedAt = Date()
        motion.magnetometerUpdateInterval = 0.05
        motion.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let f = data?.magneticField else { return }
            let mag = sqrt(f.x*f.x + f.y*f.y + f.z*f.z)
            self.ingest(mag)
        }
    }

    func stop() {
        motion.stopMagnetometerUpdates()
    }

    private func ingest(_ mag: Double) {
        magnitude = mag
        history.append(mag)
        if history.count > maxHistory { history.removeFirst() }
        samples.append(mag)
        if samples.count > baselineN { samples.removeFirst() }

        let elapsed = Date().timeIntervalSince(startedAt ?? Date())
        if elapsed < warmup {
            baseline = samples.reduce(0,+)/Double(max(samples.count,1))
            return
        }
        ready = true
        baseline = samples.reduce(0,+)/Double(samples.count)
        delta = mag - baseline

        if abs(delta) >= spikeDelta {
            consecutive += 1
            if consecutive >= needHits {
                if !isSpiking {
                    isSpiking = true
                    let spike = MagSpike(magnitude: mag, delta: delta, date: Date())
                    spikes.append(spike)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        } else if abs(delta) < hysteresis {
            consecutive = 0
            isSpiking = false
        }
    }

    func pinCurrent() {
        spikes.append(MagSpike(magnitude: magnitude, delta: delta, date: Date()))
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
