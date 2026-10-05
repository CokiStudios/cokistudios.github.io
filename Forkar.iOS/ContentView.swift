import SwiftUI
internal import Combine

// MARK: - Navigation Items
enum NavigationItem: String, CaseIterable, Identifiable {
    case home = "Inicio"
    case eco = "Eco Hub"
    case chats = "Chats"
    case profile = "Mi Perfil"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .eco: return "leaf.fill"
        case .chats: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }
    
    var tag: Int {
        switch self {
        case .home: return 0
        case .eco: return 1
        case .chats: return 2
        case .profile: return 3
        }
    }
    
    static func from(tag: Int) -> NavigationItem {
        switch tag {
        case 1: return .eco
        case 2: return .chats
        case 3: return .profile
        default: return .home
        }
    }
}

// MARK: - Universal Content View
struct ContentView: View {
    @StateObject private var authManager = SupabaseManager.shared
    @State private var selectedTab = 0
    @State private var selectedItem: NavigationItem? = .home
    @AppStorage("hasCompletedSetupWizard") private var hasCompletedSetupWizard: Bool = false
    @State private var showInitialSetupWizard: Bool = false
    
    init() {
        #if os(iOS)
        // Customize UITabBar appearance for a modern premium dark feel on iPhone
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
    
    #if os(macOS)
    var body: some View {
        macOSSplitLayout
            .environmentObject(authManager)
            .frame(minWidth: 920, minHeight: 620)
            .tint(ForkarTheme.accent)
            .onAppear {
                if !hasCompletedSetupWizard {
                    showInitialSetupWizard = true
                }
            }
            .sheet(isPresented: $showInitialSetupWizard) {
                SetupWizardView()
                    .environmentObject(authManager)
                    .frame(minWidth: 720, minHeight: 620)
            }
            .onOpenURL { url in
                handleDynamicIslandDeepLink(url)
            }
            .onReceive(QuickActionManager.shared.$actionType) { action in
                handleQuickAction(action)
            }
    }
    #else
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var duoManager = ForkarDuoManager.shared
    
    var body: some View {
        GeometryReader { windowProxy in
            Group {
                if duoManager.currentPosture == .partiallyFolded {
                    duoFoldedArrangementLayout
                } else if horizontalSizeClass == .regular || duoManager.displayMode == .innerFoldingCanvas {
                    macOSSplitLayout
                } else {
                    iOSTabLayout
                }
            }
            .onAppear {
                duoManager.updateMetrics(size: windowProxy.size, safeAreaInsets: windowProxy.safeAreaInsets)
            }
            .onChange(of: windowProxy.size) { newSize in
                duoManager.updateMetrics(size: newSize, safeAreaInsets: windowProxy.safeAreaInsets)
            }
        }
        .environmentObject(authManager)
        .environmentObject(duoManager)
        .tint(ForkarTheme.accent)
        .onAppear {
            if !hasCompletedSetupWizard {
                showInitialSetupWizard = true
            }
        }
        .fullScreenCover(isPresented: $showInitialSetupWizard) {
            SetupWizardView()
                .environmentObject(authManager)
        }
        .onOpenURL { url in
            handleDynamicIslandDeepLink(url)
        }
        .onReceive(QuickActionManager.shared.$actionType) { action in
            handleQuickAction(action)
        }
    }
    
    // MARK: - iPhone Duo Folded / Laptop Posture Layout (Apple developer.apple.com/iphone-duo)
    private var duoFoldedArrangementLayout: some View {
        ForkarDuoArrangementView(style: .split) {
            ZStack {
                ForkarTheme.bg.ignoresSafeArea()
                
                switch selectedItem ?? .home {
                case .home:
                    HomeView()
                        .environmentObject(authManager)
                case .eco:
                    ForkarEcoView()
                        .environmentObject(authManager)
                case .chats:
                    ChatsView()
                        .environmentObject(authManager)
                case .profile:
                    ProfileView()
                        .environmentObject(authManager)
                }
            }
        } secondary: {
            DuoControlDeckView(
                selectedItem: $selectedItem,
                selectedTab: $selectedTab,
                authManager: authManager
            )
        }
    }
    #endif
    
    // MARK: - Desktop / Tablet Split View Layout (macOS, iPad, iPhone Duo unfolded)
    private var macOSSplitLayout: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // App Branding Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(ForkarTheme.primaryGradient)
                            .frame(width: 32, height: 32)
                            .shadow(color: ForkarTheme.accent.opacity(0.4), radius: 6)
                        
                        Text("F")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Forkar")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.emerald)
                                .frame(width: 6, height: 6)
                            Text("Universal")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.emerald)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider().background(ForkarTheme.border.opacity(0.5))
                
                // Sidebar Navigation List
                List(selection: $selectedItem) {
                    Section {
                        ForEach(NavigationItem.allCases) { item in
                            NavigationLink(value: item) {
                                HStack(spacing: 10) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 15))
                                        .foregroundColor(selectedItem == item ? ForkarTheme.accent : ForkarTheme.textSub)
                                        .frame(width: 22)
                                    
                                    Text(item.rawValue)
                                        .font(.system(size: 13, weight: selectedItem == item ? .bold : .medium))
                                        .foregroundColor(selectedItem == item ? ForkarTheme.text : ForkarTheme.textSub)
                                    
                                    Spacer()
                                    
                                    if item == .eco {
                                        let pts = UserDefaults.standard.integer(forKey: "forkar_eco_points")
                                        if pts > 0 {
                                            Text("\(pts) pts")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(Color.emerald)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.emerald.opacity(0.15))
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .tag(item)
                        }
                    } header: {
                        Text("MENU")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(ForkarTheme.textSub.opacity(0.7))
                            .tracking(1.2)
                    }
                }
                .listStyle(.sidebar)
                
                Spacer()
                
                Divider().background(ForkarTheme.border.opacity(0.5))
                
                // Sidebar User Profile Footer
                if let user = authManager.currentUser {
                    HStack(spacing: 10) {
                        CircleAvatarPlaceholder(initials: user.initials)
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.resolvedName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ForkarTheme.text)
                                .lineLimit(1)
                            
                            Text(user.email ?? "")
                                .font(.system(size: 10))
                                .foregroundColor(ForkarTheme.textSub)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(ForkarTheme.card.opacity(0.4))
                }
            }
            .background(ForkarTheme.bg)
            .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 270)
        } detail: {
            ZStack {
                ForkarTheme.bg.ignoresSafeArea()
                
                switch selectedItem ?? .home {
                case .home:
                    HomeView()
                        .environmentObject(authManager)
                case .eco:
                    ForkarEcoView()
                        .environmentObject(authManager)
                case .chats:
                    ChatsView()
                        .environmentObject(authManager)
                case .profile:
                    ProfileView()
                        .environmentObject(authManager)
                }
            }
        }
    }
    
    // MARK: - Mobile Tab Layout (iPhone Portrait)
    private var iOSTabLayout: some View {
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
        .onChange(of: selectedTab) { newTag in
            selectedItem = NavigationItem.from(tag: newTag)
        }
        .onChange(of: selectedItem) { newItem in
            if let newItem = newItem, selectedTab != newItem.tag {
                selectedTab = newItem.tag
            }
        }
    }
    
    // MARK: - Dynamic Island & Quick Actions Handling
    private func handleQuickAction(_ action: String?) {
        guard let action = action else { return }
        switch action {
        case "com.cokistudios.forkar.ecoscan":
            selectedTab = 1
            selectedItem = .eco
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: NSNotification.Name("OpenEcoQRScanner"), object: nil)
            }
        case "com.cokistudios.forkar.dynamicisland":
            selectedTab = 1
            selectedItem = .eco
            let co2 = UserDefaults.standard.double(forKey: "forkar_co2_saved")
            let pts = UserDefaults.standard.integer(forKey: "forkar_eco_points")
            DynamicIslandEcoManager.shared.startEcoLiveActivity(
                co2: co2,
                pts: pts,
                userName: authManager.currentUser?.resolvedName ?? "CS Member"
            )
        case "com.cokistudios.forkar.ecohub":
            selectedTab = 1
            selectedItem = .eco
        default:
            break
        }
        QuickActionManager.shared.actionType = nil
    }
    
    private func handleDynamicIslandDeepLink(_ url: URL) {
        if url.scheme == "forkar" {
            if url.host == "ecoscan" {
                selectedTab = 1
                selectedItem = .eco
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenEcoQRScanner"), object: nil)
                }
            } else if url.host == "dynamicisland" {
                selectedTab = 1
                selectedItem = .eco
                let co2 = UserDefaults.standard.double(forKey: "forkar_co2_saved")
                let pts = UserDefaults.standard.integer(forKey: "forkar_eco_points")
                DynamicIslandEcoManager.shared.startEcoLiveActivity(
                    co2: co2,
                    pts: pts,
                    userName: authManager.currentUser?.resolvedName ?? "CS Member"
                )
            } else if url.host == "app" {
                selectedTab = 0
                selectedItem = .home
            }
        }
    }
}

#Preview {
    ContentView()
}
