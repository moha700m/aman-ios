import SwiftUI

@main
struct AmanApp: App {
    @StateObject private var store = AmanStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
