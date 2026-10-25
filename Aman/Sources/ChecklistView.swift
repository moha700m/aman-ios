import SwiftUI

struct ChecklistView: View {
    @EnvironmentObject var store: AmanStore
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            AmanTheme.sand.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text(L("قائمة الغرفة", "Room checklist"))
                    .font(.title2.weight(.bold)).foregroundStyle(AmanTheme.ink)

                Picker("", selection: $store.checklistId) {
                    ForEach(store.catalog.checklists) { c in
                        Text(c.title).tag(c.id)
                    }
                }
                .pickerStyle(.segmented)

                if let list = store.catalog.checklists.first(where: { $0.id == store.checklistId }) {
                    VStack(spacing: 0) {
                        ForEach(list.items) { item in
                            Button {
                                if store.checked.contains(item.id) { store.checked.remove(item.id) }
                                else { store.checked.insert(item.id) }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: store.checked.contains(item.id) ? "checkmark.square.fill" : "square")
                                        .foregroundStyle(store.checked.contains(item.id) ? AmanTheme.green : AmanTheme.ink.opacity(0.35))
                                        .font(.title3)
                                    Text(item.title)
                                        .foregroundStyle(AmanTheme.ink)
                                        .strikethrough(store.checked.contains(item.id))
                                        .opacity(store.checked.contains(item.id) ? 0.45 : 1)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                            }
                            Divider()
                        }
                    }
                    .padding(.horizontal, 14)
                    .softCard()
                }

                if let tip = store.catalog.tips.randomElement() {
                    Text(tip.text)
                        .font(.footnote)
                        .foregroundStyle(AmanTheme.ink.opacity(0.6))
                        .padding(12)
                        .softCard(14)
                }

                Spacer()
                PrimaryButton(title: L("عرض النتيجة", "Show result")) {
                    _ = store.buildSummary()
                    path.append(ScanStep.result)
                }
                DisclaimerBanner()
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
