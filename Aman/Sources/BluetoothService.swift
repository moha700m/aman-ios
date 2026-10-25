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

    private var central: CBCentralManager!
    private var strong = -50
    private var medium = -70

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func configure(from t: CatalogThresholds) {
        strong = t.bleStrongRSSI
        medium = t.bleMediumRSSI
    }

    func start() {
        devices.removeAll()
        guard central.state == .poweredOn else { return }
        scanning = true
        central.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
    }

    func stop() {
        central.stopScan()
        scanning = false
    }

    private func upsert(_ peripheral: CBPeripheral, adv: [String: Any], rssi: Int) {
        guard rssi < 0, rssi > -127 else { return }
        let match = TrackerSignatures.match(advertisement: adv, name: peripheral.name ?? (adv[CBAdvertisementDataLocalNameKey] as? String))
        let name = peripheral.name
            ?? (adv[CBAdvertisementDataLocalNameKey] as? String)
            ?? match.family.title

        if let i = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            devices[i].rssi = rssi
            devices[i].peakRSSI = max(devices[i].peakRSSI, rssi)
            devices[i].lastSeen = Date()
            devices[i].samples += 1
            if match.family != .unknown {
                devices[i].family = match.family
                devices[i].detail = match.detail
                devices[i].suspicious = match.suspicious || rssi >= strong
            } else if rssi >= strong {
                devices[i].suspicious = true
            }
        } else {
            let sus = match.suspicious || (match.family.isTrackerHeuristic) || rssi >= strong
            devices.append(BLEDevice(
                id: peripheral.identifier, name: name, rssi: rssi,
                family: match.family, detail: match.detail, suspicious: sus,
                lastSeen: Date(), peakRSSI: rssi, samples: 1
            ))
            if sus { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        devices.sort { ($0.suspicious ? 0 : 1, -$0.rssi) < ($1.suspicious ? 0 : 1, -$1.rssi) }
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
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
