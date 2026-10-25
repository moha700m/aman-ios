import SwiftUI

@main
struct AmanApp: App {
    @StateObject private var store = AmanStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .amanLayout(store.lang)
                .id(store.lang) // force full tree refresh on language switch
                .preferredColorScheme(.light)
        }
    }
}
