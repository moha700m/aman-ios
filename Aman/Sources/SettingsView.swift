import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AmanStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AmanTheme.sand.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text(L("اللغة", "Language"))
                        .font(.headline)
                        .foregroundStyle(AmanTheme.ink)

                    Picker("", selection: Binding(
                        get: { store.lang },
                        set: { store.setLanguage($0) }
                    )) {
                        ForEach(AppLang.allCases) { lang in
                            Text(lang.title).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(L("العربية هي الافتراضية. تقدر تبدّل لإنجليزي بأي وقت، ويتغير فورًا.",
                             "Arabic is the default. You can switch to English anytime; it applies immediately."))
                        .font(.footnote)
                        .foregroundStyle(AmanTheme.ink.opacity(0.6))

                    Divider().padding(.vertical, 4)

                    Text(L("عن التطبيق", "About"))
                        .font(.headline)
                        .foregroundStyle(AmanTheme.ink)
                    Text(L("فحص مساعد للشاليه والفندق: مغناطيس، بلوتوث، لمعة عدسة، وقائمة غرف. ما يضمن كشف كل الأجهزة.",
                             "Helper check for chalets and hotels: magnetometer, Bluetooth, lens glint, and room lists. Does not guarantee detecting every device."))
                        .font(.footnote)
                        .foregroundStyle(AmanTheme.ink.opacity(0.65))

                    DisclaimerBanner()
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(L("الإعدادات", "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("تم", "Done")) { dismiss() }
                }
            }
        }
        .amanLayout(store.lang)
    }
}
