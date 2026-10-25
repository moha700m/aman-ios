import SwiftUI

struct ResultView: View {
    @EnvironmentObject var store: AmanStore
    @Binding var path: NavigationPath
    @State private var shareImage: UIImage?

    var summary: ScanResultSummary { store.lastSummary ?? store.buildSummary() }

    var body: some View {
        ZStack {
            AmanTheme.sand.ignoresSafeArea()
            VStack(spacing: 16) {
                Text(L("نتيجة الفحص", "Scan result"))
                    .font(.title2.weight(.bold)).foregroundStyle(AmanTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                shareCard
                    .background(
                        GeometryReader { g in
                            Color.clear.onAppear { renderShare() }
                        }
                    )

                stats

                HStack(spacing: 10) {
                    Button {
                        renderShare()
                        if let img = shareImage {
                            let av = UIActivityViewController(activityItems: [img, summary.headline + "\n" + store.catalog.disclaimer], applicationActivities: nil)
                            UIApplication.shared.connectedScenes
                                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                                .last?.present(av, animated: true)
                        }
                    } label: {
                        Label(L("مشاركة", "Share"), systemImage: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AmanTheme.ink)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AmanTheme.ink.opacity(0.1)))
                    }
                    PrimaryButton(title: L("تم", "Done")) {
                        store.stopAll()
                        path = NavigationPath()
                    }
                }
                DisclaimerBanner()
            }
            .padding(20)
        }
        .navigationBarBackButtonHidden(false)
    }

    private var shareCard: some View {
        VStack(spacing: 10) {
            Image(systemName: summary.clear ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .font(.system(size: 52))
                .foregroundStyle(summary.clear ? AmanTheme.green : AmanTheme.warn)
                .frame(width: 72, height: 72)
            Text(summary.headline)
                .font(.title3.weight(.heavy))
                .foregroundStyle(summary.clear ? AmanTheme.green : AmanTheme.warn)
            Text(L("مغناطيس · بلوتوث · عدسة · قائمة", "Magnet · Bluetooth · Lens · List"))
                .font(.caption)
                .foregroundStyle(AmanTheme.ink.opacity(0.55))
            Text(L("أمان الغرفة", "Aman Al-Ghurfa"))
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(AmanTheme.green.opacity(0.12), in: Capsule())
                .foregroundStyle(AmanTheme.green)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .softCard(24)
    }

    private var stats: some View {
        VStack(spacing: 8) {
            row(L("ارتفاعات مغناطيس", "Magnet spikes"), "\(summary.magnetSpikes)")
            row(L("أجهزة بلوتوث مشتبهة", "Suspect BLE"), "\(summary.bleSuspicious)")
            row(L("علامات لمعة", "Lens marks"), "\(summary.lensMarks)")
            row(L("بنود القائمة", "Checklist"), "\(summary.checkedItems)/\(summary.totalItems)")
        }
        .padding(14)
        .softCard()
    }

    private func row(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t).foregroundStyle(AmanTheme.ink.opacity(0.7))
            Spacer()
            Text(v).fontWeight(.bold).foregroundStyle(AmanTheme.ink)
        }
        .font(.subheadline)
    }

    @MainActor private func renderShare() {
        let view = shareCard.frame(width: 320)
        let renderer = ImageRenderer(content: view.environment(\.layoutDirection, L10n.lang == .ar ? .rightToLeft : .leftToRight))
        renderer.scale = 3
        shareImage = renderer.uiImage
    }
}
