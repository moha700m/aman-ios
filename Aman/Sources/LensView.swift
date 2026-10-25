import SwiftUI

struct LensView: View {
    @EnvironmentObject var store: AmanStore
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraPreview(session: store.lens.session)
                .ignoresSafeArea()
                .overlay {
                    ForEach(store.lens.candidates.prefix(5)) { c in
                        Circle()
                            .stroke(AmanTheme.green, lineWidth: 2)
                            .frame(width: 28, height: 28)
                            .position(x: UIScreen.main.bounds.width * c.x,
                                      y: UIScreen.main.bounds.height * c.y * 0.75 + 80)
                            .opacity(0.85)
                    }
                }

            VStack {
                HStack {
                    Text(L("لمعة العدسة", "Lens glint"))
                        .font(.headline.weight(.bold)).foregroundStyle(.white)
                    Spacer()
                    Text(store.lens.torchOn ? "FLASH" : "OFF")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.85), in: Capsule())
                        .foregroundStyle(.black)
                        .onTapGesture { store.lens.setTorch(!store.lens.torchOn) }
                }
                .padding(.horizontal, 20).padding(.top, 8)

                Spacer()

                VStack(alignment: .leading, spacing: 10) {
                    Text(L("شفت لمعة ثابتة؟ قرّب بالعين وعلّمها",
                             "See a steady glint? Check by eye and mark it"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AmanTheme.ink)
                    Text(L("النقاط الخضراء مرشحات آلية فقط — مو إثبات كاميرا",
                             "Green dots are automatic candidates only — not camera proof"))
                        .font(.caption)
                        .foregroundStyle(AmanTheme.ink.opacity(0.55))
                    HStack(spacing: 10) {
                        SecondaryButton(title: L("لا / تخطي", "No / skip")) {
                            store.lens.stop()
                            path.append(ScanStep.checklist)
                        }
                        Button {
                            store.lens.markTop()
                        } label: {
                            Text(L("نعم · علّم", "Yes · mark"))
                                .font(.body.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(AmanTheme.warn, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    if !store.lens.marks.isEmpty {
                        Text(L("علامات: \(store.lens.marks.count)", "Marks: \(store.lens.marks.count)"))
                            .font(.caption).foregroundStyle(AmanTheme.ink.opacity(0.6))
                    }
                    Button {
                        store.lens.stop()
                        path.append(ScanStep.checklist)
                    } label: {
                        Text(L("التالي · القائمة", "Next · checklist"))
                            .font(.body.weight(.bold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(AmanTheme.green, in: RoundedRectangle(cornerRadius: 16))
                    }
                    DisclaimerBanner()
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(16)
            }

            if store.lens.permissionDenied || !store.lens.cameraAvailable {
                AmanTheme.sand.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image("LensDemo").resizable().scaledToFill().frame(height: 220).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    StatusCard(symbol: "camera.fill",
                               title: store.lens.permissionDenied ? L("إذن الكاميرا مقفل", "Camera permission is off")
                                                                 : L("الكاميرا غير متوفرة", "Camera unavailable"),
                               message: L("تقدر تستخدم «مساعد الفلاش» من الأدوات وتفحص بعينك، أو فعّل الكاميرا من الإعدادات.",
                                           "Use the Flashlight helper from Tools and check by eye, or enable the camera in Settings."),
                               showSettings: store.lens.permissionDenied)
                    PrimaryButton(title: L("التالي · القائمة", "Next · checklist")) { path.append(ScanStep.checklist) }
                }.padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            store.lens.configure(from: store.catalog.thresholds)
            await store.lens.start()
        }
        .onDisappear { store.lens.stop() }
    }
}
