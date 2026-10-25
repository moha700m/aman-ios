import SwiftUI

enum ReportBuilder {
    static func text(summary s: ScanResultSummary, spikes: [MagSpike], devices: [BLEDevice], marks: [LensMark],
                     checklistTitle: String, disclaimer: String) -> String {
        var out: [String] = []
        out.append(L("تقرير «أمان الغرفة»", "Aman Al-Ghurfa report"))
        out.append(s.date.formatted(date: .abbreviated, time: .shortened))
        out.append(s.headline)
        out.append("")
        out.append(L("المكان: ", "Place: ") + checklistTitle)
        out.append(L("بنود القائمة: ", "Checklist: ") + "\(s.checkedItems)/\(s.totalItems)")
        out.append(L("ارتفاعات المغناطيس: ", "Magnet spikes: ") + "\(spikes.count)")
        for sp in spikes.prefix(10) {
            out.append("  • \(sp.date.formatted(date: .omitted, time: .standard))  Δ\(String(format: "%.0f", sp.delta)) µT")
        }
        let sus = devices.filter(\.suspicious)
        out.append(L("أجهزة بلوتوث تستاهل نظرة: ", "BLE worth a look: ") + "\(sus.count)")
        for d in sus.prefix(10) { out.append("  • \(d.family.title) · \(d.name) · \(d.peakRSSI) dBm") }
        out.append(L("علامات لمعة: ", "Glint marks: ") + "\(marks.count)")
        out.append("")
        out.append(disclaimer)
        return out.joined(separator: "\n")
    }
}

struct ReportView: View {
    @EnvironmentObject var store: AmanStore
    var report: String {
        let s = store.lastSummary ?? store.buildSummary()
        let title = store.catalog.checklists.first { $0.id == s.checklistId }?.title ?? ""
        return ReportBuilder.text(summary: s, spikes: store.magnet.spikes, devices: store.ble.devices,
                                  marks: store.lens.marks, checklistTitle: title, disclaimer: store.catalog.disclaimer)
    }
    var body: some View {
        ZStack {
            AmanTheme.sand.ignoresSafeArea()
            VStack(spacing: 14) {
                ScrollView {
                    Text(report).font(.system(.footnote, design: .monospaced)).foregroundStyle(AmanTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                }.softCard(16)
                ShareLink(item: report) {
                    Label(L("مشاركة التقرير", "Share report"), systemImage: "square.and.arrow.up")
                        .font(.body.weight(.bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(AmanTheme.green, in: RoundedRectangle(cornerRadius: 16))
                }
                Button { UIPasteboard.general.string = report } label: {
                    Text(L("نسخ", "Copy")).font(.subheadline.weight(.semibold)).foregroundStyle(AmanTheme.ink)
                }
            }.padding(20)
        }
        .navigationTitle(L("التقرير", "Report")).navigationBarTitleDisplayMode(.inline)
    }
}
