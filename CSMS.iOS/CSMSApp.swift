import SwiftUI

@main
struct CSMSApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabaseManager)
        }
    }
}
