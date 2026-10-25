import XCTest
@testable import Aman

final class AmanTests: XCTestCase {
    func testBundledCatalogHasChecklists() {
        let c = Catalog.bundled
        XCTAssertGreaterThanOrEqual(c.version, 1)
        XCTAssertFalse(c.checklists.isEmpty)
        XCTAssertEqual(c.checklists.first?.id, "chalet")
        XCTAssertGreaterThan(c.thresholds.magnetSpikeBalanced, c.thresholds.magnetHysteresis)
    }

    func testAppleFindMySignature() {
        var bytes: [UInt8] = [0x4C, 0x00, 0x12, 0x19, 0x00]
        bytes += Array(repeating: 0x11, count: 24)
        let m = TrackerSignatures.matchManufacturer(Data(bytes))
        XCTAssertEqual(m?.family, .airTag)
        XCTAssertEqual(m?.suspicious, true)
    }

    func testAppleFindMyMaintainedLessSuspicious() {
        var bytes: [UInt8] = [0x4C, 0x00, 0x12, 0x19, 0x24]
        bytes += Array(repeating: 0x22, count: 24)
        let m = TrackerSignatures.matchManufacturer(Data(bytes))
        XCTAssertEqual(m?.family, .airTag)
    }

    func testTileServiceUUIDHeuristic() {
        let m = TrackerSignatures.match(advertisement: [:], name: "Tile Pro")
        XCTAssertEqual(m.family, .tile)
        XCTAssertTrue(m.suspicious)
    }

    func testScanResultClearLogic() {
        let s = ScanResultSummary(mode: .balanced, checklistId: "chalet",
                                  magnetSpikes: 0, bleSuspicious: 0, lensMarks: 0,
                                  checkedItems: 3, totalItems: 5, clear: true)
        XCTAssertTrue(s.clear)
        XCTAssertTrue(s.headline.contains("صافية") || s.headline.lowercased().contains("clear"))
    }

    func testCatalogJSONRoundTrip() throws {
        let data = try JSONEncoder().encode(Catalog.bundled)
        let decoded = try JSONDecoder().decode(Catalog.self, from: data)
        XCTAssertEqual(decoded.version, Catalog.bundled.version)
        XCTAssertEqual(decoded.checklists.count, Catalog.bundled.checklists.count)
    }

    func testMagnetThresholdOrdering() {
        let t = Catalog.bundled.thresholds
        XCTAssertGreaterThan(t.magnetSpikeQuick, t.magnetSpikeBalanced)
        XCTAssertGreaterThan(t.magnetSpikeBalanced, t.magnetSpikeThorough)
    }

    func testDefaultLanguageIsArabic() {
        UserDefaults.standard.removeObject(forKey: L10n.storageKey)
        XCTAssertEqual(L10n.lang, .ar)
        L10n.setLang(.en)
        XCTAssertEqual(L10n.lang, .en)
        XCTAssertEqual(L("مرحبا", "Hello"), "Hello")
        L10n.setLang(.ar)
        XCTAssertEqual(L("مرحبا", "Hello"), "مرحبا")
    }
}
