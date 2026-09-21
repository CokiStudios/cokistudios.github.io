import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
#endif

@main
struct ForkarApp: App {
#if canImport(FirebaseCore)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
#endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

