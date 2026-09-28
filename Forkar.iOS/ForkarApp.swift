import SwiftUI
internal import Combine

#if canImport(FirebaseCore)
import FirebaseCore
#endif

// MARK: - Gestor de Acciones Rápidas (Long Press en icono de App)
class QuickActionManager: ObservableObject {
    static let shared = QuickActionManager()
    @Published var actionType: String? = nil
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
    }
}
#else
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
        
        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            QuickActionManager.shared.actionType = shortcutItem.type
        }
        return true
    }
}
#endif

@main
struct ForkarApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #else
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1080, height: 720)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}
