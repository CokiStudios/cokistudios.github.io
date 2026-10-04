import SwiftUI
import AppKit

@main
struct hiOPApp: App {
    var body: some Scene {
        WindowGroup {
            hiOPWorkspaceView()
                .frame(minWidth: 1040, idealWidth: 1240, minHeight: 680, idealHeight: 820)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Nuevo archivo .loop") {
                    NotificationCenter.default.post(name: NSNotification.Name("NewLoopFile"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Guardar archivo") {
                    NotificationCenter.default.post(name: NSNotification.Name("SaveLoopCode"), object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
            }

            CommandMenu("Looping Core") {
                Button("Ejecutar código .loop (C++ Native)") {
                    NotificationCenter.default.post(name: NSNotification.Name("RunLoopCode"), object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
