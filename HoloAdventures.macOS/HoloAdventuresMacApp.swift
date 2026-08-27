import SwiftUI
import AppKit

@main
struct HoloAdventuresMacApp: App {
    var body: some Scene {
        WindowGroup {
            HoloMacGameContainerView()
                .frame(minWidth: 1024, minHeight: 640)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
