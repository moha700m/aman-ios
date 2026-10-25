import SwiftUI
import AVFoundation

enum ToolRoute: Hashable {
    case magnetMeter, bleList, flashlight, steps, rf, wifi, privacy, report
}

struct ToolsSection: View {
    @EnvironmentObject var store: AmanStore
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("الأدوات", "Tools")).font(.title3.weight(.bold)).foregroundStyle(AmanTheme.ink)
            if let tip = store.catalog.tipOfDay {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill").foregroundStyle(AmanTheme.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("نصيحة اليوم", "Tip of the day")).font(.caption.weight(.bold)).foregroundStyle(AmanTheme.green)
                        Text(tip.text).font(.footnote).foregroundStyle(AmanTheme.ink.opacity(0.75))
                    }
                }.padding(14).frame(maxWidth: .infinity, alignment: .leading).softCard(16)
            }
            VStack(spacing: 0) {
                row(.magnetMeter, L("مقياس المغناطيس المستمر", "Continuous magnet meter"), "waveform.path.ecg")
                row(.bleList, L("أجهزة البلوتوث والمتتبعات", "Bluetooth devices & trackers"), "antenna.radiowaves.left.and.right")
                row(.flashlight, L("مساعد الفلاش للّمعة", "Flashlight glint helper"), "flashlight.on.fill")
                row(.steps, L("خطوات فحص الغرفة", "Guided room scan"), "list.number")
                row(.privacy, L("قائمة الخصوصية للفندق والشاليه", "Hotel & chalet privacy list"), "lock.shield")
                row(.rf, L("نصائح الإشارات اللاسلكية", "Wireless signal tips"), "dot.radiowaves.right")
                row(.wifi, L("نصائح الواي فاي", "Wi‑Fi tips"), "wifi")
                row(.report, L("تصدير ومشاركة التقرير", "Export & share report"), "square.and.arrow.up", last: true)
            }.softCard(18)
        }
    }

    private func row(_ r: ToolRoute, _ title: String, _ symbol: String, last: Bool = false) -> some View {
        NavigationLink(value: r) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: symbol).foregroundStyle(AmanTheme.green)
                        .frame(width: 34, height: 34)
                        .background(AmanTheme.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(AmanTheme.ink)
                    Spacer()
                    Image(systemName: L10n.lang == .ar ? "chevron.left" : "chevron.right")
                        .font(.caption.weight(.bold)).foregroundStyle(AmanTheme.ink.opacity(0.3))
                }.padding(.horizontal, 14).padding(.vertical, 10)
                if !last { Divider().padding(.leading, 60) }
            }
        }.buttonStyle(.plain)
    }
}

struct ToolDestination: View {
    var route: ToolRoute
    @Binding var path: NavigationPath
    var body: some View {
        switch route {
        case .magnetMeter: MagnetView(path: $path, standalone: true)
        case .bleList: BluetoothView(path: $path, standalone: true)
        case .flashlight: FlashlightView()
        case .steps: TipListView(title: L("خطوات فحص الغرفة", "Guided room scan"), tips: \.steps, symbol: "list.number")
        case .privacy: TipListView(title: L("قائمة الخصوصية", "Privacy checklist"), tips: \.privacy, symbol: "lock.shield", checkable: true)
        case .rf: TipListView(title: L("الإشارات اللاسلكية", "Wireless signals"), tips: \.rf, symbol: "dot.radiowaves.right")
        case .wifi: TipListView(title: L("الواي فاي", "Wi‑Fi"), tips: \.wifi, symbol: "wifi")
        case .report: ReportView()
        }
    }
}

struct TipListView: View {
    @EnvironmentObject var store: AmanStore
    var title: String
    var tips: KeyPath<Catalog, [CatalogTip]>
    var symbol: String
    var checkable = false
    @State private var done: Set<Int> = []

    var body: some View {
        ZStack {
            AmanTheme.sand.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(store.catalog[keyPath: tips].enumerated()), id: \.offset) { i, tip in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: checkable ? (done.contains(i) ? "checkmark.square.fill" : "square") : symbol)
                                .foregroundStyle(AmanTheme.green).font(.title3)
                            Text(tip.text).font(.subheadline).foregroundStyle(AmanTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(14).softCard(16)
                        .onTapGesture { if checkable { if done.contains(i) { done.remove(i) } else { done.insert(i) } } }
                    }
                    DisclaimerBanner().padding(.top, 8)
                }.padding(20)
            }
        }
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}

struct FlashlightView: View {
    @State private var on = false
    @State private var level: Double = 1.0
    @State private var strobe = false
    @State private var timer: Timer?
    @State private var hasTorch = AVCaptureDevice.default(for: .video)?.hasTorch ?? false

    var body: some View {
        ZStack {
            AmanTheme.sand.ignoresSafeArea()
            VStack(spacing: 18) {
                if !hasTorch {
                    StatusCard(symbol: "flashlight.slash", title: L("ما فيه فلاش", "No torch"),
                               message: L("استخدم شاشة ساطعة أو كشاف خارجي.", "Use a bright screen or an external torch."), showSettings: false)
                }
                Image(systemName: on ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.system(size: 90)).foregroundStyle(on ? AmanTheme.green : AmanTheme.ink.opacity(0.3))
                    .padding(30).softCard(30)
                    .onTapGesture { on.toggle(); apply() }
                VStack(alignment: .leading) {
                    Text(L("السطوع", "Brightness")).font(.caption).foregroundStyle(AmanTheme.ink.opacity(0.6))
                    Slider(value: $level, in: 0.1...1.0).onChange(of: level) { _, _ in apply() }
                }
                Toggle(L("وميض بطيء (يساعد تلاحظ اللمعة)", "Slow pulse (helps glints pop)"), isOn: $strobe)
                    .onChange(of: strobe) { _, v in setStrobe(v) }
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("طريقة الاستخدام", "How to use")).font(.headline).foregroundStyle(AmanTheme.ink)
                    Text(L("١. أطفِ نور الغرفة.\n٢. حط الجوال قرب عينك والفلاش شغال.\n٣. لف ببطء على الشواحن والساعات والدخان والمرايا.\n٤. العدسة ترجع نقطة لمّاعة ثابتة حتى لو تحركت شوي.",
                             "1. Turn the room lights off.\n2. Hold the phone near your eye, torch on.\n3. Sweep slowly over chargers, clocks, smoke detectors, mirrors.\n4. A lens returns a steady pinpoint glint even as you move."))
                        .font(.subheadline).foregroundStyle(AmanTheme.ink.opacity(0.75))
                }.frame(maxWidth: .infinity, alignment: .leading).padding(14).softCard(16)
                Spacer()
                DisclaimerBanner()
            }.padding(20)
        }
        .navigationTitle(L("مساعد الفلاش", "Flashlight helper")).navigationBarTitleDisplayMode(.inline)
        .onDisappear { setStrobe(false); Torch.set(false, level: 1) }
    }

    private func apply() { Torch.set(on, level: level) }
    private func setStrobe(_ v: Bool) {
        timer?.invalidate(); timer = nil
        guard v else { apply(); return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            Task { @MainActor in on.toggle(); apply() }
        }
    }
}

enum Torch {
    static func set(_ on: Bool, level: Double) {
        guard let d = AVCaptureDevice.default(for: .video), d.hasTorch else { return }
        do {
            try d.lockForConfiguration()
            if on { try d.setTorchModeOn(level: Float(max(0.05, min(1, level)))) } else { d.torchMode = .off }
            d.unlockForConfiguration()
        } catch {}
    }
}
