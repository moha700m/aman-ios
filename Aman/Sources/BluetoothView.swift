import SwiftUI

struct BluetoothView: View {
    @EnvironmentObject var store: AmanStore
    @Binding var path: NavigationPath
    var standalone = false
    @State private var focus: UUID?

    var body: some View {
        ZStack {
            AmanTheme.sand.ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    Text(L("أجهزة قريبة", "Nearby devices")).font(.title2.weight(.bold)).foregroundStyle(AmanTheme.ink)
                    Spacer()
                    Text("\(store.ble.devices.count)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(AmanTheme.green.opacity(0.12), in: Capsule())
                        .foregroundStyle(AmanTheme.green)
                }

                radar

                BluetoothStateCard(state: store.ble.state)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.ble.devices) { d in
                            deviceRow(d)
                        }
                        if store.ble.devices.isEmpty && store.ble.poweredOn {
                            Text(L("يمسح… قرّب من الزوايا والشاحن والدخان",
                                     "Scanning… move near corners, chargers and smoke detectors"))
                                .font(.subheadline)
                                .foregroundStyle(AmanTheme.ink.opacity(0.5))
                                .padding(.top, 20)
                        }
                    }
                }

                if !standalone {
                    PrimaryButton(title: L("التالي · لمعة العدسة", "Next · Lens glint")) {
                        store.ble.stop()
                        path.append(ScanStep.lens)
                    }
                }
                DisclaimerBanner()
            }
            .padding(20)
        }
        .navigationTitle(L("بلوتوث وتتبع", "Bluetooth & trackers"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.ble.configure(from: store.catalog.thresholds); store.ble.start() }
        .onDisappear { store.ble.stop() }
    }

    private var radar: some View {
        ZStack {
            Circle().stroke(AmanTheme.green.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [6,4])).frame(width: 120, height: 120)
            Circle().fill(AmanTheme.green.opacity(0.12)).frame(width: 100, height: 100)
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.largeTitle)
                .foregroundStyle(AmanTheme.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .softCard(24)
    }

    private func deviceRow(_ d: BLEDevice) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: d.suspicious ? "tag.fill" : "dot.radiowaves.left.and.right")
                    .foregroundStyle(d.suspicious ? AmanTheme.warn : AmanTheme.green)
                    .frame(width: 40, height: 40)
                    .background((d.suspicious ? AmanTheme.warn : AmanTheme.green).opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(d.name).font(.subheadline.weight(.bold)).foregroundStyle(AmanTheme.ink)
                    Text((d.family == .unknown ? "" : "\(d.family.title) · ") + "\(d.proximity) · \(d.rssi) dBm")
                        .font(.caption)
                        .foregroundStyle(AmanTheme.ink.opacity(0.5))
                }
                Spacer()
                Text(d.suspicious ? L("اشتباه", "Suspect") : L("عادي", "OK"))
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background((d.suspicious ? AmanTheme.warn : AmanTheme.green).opacity(0.12), in: Capsule())
                    .foregroundStyle(d.suspicious ? AmanTheme.warn : AmanTheme.green)
            }
            GeometryReader { g in
                let w = max(0.08, min(1.0, CGFloat(d.rssi + 100) / 60.0))
                Capsule().fill(AmanTheme.ink.opacity(0.08))
                    .overlay(alignment: .leading) {
                        Capsule().fill(d.suspicious ? AmanTheme.warn : AmanTheme.green).frame(width: g.size.width * w)
                    }
            }
            .frame(height: 6)

            if focus == d.id {
                Text(L("Hot/cold: اقترب إذا الرقم ارتفع (صار أقل سالب)",
                         "Hot/cold: move closer if RSSI rises (less negative)"))
                    .font(.caption2)
                    .foregroundStyle(AmanTheme.ink.opacity(0.55))
            }
        }
        .padding(14)
        .softCard(16)
        .onTapGesture { focus = d.id }
    }
}
