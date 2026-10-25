import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AmanStore
    @State private var path = NavigationPath()
    @State private var showSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                ChaletBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("قبل ما تجلس", "Before you sit"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AmanTheme.green)
                                Text(L("أمان الغرفة", "Aman Al-Ghurfa"))
                                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                    .foregroundStyle(AmanTheme.ink)
                            }
                            Spacer()
                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.title3)
                                    .foregroundStyle(AmanTheme.ink.opacity(0.7))
                                    .padding(10)
                                    .background(Color.white.opacity(0.7), in: Circle())
                            }
                            Image(systemName: "shield.checkered")
                                .font(.title2)
                                .foregroundStyle(AmanTheme.green)
                                .padding(12)
                                .background(AmanTheme.green.opacity(0.12), in: Circle())
                        }

                        Text(L("فحص سريع للشاليه والاستراحة والفندق. مساعد، مو ضمان.",
                                 "Quick check for chalets, rest houses and hotels. A helper, not a guarantee."))
                            .font(.subheadline)
                            .foregroundStyle(AmanTheme.ink.opacity(0.7))

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(L("فحص الشاليه الكامل", "Full chalet scan"))
                                        .font(.headline)
                                        .foregroundStyle(AmanTheme.ink)
                                    Text(modeSubtitle)
                                        .font(.caption)
                                        .foregroundStyle(AmanTheme.ink.opacity(0.55))
                                }
                                Spacer()
                                Text(L("موصى", "Recommended"))
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(AmanTheme.green.opacity(0.12), in: Capsule())
                                    .foregroundStyle(AmanTheme.green)
                            }
                            Picker("", selection: $store.mode) {
                                ForEach(ScanMode.allCases) { m in Text(m.title).tag(m) }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: store.mode) { _, _ in store.applyThresholds() }

                            PrimaryButton(title: L("ابدأ الآن", "Start now")) {
                                path.append(ScanStep.magnet)
                            }
                        }
                        .padding(16)
                        .softCard()

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            feature(L("مغناطيس", "Magnet"), "waveform.path.ecg")
                            feature(L("تتبع BLE", "BLE trackers"), "antenna.radiowaves.left.and.right")
                            feature(L("لمعة عدسة", "Lens glint"), "camera.viewfinder")
                            feature(L("قائمة غرف", "Room list"), "checklist")
                        }

                        Text(L("خصوصيتك محلية · ما نرفع صور", "Privacy stays on-device · no photo upload"))
                            .font(.caption2)
                            .foregroundStyle(AmanTheme.ink.opacity(0.45))
                            .frame(maxWidth: .infinity)
                        DisclaimerBanner()
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: ScanStep.self) { step in
                switch step {
                case .magnet: MagnetView(path: $path)
                case .bluetooth: BluetoothView(path: $path)
                case .lens: LensView(path: $path)
                case .checklist: ChecklistView(path: $path)
                case .result: ResultView(path: $path)
                }
            }
        }
        .amanLayout(store.lang)
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
        .tint(AmanTheme.green)
    }

    private var modeSubtitle: String {
        switch store.mode {
        case .quick: return L("≈ ٣٠ ثانية · عتبة أعلى", "≈ 30s · higher threshold")
        case .balanced: return L("≈ دقيقتين · ٣ إشارات", "≈ 2 min · 3 signals")
        case .thorough: return L("≈ ٤ دقايق · حساسية أعلى", "≈ 4 min · higher sensitivity")
        }
    }

    private func feature(_ title: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(AmanTheme.green)
                .frame(width: 40, height: 40)
                .background(AmanTheme.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            Text(title).font(.subheadline.weight(.bold)).foregroundStyle(AmanTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .softCard(16)
    }
}
