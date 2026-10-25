import Foundation
import SwiftUI

/// Debug-only: App Store screenshot mode, driven by SIMCTL_CHILD_AMAN_SHOT.
enum ShotMode {
    #if DEBUG
    static let screen: String? = ProcessInfo.processInfo.environment["AMAN_SHOT"]
    #else
    static let screen: String? = nil
    #endif
    static var active: Bool { screen != nil }

    @MainActor static func seed(_ store: AmanStore) {
        guard active else { return }
        let m = store.magnet
        m.available = true; m.running = true; m.ready = true
        m.baseline = 46
        var h: [Double] = []
        for i in 0..<160 { h.append(46 + sin(Double(i) / 6) * 1.5 + (i > 120 && i < 135 ? 38 : 0)) }
        m.history = h; m.magnitude = 84; m.delta = 38; m.peak = 38; m.isSpiking = true
        m.spikes = [MagSpike(magnitude: 84, delta: 38, date: Date().addingTimeInterval(-40)),
                    MagSpike(magnitude: 71, delta: 25, date: Date().addingTimeInterval(-160))]
        let b = store.ble
        b.poweredOn = true; b.scanning = true; b.state = .poweredOn
        func d(_ n: String, _ r: Int, _ f: TrackerFamily, _ s: Bool) -> BLEDevice {
            BLEDevice(id: UUID(), name: n, rssi: r, family: f, detail: f.title, suspicious: s,
                      lastSeen: Date(), peakRSSI: r, samples: 20, smoothed: Double(r))
        }
        b.devices = [d(L("متتبع Find My", "Find My tracker"), -58, .airTag, true),
                     d(L("سماعات AirPods", "AirPods"), -64, .unknown, false),
                     d("midea AC", -71, .unknown, false),
                     d(L("جهاز Samsung", "Samsung device"), -80, .unknown, false),
                     d(L("ساعة Apple", "Apple Watch"), -84, .unknown, false),
                     d(L("جهاز بلوتوث • A3F9", "Bluetooth device • A3F9"), -93, .unknown, false)]
        store.lens.marks = [LensMark(note: L("لمعة معلّمة (قوة ٧٢٪)", "Marked glint (strength 72%)"))]
    }
}
