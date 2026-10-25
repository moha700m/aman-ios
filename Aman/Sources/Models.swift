import Foundation

enum ScanMode: String, CaseIterable, Identifiable {
    case quick, balanced, thorough
    var id: String { rawValue }
    var title: String {
        switch self {
        case .quick: return L("سريع · ٣٠ ثانية", "Quick · 30s")
        case .balanced: return L("متوازن", "Balanced")
        case .thorough: return L("شامل", "Thorough")
        }
    }
    var seconds: TimeInterval {
        switch self { case .quick: return 30; case .balanced: return 120; case .thorough: return 240 }
    }
}

enum ScanStep: Int, CaseIterable {
    case magnet, bluetooth, lens, checklist, result
    var title: String {
        switch self {
        case .magnet: return L("مغناطيس", "Magnetometer")
        case .bluetooth: return L("بلوتوث", "Bluetooth")
        case .lens: return L("لمعة عدسة", "Lens glint")
        case .checklist: return L("قائمة الغرفة", "Room list")
        case .result: return L("النتيجة", "Result")
        }
    }
}

struct LensMark: Identifiable, Equatable {
    var id = UUID()
    var note: String
    var date: Date = Date()
}

struct ScanResultSummary: Equatable {
    var mode: ScanMode
    var checklistId: String
    var magnetSpikes: Int
    var bleSuspicious: Int
    var lensMarks: Int
    var checkedItems: Int
    var totalItems: Int
    var clear: Bool
    var date: Date = Date()

    var headline: String {
        clear
            ? L("الغرفة صافية ✓", "Room looks clear ✓")
            : L("فيه نقاط تستاهل نظرة", "Some spots need a closer look")
    }
}
