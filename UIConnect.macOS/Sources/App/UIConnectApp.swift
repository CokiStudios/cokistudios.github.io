import SwiftUI
import AppKit

// MARK: - Native macOS App Entrypoint
@main
struct UIConnectApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("UI Connect") {
                Button("Escanear Dispositivos (ADB)") {
                    NotificationCenter.default.post(name: NSNotification.Name("ScanDevices"), object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Emitir Tono APU") {
                    SoundSynthesizer.shared.playApuChime()
                }
                .keyboardShortcut("t", modifiers: .command)

                Divider()

                Button("Silenciar / Reactivar Audio") {
                    SoundSynthesizer.shared.isMuted.toggle()
                }
                .keyboardShortcut("m", modifiers: .command)
            }
        }
    }
}

// MARK: - App Delegate for Window Styling
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let window = NSApp.windows.first {
            window.title = "✦ UI CONNECT (PC) — Shine OS Component 2 Manager ✦"
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(red: 11/255, green: 15/255, blue: 25/255, alpha: 1.0)
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
