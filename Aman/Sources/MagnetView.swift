import SwiftUI

struct MagnetView: View {
    @EnvironmentObject var store: AmanStore
    @Binding var path: NavigationPath
    var standalone = false

    var body: some View {
        ZStack {
            AmanTheme.sand.ignoresSafeArea()
            VStack(spacing: 14) {
                header
                Text(L("حرّك الجوال ببطء قرب الساعة، الدخان، والشاحن",
                         "Move the phone slowly near clocks, smoke detectors and chargers"))
                    .font(.subheadline)
                    .foregroundStyle(AmanTheme.ink.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !store.magnet.available {
                    StatusCard(symbol: "sensor", title: L("الحساس غير متوفر", "Sensor unavailable"),
                               message: L("هذا الجهاز ما فيه مغناطيس متاح.", "This device has no available magnetometer."), showSettings: false)
                }
                gauge
                if standalone && !store.magnet.spikes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("سجل الارتفاعات", "Anomaly history")).font(.caption.weight(.bold)).foregroundStyle(AmanTheme.ink.opacity(0.6))
                        ForEach(store.magnet.spikes.suffix(4).reversed()) { s in
                            Text("\(s.date.formatted(date: .omitted, time: .standard)) · Δ \(String(format: "%.0f", s.delta)) µT\(s.pinned ? " 📌" : "")")
                                .font(.caption).foregroundStyle(AmanTheme.ink.opacity(0.7))
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                if store.magnet.isSpiking {
                    alert
                } else if store.magnet.ready {
                    Text(L("ما فيه ارتفاع غريب الحين", "No unusual spike right now"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AmanTheme.green)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .softCard()
                } else {
                    Text(L("يثبّت خط الأساس…", "Calibrating baseline…"))
                        .font(.subheadline)
                        .foregroundStyle(AmanTheme.ink.opacity(0.5))
                }

                chart
                Spacer()
                HStack(spacing: 10) {
                    SecondaryButton(title: L("ثبّت اشتباه", "Pin suspect")) { store.magnet.pinCurrent() }
                    if standalone {
                        SecondaryButton(title: L("إعادة معايرة", "Recalibrate")) { store.magnet.recalibrate() }
                    } else {
                        PrimaryButton(title: L("التالي · بلوتوث", "Next · Bluetooth")) {
                            store.magnet.stop()
                            path.append(ScanStep.bluetooth)
                        }
                    }
                }
                DisclaimerBanner()
            }
            .padding(20)
        }
        .navigationTitle(L("حقل مغناطيسي", "Magnetic field"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.magnet.configure(from: store.catalog.thresholds, mode: store.mode); store.magnet.start(clearSpikes: !standalone) }
        .onDisappear { store.magnet.stop() }
    }

    private var header: some View {
        HStack {
            Text(L("مغناطيس", "Magnetometer")).font(.title2.weight(.bold)).foregroundStyle(AmanTheme.ink)
            Spacer()
            Text(store.magnet.ready ? L("مباشر", "Live") : L("تجهيز", "Warm-up"))
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(AmanTheme.green.opacity(0.12), in: Capsule())
                .foregroundStyle(AmanTheme.green)
        }
    }

    private var gauge: some View {
        ZStack {
            Circle()
                .stroke(AmanTheme.green.opacity(0.15), lineWidth: 14)
                .frame(width: 200, height: 200)
            Circle()
                .trim(from: 0, to: min(1, abs(store.magnet.delta)/40))
                .stroke(store.magnet.isSpiking ? AmanTheme.warn : AmanTheme.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 200, height: 200)
            VStack(spacing: 4) {
                Text(String(format: "%.1f", store.magnet.magnitude))
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(AmanTheme.green)
                Text("µT")
                    .font(.caption)
                    .foregroundStyle(AmanTheme.ink.opacity(0.5))
                Text(L("خط الأساس \(String(format: "%.0f", store.magnet.baseline))",
                         "Baseline \(String(format: "%.0f", store.magnet.baseline))"))
                    .font(.caption2)
                    .foregroundStyle(AmanTheme.ink.opacity(0.45))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: AmanTheme.ink.opacity(0.06), radius: 16, y: 8)
    }

    private var alert: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AmanTheme.warn)
            VStack(alignment: .leading) {
                Text(L("ارتفاع مفاجئ", "Sudden spike")).font(.headline).foregroundStyle(AmanTheme.warn)
                Text(L("قرب وافحص بالعين — المغناطيس مو إثبات كاميرا",
                         "Look closer by eye — magnetometer is not camera proof"))
                    .font(.caption).foregroundStyle(AmanTheme.ink.opacity(0.6))
            }
            Spacer()
        }
        .padding()
        .background(AmanTheme.warn.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L("سجل الحقل", "Field history")).font(.caption).foregroundStyle(AmanTheme.ink.opacity(0.5))
            GeometryReader { g in
                let vals = store.magnet.history
                Path { p in
                    guard vals.count > 1, let minV = vals.min(), let maxV = vals.max() else { return }
                    let span = max(maxV - minV, 1)
                    for (i, v) in vals.enumerated() {
                        let x = g.size.width * CGFloat(i) / CGFloat(vals.count - 1)
                        let y = g.size.height * (1 - CGFloat((v - minV) / span))
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(AmanTheme.green, lineWidth: 2)
            }
            .frame(height: 56)
        }
    }
}
