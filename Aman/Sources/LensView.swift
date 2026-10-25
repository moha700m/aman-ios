import SwiftUI

/// Guided lens-glint flow: 5 illustrated steps, then a live camera view, then a summary.
struct LensView: View {
    @EnvironmentObject var store: AmanStore
    @Binding var path: NavigationPath
    @State private var phase: Phase = .guide(0)

    enum Phase: Equatable { case guide(Int), live, summary }

    struct Step { let image: String; let symbol: String; let title: String; let body: String }
    static var steps: [Step] { [
        Step(image: "LensStep1", symbol: "lightbulb.slash",
             title: L("طفِّ أنوار الغرفة", "Turn off the room lights"),
             body: L("الظلام يخلّي انعكاس العدسة واضح. سكّر الستاير لو فيه نور من برّا.",
                     "Darkness makes a lens reflection stand out. Close curtains if light comes in.")),
        Step(image: "LensStep2", symbol: "flashlight.on.fill",
             title: L("الجوال عند مستوى عينك والفلاش شغّال", "Phone at eye level, torch on"),
             body: L("الفلاش والكاميرا لازم يكونون قريب من عينك عشان الانعكاس يرجع لك.",
                     "Keep the torch and camera close to your eyes so the reflection comes back to you.")),
        Step(image: "LensStep3", symbol: "arrow.left.and.right",
             title: L("امسح الغرفة ببطء", "Sweep the room slowly"),
             body: L("ركّز على: كاشف الدخان، الشواحن، الساعات، المكيّف، التلفزيون، المرايا، فتحات التهوية، الأفياش.",
                     "Focus on: smoke detectors, chargers, clocks, AC, TV, mirrors, vents, outlets.")),
        Step(image: "LensStep4", symbol: "sparkle",
             title: L("دوّر نقطة لمّاعة زرقاء أو بنفسجية", "Look for a blue/purple bright dot"),
             body: L("العدسة تعطي نقطة صغيرة جدًا تبقى ثابتة مكانها لما تتحرك. اللمعة العادية تتحرك وتختفي.",
                     "A lens shows a tiny dot that stays fixed as you move. Normal shine moves or vanishes.")),
        Step(image: "LensStep5", symbol: "scope",
             title: L("قرّب وتأكد", "Move closer to confirm"),
             body: L("لو شفت نقطة ثابتة، قرّب منها وشوف بعينك. اضغط عليها في الكاميرا عشان تعلّمها.",
                     "If a dot stays fixed, move closer and check by eye. Tap it on the camera to mark it."))
    ] }

    var body: some View {
        Group {
            switch phase {
            case .guide(let i): guide(i)
            case .live: live
            case .summary: summary
            }
        }
        .animation(.easeInOut(duration: 0.25), value: phase)
        .navigationTitle(L("لمعة العدسة", "Lens glint"))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { store.lens.stop() }
    }

    // MARK: Guide
    private func guide(_ i: Int) -> some View {
        let s = Self.steps[i]
        return ZStack {
            AmanTheme.sand.ignoresSafeArea()
            VStack(spacing: 18) {
                progress(current: i, total: Self.steps.count + 1)
                Image(s.image).resizable().scaledToFill()
                    .frame(maxWidth: .infinity).frame(height: 260).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                    .id(s.image)
                    .transition(.opacity)
                VStack(alignment: .leading, spacing: 10) {
                    Label {
                        Text(L("الخطوة \(i+1) من \(Self.steps.count)", "Step \(i+1) of \(Self.steps.count)"))
                    } icon: { Image(systemName: s.symbol) }
                    .font(.caption.weight(.bold)).foregroundStyle(AmanTheme.green)
                    Text(s.title).font(.title2.weight(.bold)).foregroundStyle(AmanTheme.ink)
                    Text(s.body).font(.body).foregroundStyle(AmanTheme.ink.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    if i > 0 {
                        SecondaryButton(title: L("السابق", "Back")) { phase = .guide(i - 1) }
                            .frame(maxWidth: 120)
                    }
                    PrimaryButton(title: i == Self.steps.count - 1 ? L("ابدأ الكاميرا", "Start camera") : L("التالي", "Next")) {
                        if i == Self.steps.count - 1 { phase = .live } else { phase = .guide(i + 1) }
                    }
                }
                Button(L("أعرف الخطوات · ابدأ مباشرة", "I know this · start now")) { phase = .live }
                    .font(.footnote.weight(.semibold)).foregroundStyle(AmanTheme.ink.opacity(0.55))
            }.padding(20)
        }
    }

    private func progress(current: Int, total: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { k in
                Capsule().fill(k <= current ? AmanTheme.green : AmanTheme.ink.opacity(0.12))
                    .frame(height: 6)
            }
        }
    }

    // MARK: Live
    private var live: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geo in
                ZStack {
                    CameraPreview(session: store.lens.session)
                    ForEach(store.lens.candidates.prefix(6)) { c in
                        let pt = screenPoint(c, in: geo.size)
                        Button { store.lens.mark(c) } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle().stroke(Color.white, lineWidth: 3).frame(width: 46, height: 46)
                                    Circle().stroke(c.score > 0.6 ? AmanTheme.warn : Color.yellow, lineWidth: 2).frame(width: 46, height: 46)
                                }
                                Text(c.score > 0.6 ? L("لمعة ثابتة · اضغط للتعليم", "Steady glint · tap to mark")
                                                   : L("نقطة لامعة", "Bright spot"))
                                    .font(.caption2.weight(.bold)).foregroundStyle(.black)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.white.opacity(0.92), in: Capsule())
                            }
                        }
                        .position(pt)
                    }
                }
            }
            .ignoresSafeArea()

            VStack {
                HStack(spacing: 10) {
                    statusPill
                    Spacer()
                    Button { store.lens.setTorch(!store.lens.torchOn) } label: {
                        Image(systemName: store.lens.torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.title3).foregroundStyle(store.lens.torchOn ? .black : .white)
                            .frame(width: 48, height: 48)
                            .background(store.lens.torchOn ? Color.yellow : Color.white.opacity(0.2), in: Circle())
                    }
                }.padding(.horizontal, 16).padding(.top, 8)
                Spacer()
                VStack(spacing: 12) {
                    Text(L("امسح ببطء · النقطة اللي تبقى ثابتة تستاهل نظرة", "Sweep slowly · a dot that stays put is worth a look"))
                        .font(.subheadline.weight(.semibold)).foregroundStyle(AmanTheme.ink).multilineTextAlignment(.center)
                    HStack {
                        Text(L("الحساسية", "Sensitivity")).font(.caption.weight(.bold)).foregroundStyle(AmanTheme.ink.opacity(0.6))
                        Picker("", selection: Binding(get: { sensitivityLevel }, set: { store.lens.setSensitivity($0) })) {
                            Text(L("منخفضة", "Low")).tag(0.15)
                            Text(L("متوسطة", "Medium")).tag(0.5)
                            Text(L("عالية", "High")).tag(0.85)
                        }.pickerStyle(.segmented)
                    }
                    HStack(spacing: 10) {
                        Button { store.lens.markTop() } label: {
                            Label(L("علّم يدويًا", "Mark manually"), systemImage: "mappin")
                                .font(.body.weight(.bold)).foregroundStyle(AmanTheme.ink)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                        }
                        Button { store.lens.stop(); phase = .summary } label: {
                            Text(L("انتهيت", "Done"))
                                .font(.body.weight(.bold)).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(AmanTheme.green, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    Text(L("فحص مساعد — النقاط مرشحات آلية مو إثبات كاميرا", "Helper check — spots are automatic candidates, not camera proof"))
                        .font(.caption2).foregroundStyle(AmanTheme.ink.opacity(0.55))
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(14)
            }

            if store.lens.permissionDenied || !store.lens.cameraAvailable { cameraBlocked }
        }
        .task {
            store.lens.configure(from: store.catalog.thresholds)
            store.lens.setSensitivity(store.lens.sensitivity)
            await store.lens.start()
        }
    }

    private var sensitivityLevel: Double {
        let s = store.lens.sensitivity
        return s < 0.33 ? 0.15 : (s > 0.66 ? 0.85 : 0.5)
    }

    private var statusPill: some View {
        let n = store.lens.candidates.count
        return HStack(spacing: 6) {
            Circle().fill(n == 0 ? AmanTheme.green : Color.yellow).frame(width: 8, height: 8)
            Text(n == 0 ? L("ما فيه نقاط حاليًا", "No spots right now") : L("\(n) نقطة لامعة", "\(n) bright spot(s)"))
            if !store.lens.marks.isEmpty { Text("· 📌 \(store.lens.marks.count)") }
        }
        .font(.caption.weight(.bold)).foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color.black.opacity(0.55), in: Capsule())
    }

    /// Back camera buffer is landscape; preview is portrait aspect-fill.
    private func screenPoint(_ c: GlintCandidate, in size: CGSize) -> CGPoint {
        let bufW: CGFloat = 480, bufH: CGFloat = 640 // rotated to portrait
        let scale = max(size.width / bufW, size.height / bufH)
        let dx = (bufW * scale - size.width) / 2, dy = (bufH * scale - size.height) / 2
        let px = (1 - c.y) * bufW * scale - dx
        let py = c.x * bufH * scale - dy
        return CGPoint(x: min(max(px, 30), size.width - 30), y: min(max(py, 60), size.height - 60))
    }

    private var cameraBlocked: some View {
        ZStack {
            AmanTheme.sand.ignoresSafeArea()
            VStack(spacing: 16) {
                Image("LensStep2").resizable().scaledToFill().frame(height: 220).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                StatusCard(symbol: "camera.fill",
                           title: store.lens.permissionDenied ? L("إذن الكاميرا مقفل", "Camera permission is off")
                                                             : L("الكاميرا غير متوفرة", "Camera unavailable"),
                           message: L("تقدر تتبع نفس الخطوات بعينك مع «مساعد الفلاش»، أو فعّل الكاميرا من الإعدادات.",
                                       "Follow the same steps by eye with the Flashlight helper, or enable the camera in Settings."),
                           showSettings: store.lens.permissionDenied)
                PrimaryButton(title: L("التالي · القائمة", "Next · checklist")) { path.append(ScanStep.checklist) }
            }.padding(20)
        }
    }

    // MARK: Summary
    private var summary: some View {
        let n = store.lens.marks.count
        return ZStack {
            AmanTheme.sand.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: n == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 64)).foregroundStyle(n == 0 ? AmanTheme.green : AmanTheme.warn)
                    .padding(.top, 24)
                Text(n == 0 ? L("ما علّمت أي لمعة", "No glints marked") : L("علّمت \(n) نقطة", "You marked \(n) spot(s)"))
                    .font(.title2.weight(.bold)).foregroundStyle(AmanTheme.ink)
                Text(n == 0 ? L("ممتاز. كمّل القائمة عشان تتأكد من باقي الأماكن.", "Good. Continue the checklist to cover other spots.")
                            : L("افحص كل نقطة عن قرب بعينك. لو شكّيت، غطّها أو بلّغ المسؤول عن المكان.",
                                "Inspect each spot closely. If in doubt, cover it or tell the property owner."))
                    .font(.body).foregroundStyle(AmanTheme.ink.opacity(0.72)).multilineTextAlignment(.center)
                if n > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(store.lens.marks) { m in
                            Label(m.note, systemImage: "mappin.circle.fill").font(.subheadline).foregroundStyle(AmanTheme.ink)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(14).softCard(16)
                }
                Spacer()
                SecondaryButton(title: L("أعد المسح", "Scan again")) { phase = .live }
                PrimaryButton(title: L("التالي · القائمة", "Next · checklist")) { path.append(ScanStep.checklist) }
                DisclaimerBanner()
            }.padding(20)
        }
    }
}
