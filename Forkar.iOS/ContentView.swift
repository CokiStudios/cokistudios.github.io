import SwiftUI
internal import Combine

struct ContentView: View {
    @StateObject private var authManager = SupabaseManager.shared
    @State private var selectedTab = 0
    @AppStorage("hasCompletedSetupWizard") private var hasCompletedSetupWizard: Bool = false
    @State private var showInitialSetupWizard: Bool = false
    
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
        .onAppear {
            if !hasCompletedSetupWizard {
                showInitialSetupWizard = true
            }
        }
        #if os(macOS)
        .sheet(isPresented: $showInitialSetupWizard) {
            SetupWizardView()
                .environmentObject(authManager)
                .frame(minWidth: 700, minHeight: 600)
        }
        #else
        .fullScreenCover(isPresented: $showInitialSetupWizard) {
            SetupWizardView()
                .environmentObject(authManager)
        }
        #endif
        .onOpenURL { url in
            handleDynamicIslandDeepLink(url)
        }
        .onReceive(QuickActionManager.shared.$actionType) { action in
            guard let action = action else { return }
            switch action {
            case "com.cokistudios.forkar.ecoscan":
                selectedTab = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenEcoQRScanner"), object: nil)
                }
            case "com.cokistudios.forkar.dynamicisland":
                selectedTab = 1
                let co2 = UserDefaults.standard.double(forKey: "forkar_co2_saved")
                let pts = UserDefaults.standard.integer(forKey: "forkar_eco_points")
                DynamicIslandEcoManager.shared.startEcoLiveActivity(
                    co2: co2 > 0 ? co2 : 8.5,
                    pts: pts > 0 ? pts : 150,
                    userName: authManager.currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "Usuario"
                )
            case "com.cokistudios.forkar.ecohub":
                selectedTab = 1
            default:
                break
            }
            QuickActionManager.shared.actionType = nil
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
            } else if url.host == "dynamicisland" {
                selectedTab = 1
                let co2 = UserDefaults.standard.double(forKey: "forkar_co2_saved")
                let pts = UserDefaults.standard.integer(forKey: "forkar_eco_points")
                DynamicIslandEcoManager.shared.startEcoLiveActivity(
                    co2: co2 > 0 ? co2 : 8.5,
                    pts: pts > 0 ? pts : 150,
                    userName: authManager.currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "Usuario"
                )
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
