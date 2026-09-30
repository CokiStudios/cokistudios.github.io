import SwiftUI

@main
struct CSIMSApp: App {
    @StateObject private var manager = SupabaseManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                #if os(macOS)
                .frame(minWidth: 840, minHeight: 600)
                #endif
        }
    }
}
