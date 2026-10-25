import Foundation
import Combine

@MainActor
final class AmanStore: ObservableObject {
    @Published var catalog: Catalog
    @Published var mode: ScanMode = .balanced
    @Published var checklistId: String = "chalet"
    @Published var checked: Set<String> = []
    @Published var lastSummary: ScanResultSummary?

    let magnet = MagnetometerService()
    let ble = BluetoothService()
    let lens = LensGlintService()

    init() {
        catalog = CatalogService.cached() ?? .bundled
        applyThresholds()
        Task { await refreshCatalog() }
    }

    func refreshCatalog() async {
        if let remote = await CatalogService.fetchRemote(), remote.version >= catalog.version {
            catalog = remote
            applyThresholds()
        }
    }

    func applyThresholds() {
        magnet.configure(from: catalog.thresholds, mode: mode)
        ble.configure(from: catalog.thresholds)
        lens.configure(from: catalog.thresholds)
    }

    func startAllSensors() {
        applyThresholds()
        magnet.start()
        ble.start()
    }

    func stopAll() {
        magnet.stop()
        ble.stop()
        lens.stop()
    }

    func buildSummary() -> ScanResultSummary {
        let list = catalog.checklists.first(where: { $0.id == checklistId })
        let total = list?.items.count ?? 0
        let spikes = magnet.spikes.count
        let sus = ble.devices.filter(\.suspicious).count
        let marks = lens.marks.count
        let clear = spikes == 0 && sus == 0 && marks == 0
        let s = ScanResultSummary(
            mode: mode, checklistId: checklistId,
            magnetSpikes: spikes, bleSuspicious: sus, lensMarks: marks,
            checkedItems: checked.count, totalItems: total, clear: clear
        )
        lastSummary = s
        return s
    }
}
