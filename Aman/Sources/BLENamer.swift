import Foundation
import CoreBluetooth

/// Derives a human label for anonymous BLE advertisers from manufacturer data and service UUIDs.
enum BLENamer {
    static let companies: [UInt16: String] = [
        0x004C: "Apple", 0x0075: "Samsung", 0x0006: "Microsoft", 0x00E0: "Google", 0x018E: "Google",
        0x038F: "Xiaomi", 0x027D: "Huawei", 0x0157: "Huami (Amazfit)", 0x00D2: "Dialog", 0x0059: "Nordic",
        0x000D: "Texas Instruments", 0x0087: "Garmin", 0x009E: "Bose", 0x012D: "Sony", 0x00C4: "LG",
        0x0171: "Amazon", 0x067C: "Tile", 0x01DA: "Logitech", 0x0310: "SGL Italia", 0x02E5: "Espressif",
        0x0822: "Midea", 0x0499: "Ruuvi", 0x0131: "Cypress", 0x0002: "Intel", 0x000F: "Broadcom",
        0x001D: "Qualcomm", 0x0046: "MediaTek", 0x0030: "ST Micro", 0x0397: "Oppo", 0x072F: "OnePlus",
        0x0BDA: "Realtek", 0x058E: "Meta", 0x0103: "Bang & Olufsen", 0x0057: "Harman", 0x00CD: "Microchip",
        0x0078: "Nike", 0x0101: "Fitbit", 0x06A6: "Chipolo"
    ]

    static let appleTypes: [UInt8: (String, String)] = [
        0x07: ("سماعات AirPods", "AirPods"),
        0x10: ("جهاز Apple قريب (آيفون/آيباد/ماك)", "Nearby Apple device (iPhone/iPad/Mac)"),
        0x0C: ("جهاز Apple (Handoff)", "Apple device (Handoff)"),
        0x0F: ("جهاز Apple (مشاركة)", "Apple device (Sharing)"),
        0x12: ("شبكة Find My", "Find My network"),
        0x09: ("جهاز Apple (AirPlay)", "Apple device (AirPlay)"),
        0x0B: ("ساعة Apple", "Apple Watch"),
        0x05: ("جهاز Apple (AirDrop)", "Apple device (AirDrop)"),
        0x0E: ("جهاز Apple (نقطة اتصال)", "Apple device (Hotspot)"),
        0x02: ("إشارة iBeacon", "iBeacon")
    ]

    static let services: [String: (String, String)] = [
        "180D": ("حزام نبض", "Heart-rate sensor"), "180F": ("جهاز ببطارية", "Battery device"),
        "1812": ("لوحة مفاتيح/فأرة", "Keyboard/mouse"), "110B": ("جهاز صوت", "Audio device"),
        "184E": ("جهاز صوت", "Audio device"), "1844": ("جهاز صوت", "Audio device"),
        "FE9F": ("جهاز Google", "Google device"), "FD5A": ("جهاز Samsung", "Samsung device"),
        "FEAA": ("إشارة Eddystone", "Eddystone beacon"), "1816": ("حساس دراجة", "Cycling sensor"),
        "181A": ("حساس بيئة", "Environmental sensor"), "FE2C": ("جهاز Google (Fast Pair)", "Google Fast Pair device"),
        "FCF1": ("جهاز Google", "Google device"), "FE07": ("سماعة Sonos", "Sonos speaker"),
        "FEED": ("Tile", "Tile"), "FD44": ("جهاز Apple", "Apple device"), "1809": ("ميزان حرارة", "Thermometer"),
        "181D": ("ميزان", "Weight scale"), "1810": ("جهاز ضغط", "Blood-pressure monitor")
    ]

    static func label(adv: [String: Any], id: UUID) -> String {
        if let d = adv[CBAdvertisementDataManufacturerDataKey] as? Data, d.count >= 2 {
            let cid = UInt16(d[d.startIndex]) | UInt16(d[d.startIndex + 1]) << 8
            if cid == 0x004C, d.count >= 3, let t = appleTypes[d[d.startIndex + 2]] { return L(t.0, t.1) }
            if let c = companies[cid] { return L("جهاز \(c)", "\(c) device") }
        }
        let uuids = (adv[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [])
            + ((adv[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data])?.keys.map { $0 } ?? [])
        for u in uuids { if let s = services[u.uuidString.uppercased()] { return L(s.0, s.1) } }
        let tail = String(id.uuidString.suffix(4))
        return L("جهاز بلوتوث • \(tail)", "Bluetooth device • \(tail)")
    }
}
