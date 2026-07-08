import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = SupabaseManager.shared
    @State private var selectedTab = 0
    
    init() {
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
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
                .tag(0)
            
            ProfileView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Mi Perfil", systemImage: "person.fill")
                }
                .tag(1)
        }
        .tint(ForkarTheme.accent)
    }
}

#Preview {
    ContentView()
}
