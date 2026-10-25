import Foundation
import CoreBluetooth

enum TrackerFamily: String, Codable, CaseIterable {
    case airTag, tile, smartTag, googleFMDN, dult, chipolo, unknown
    var title: String {
        switch self {
        case .airTag: return L("AirTag / Find My", "AirTag / Find My")
        case .tile: return "Tile"
        case .smartTag: return L("سامسونج SmartTag", "Samsung SmartTag")
        case .googleFMDN: return L("Google Find My", "Google Find My")
        case .dult: return "DULT"
        case .chipolo: return "Chipolo / Pebblebee"
        case .unknown: return L("جهاز مجهول", "Unknown device")
        }
    }
    var isTrackerHeuristic: Bool { self != .unknown }
}

struct TrackerMatch: Equatable {
    var family: TrackerFamily
    var detail: String
    var suspicious: Bool
}

/// Wire-format heuristics from public reverse engineering (VIGIL / continuity / SignalScout signatures).
/// Reimplemented locally — no third-party source copied.
enum TrackerSignatures {
    static let appleCompanyID: UInt16 = 0x004C
    static let findMyType: UInt8 = 0x12

    static func match(advertisement: [String: Any], name: String?) -> TrackerMatch {
        if let mfg = advertisement[CBAdvertisementDataManufacturerDataKey] as? Data,
           let m = matchManufacturer(mfg) { return m }

        let uuids = (advertisement[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [])
            + ((advertisement[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]) ?? [])
        let short = Set(uuids.map { $0.uuidString.uppercased().replacingOccurrences(of: "-", with: "") })
        let serviceData = advertisement[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] ?? [:]

        for (uuid, data) in serviceData {
            let key = uuid.uuidString.uppercased()
            if key.contains("FEAA"), let first = data.first {
                let sep = first == 0x41
                return TrackerMatch(family: .googleFMDN,
                                    detail: sep ? L("منفصل عن المالك؟", "Separated from owner?") : L("إعلان Find My", "Find My advert"),
                                    suspicious: sep)
            }
            if key.contains("FD5A") || key.contains("FDDF") {
                return TrackerMatch(family: .smartTag, detail: L("SmartTag قريب", "Nearby SmartTag"), suspicious: true)
            }
            if key.contains("FCB2") {
                return TrackerMatch(family: .dult, detail: "DULT", suspicious: true)
            }
            if key.contains("FEED") || key.contains("FEEC") || key.contains("FE84") {
                return TrackerMatch(family: .tile, detail: "Tile", suspicious: true)
            }
        }

        if short.contains(where: { $0.hasSuffix("FEED") || $0.hasSuffix("FEEC") || $0.hasSuffix("FE84") }) {
            return TrackerMatch(family: .tile, detail: "Tile UUID", suspicious: true)
        }
        if short.contains(where: { $0.hasSuffix("FD5A") || $0.hasSuffix("FDDF") }) {
            return TrackerMatch(family: .smartTag, detail: "SmartTag UUID", suspicious: true)
        }
        if short.contains(where: { $0.hasSuffix("FD9F") || $0.hasSuffix("FD6F") }) {
            return TrackerMatch(family: .airTag, detail: "Find My UUID", suspicious: true)
        }
        if short.contains(where: { $0.hasSuffix("FE95") || $0.hasSuffix("FE9F") }) {
            return TrackerMatch(family: .chipolo, detail: "Chipolo/Pebblebee", suspicious: true)
        }

        let n = (name ?? "").lowercased()
        if n.contains("tile") { return TrackerMatch(family: .tile, detail: name ?? "Tile", suspicious: true) }
        if n.contains("airtag") { return TrackerMatch(family: .airTag, detail: name ?? "AirTag", suspicious: true) }

        return TrackerMatch(family: .unknown, detail: name ?? L("بدون اسم", "Unnamed"), suspicious: false)
    }

    static func matchManufacturer(_ data: Data) -> TrackerMatch? {
        guard data.count >= 3 else { return nil }
        let company = UInt16(data[0]) | (UInt16(data[1]) << 8)
        guard company == appleCompanyID else {
            // Tile often uses company-ish prefixes in some firmwares; keep generic
            return nil
        }
        var i = 2
        while i + 1 < data.count {
            let type = data[i]
            let len = Int(data[i + 1])
            if type == findMyType {
                let status = (i + 2 < data.count) ? data[i + 2] : 0
                let maintained = (status & 0x04) != 0
                return TrackerMatch(
                    family: .airTag,
                    detail: maintained
                        ? L("Find My · المالك قريب؟", "Find My · owner nearby?")
                        : L("Find My / AirTag · يبث", "Find My / AirTag · advertising"),
                    suspicious: !maintained
                )
            }
            if len <= 0 { break }
            i += 2 + len
        }
        return nil
    }
}
