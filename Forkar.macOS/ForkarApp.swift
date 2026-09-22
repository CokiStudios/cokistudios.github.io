import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 🚗 FORKAR FOR PC — NATIVE MACOS DESKTOP APPLICATION
// Cliente nativo en SwiftUI con Extensión CSMS, Eco Hub y OAuth
// ══════════════════════════════════════════════════════════════════

@main
struct ForkarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager = SupabaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            ForkarDesktopRootView()
                .environmentObject(manager)
                .frame(minWidth: 980, minHeight: 650)
                .background(ForkarTheme.bg)
                .onOpenURL { url in
                    if url.scheme == "forkar" && url.host == "oauth" {
                        Task {
                            try? await manager.handleOAuthCallback(url: url)
                        }
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("Nueva Publicación") {
                    NotificationCenter.default.post(name: NSNotification.Name("ForkarNewPost"), object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("Abrir Extensión CSMS") {
                    NotificationCenter.default.post(name: NSNotification.Name("ForkarOpenCSMS"), object: nil)
                }
                .keyboardShortcut("2", modifiers: [.command])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        setenv("OS_ACTIVITY_MODE", "disable", 1)
        UserDefaults.standard.set(false, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "forkar" {
                Task {
                    try? await SupabaseManager.shared.handleOAuthCallback(url: url)
                }
            }
        }
    }
}
