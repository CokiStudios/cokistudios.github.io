import SwiftUI

@main
struct HoloAdventuresApp: App {
    var body: some Scene {
        WindowGroup {
            HoloGameView()
                .preferredColorScheme(.dark)
        }
    }
}
