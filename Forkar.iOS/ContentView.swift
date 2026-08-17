import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = SupabaseManager.shared
    @State private var selectedTab = 0
    
    init() {
        #if os(iOS)
        // Customize UITabBar appearance for a modern premium dark feel
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ForkarTheme.bg)
        
        // Active item color (Indigo)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(ForkarTheme.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(ForkarTheme.accent)]
        
        // Inactive item color (Gray)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(ForkarTheme.textSub)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(ForkarTheme.textSub)]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
                .tag(0)
            
            ForkarEcoView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Eco Hub", systemImage: "leaf.fill")
                }
                .tag(1)
            
            ChatsView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(2)
            
            ProfileView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Mi Perfil", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(ForkarTheme.accent)
        .onOpenURL { url in
            handleDynamicIslandDeepLink(url)
        }
    }
    
    private func handleDynamicIslandDeepLink(_ url: URL) {
        if url.scheme == "forkar" {
            if url.host == "ecoscan" {
                // 1 Click en Dynamic Island -> Cambiar a Eco Hub y abrir escáner QR
                selectedTab = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenEcoQRScanner"), object: nil)
                }
            } else if url.host == "app" {
                // 2 Clicks / Click en Abrir Forkar -> Abrir vista principal
                selectedTab = 0
            }
        }
    }
}

#Preview {
    ContentView()
}
