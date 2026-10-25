import Foundation
import CoreBluetooth
import Combine
import UIKit

struct BLEDevice: Identifiable, Equatable {
    var id: UUID
    var name: String
    var rssi: Int
    var family: TrackerFamily
    var detail: String
    var suspicious: Bool
    var lastSeen: Date
    var peakRSSI: Int
    var samples: Int
    var smoothed: Double = -100
    var proximity: String { RSSISmoother.proximity(smoothed) }

    var rssiLabel: String {
        if rssi >= -50 { return L("قوي جدًا", "Very strong") }
        if rssi >= -70 { return L("متوسط", "Medium") }
        return L("ضعيف", "Weak")
    }
}

@MainActor
final class BluetoothService: NSObject, ObservableObject {
    @Published var devices: [BLEDevice] = []
    @Published var scanning = false
    @Published var poweredOn = false
    @Published var authDenied = false

    private var central: CBCentralManager?
    @Published var state: CBManagerState = .unknown
    private var strong = -50
    private var medium = -70
    private var smoothers: [UUID: RSSISmoother] = [:]

    override init() { super.init() }

    /// Created lazily (first scan) so the permission prompt appears in context, and with the
    /// system power alert disabled — its "Settings" link opens a broken pane on recent iOS.
    private func ensureCentral() -> CBCentralManager {
        if let c = central { return c }
        let c = CBCentralManager(delegate: self, queue: .main,
                                 options: [CBCentralManagerOptionShowPowerAlertKey: false])
        central = c
        return c
    }

    var authorization: CBManagerAuthorization { CBCentralManager.authorization }

    func configure(from t: CatalogThresholds) {
        strong = t.bleStrongRSSI
        medium = t.bleMediumRSSI
    }

    func start() {
        if ShotMode.active { return }
        devices.removeAll(); smoothers.removeAll()
        scanning = true   // if BT not ready yet, didUpdateState starts the scan
        let c = ensureCentral()
        guard c.state == .poweredOn else { return }
        c.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
    }

    func stop() {
        central?.stopScan()
        scanning = false
    }

    private func upsert(_ peripheral: CBPeripheral, adv: [String: Any], rssi: Int) {
        guard rssi < 0, rssi > -127 else { return }
        var sm = smoothers[peripheral.identifier] ?? RSSISmoother()
        let smooth = sm.feed(rssi); smoothers[peripheral.identifier] = sm
        let match = TrackerSignatures.match(advertisement: adv, name: peripheral.name ?? (adv[CBAdvertisementDataLocalNameKey] as? String))
        let advName = (peripheral.name ?? (adv[CBAdvertisementDataLocalNameKey] as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let name = advName.isEmpty ? (match.family != .unknown ? match.family.title : BLENamer.label(adv: adv, id: peripheral.identifier)) : advName

        if let i = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            devices[i].rssi = rssi
            devices[i].peakRSSI = max(devices[i].peakRSSI, rssi)
            devices[i].lastSeen = Date()
            devices[i].samples += 1
            devices[i].smoothed = smooth
            if !advName.isEmpty { devices[i].name = advName }
            if match.family != .unknown {
                devices[i].family = match.family
                devices[i].detail = match.detail
                devices[i].suspicious = true
            }
        } else {
            let sus = match.family.isTrackerHeuristic || match.suspicious
            devices.append(BLEDevice(
                id: peripheral.identifier, name: name, rssi: rssi,
                family: match.family, detail: match.detail, suspicious: sus,
                lastSeen: Date(), peakRSSI: rssi, samples: 1, smoothed: smooth
            ))
            if sus { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        devices.sort { ($0.suspicious ? 0 : 1, -$0.rssi) < ($1.suspicious ? 0 : 1, -$1.rssi) }
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            state = central.state
            poweredOn = central.state == .poweredOn
            authDenied = central.state == .unauthorized
            if poweredOn && scanning {
                central.scanForPeripherals(withServices: nil, options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: true
                ])
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            upsert(peripheral, adv: advertisementData, rssi: RSSI.intValue)
        }
    }
}
