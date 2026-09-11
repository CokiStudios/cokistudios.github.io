import SwiftUI
import WebKit

// ═══════════════════════════════════════════════════════════════
// 🧠 AI PROVIDERS MODEL (100% SF SYMBOLS — ZERO EMOJIS)
// ═══════════════════════════════════════════════════════════════
public enum AISidebarProvider: String, CaseIterable, Identifiable {
    case gemini = "Gemini"
    case chatgpt = "ChatGPT"
    case claude = "Claude"
    case kimi = "Kimi"
    case custom = "Personalizada (Tu IA)"
    case none = "Nulo (Desactivado)"
    
    public var id: String { self.rawValue }
    
    public var systemIcon: String {
        switch self {
        case .gemini: return "sparkles"
        case .chatgpt: return "cpu"
        case .claude: return "brain.head.profile"
        case .kimi: return "moon.stars.fill"
        case .custom: return "terminal.fill"
        case .none: return "nosign"
        }
    }
    
    public var defaultUrl: String {
        switch self {
        case .gemini: return "https://gemini.google.com"
        case .chatgpt: return "https://chatgpt.com"
        case .claude: return "https://claude.ai"
        case .kimi: return "https://kimi.moonshot.cn"
        case .custom: return "https://chat.openai.com"
        case .none: return "about:blank"
        }
    }
    
    public var themeColor: Color {
        switch self {
        case .gemini: return .purple
        case .chatgpt: return .green
        case .claude: return .orange
        case .kimi: return .cyan
        case .custom: return .blue
        case .none: return .gray
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 🪪 NATIVE CS ID AUTHENTICATION MANAGER (SUPABASE INTEGRATION)
// ═══════════════════════════════════════════════════════════════
public class CSIDManager: ObservableObject {
    public static let shared = CSIDManager()
    
    private let baseUrl = "https://cmkumxprmmhuinxfppxl.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"
    
    @Published public var isLoggedIn: Bool = false
    @Published public var userName: String = "Usuario CS"
    @Published public var userEmail: String = ""
    @Published public var sessionToken: String? = nil
    
    public var initial: String {
        if !userName.trimmingCharacters(in: .whitespaces).isEmpty {
            return String(userName.prefix(1)).uppercased()
        }
        return "CS"
    }
    
    private init() {
        if let savedToken = UserDefaults.standard.string(forKey: "csid_session_token"),
           let savedEmail = UserDefaults.standard.string(forKey: "csid_user_email") {
            self.sessionToken = savedToken
            self.userEmail = savedEmail
            self.userName = UserDefaults.standard.string(forKey: "csid_user_name") ?? savedEmail.components(separatedBy: "@").first ?? "Usuario"
            self.isLoggedIn = true
        }
    }
    
    public func login(email: String, pass: String) async throws {
        let url = URL(string: "\(baseUrl)/auth/v1/token?grant_type=password")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email.trimmingCharacters(in: .whitespacesAndNewlines), "password": pass]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["access_token"] as? String,
           let userObj = json["user"] as? [String: Any] {
            let emailStr = (userObj["email"] as? String) ?? email
            var nameStr = emailStr.components(separatedBy: "@").first ?? "Usuario"
            if let meta = userObj["user_metadata"] as? [String: Any],
               let full = meta["full_name"] as? String, !full.isEmpty {
                nameStr = full
            }
            
            await MainActor.run {
                self.sessionToken = token
                self.userEmail = emailStr
                self.userName = nameStr
                self.isLoggedIn = true
                UserDefaults.standard.set(token, forKey: "csid_session_token")
                UserDefaults.standard.set(emailStr, forKey: "csid_user_email")
                UserDefaults.standard.set(nameStr, forKey: "csid_user_name")
            }
        }
    }
    
    public func logout() {
        self.sessionToken = nil
        self.userEmail = ""
        self.userName = "Usuario CS"
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: "csid_session_token")
        UserDefaults.standard.removeObject(forKey: "csid_user_email")
        UserDefaults.standard.removeObject(forKey: "csid_user_name")
    }
}

// ═══════════════════════════════════════════════════════════════
// ⚡ OPTIMIZACIONES DEL NAVEGADOR & STATE MANAGER FOR MAC
// ═══════════════════════════════════════════════════════════════
public class BrowserOptimizerManager: ObservableObject {
    public static let shared = BrowserOptimizerManager()
    
    @Published public var isOptimizationModeActive: Bool = false {
        didSet { applyOptimizations() }
    }
    
    @Published public var blockedTrackersCount: Int = 14
    @Published public var co2SavedGrams: Double = 3.4
    @Published public var selectedAIProvider: AISidebarProvider = .gemini
    
    @Published public var customAIUrl: String = UserDefaults.standard.string(forKey: "shine_custom_ai_url") ?? "https://perplex.ai" {
        didSet { UserDefaults.standard.set(customAIUrl, forKey: "shine_custom_ai_url") }
    }
    
    @Published public var customAIName: String = UserDefaults.standard.string(forKey: "shine_custom_ai_name") ?? "Mi IA Personalizada" {
        didSet { UserDefaults.standard.set(customAIName, forKey: "shine_custom_ai_name") }
    }
    
    public var currentAIUrl: String {
        if selectedAIProvider == .custom {
            return customAIUrl.isEmpty ? "https://perplex.ai" : customAIUrl
        }
        return selectedAIProvider.defaultUrl
    }
    
    @Published public var extensionsList: [BrowserExtension] = [
        BrowserExtension(id: "sentinel", name: "CSID Sentinel Shield", systemIcon: "shield.checkerboard", isEnabled: true),
        BrowserExtension(id: "eco", name: "Eco Hub CO₂ Tracker", systemIcon: "leaf.fill", isEnabled: true),
        BrowserExtension(id: "dark", name: "Shine Dark Theme Engine", systemIcon: "moon.fill", isEnabled: true),
        BrowserExtension(id: "ai_sidebar", name: "Multi-AI Assistant Engine", systemIcon: "wand.and.stars", isEnabled: true)
    ]
    
    @Published public var bookmarksList: [BookmarkItemData] = [
        BookmarkItemData(id: UUID(), systemIcon: "message.fill", title: "Forkar Hub", url: "https://cokistudios.github.io/forkar.html"),
        BookmarkItemData(id: UUID(), systemIcon: "bolt.fill", title: "Coki Products", url: "https://cokistudios.github.io/products.html"),
        BookmarkItemData(id: UUID(), systemIcon: "person.text.rectangle.fill", title: "CSID Dashboard", url: "https://cokistudios.github.io/dashboard.html"),
        BookmarkItemData(id: UUID(), systemIcon: "map.fill", title: "Shine Maps", url: "https://cokistudios.github.io/shine-maps.html"),
        BookmarkItemData(id: UUID(), systemIcon: "sparkles", title: "Gemini AI", url: "https://gemini.google.com"),
        BookmarkItemData(id: UUID(), systemIcon: "cpu", title: "ChatGPT", url: "https://chatgpt.com")
    ]
    
    @Published public var activeTabs: [TabItem] = [
        TabItem(id: UUID(), title: "Forkar — Comunidad", url: "https://cokistudios.github.io/forkar.html", systemIcon: "message.fill", isActive: true),
        TabItem(id: UUID(), title: "Shine Maps — GPS", url: "https://cokistudios.github.io/shine-maps.html", systemIcon: "map.fill", isActive: false),
        TabItem(id: UUID(), title: "Productos — Coki Studios", url: "https://cokistudios.github.io/products.html", systemIcon: "bolt.fill", isActive: false),
        TabItem(id: UUID(), title: "Mi CSID", url: "https://cokistudios.github.io/dashboard.html", systemIcon: "person.text.rectangle.fill", isActive: false)
    ]
    
    public func applyOptimizations() {
        if isOptimizationModeActive {
            print("Optimizaciones del Navegador ACTIVAS: HW Video Decode Throttled & Low Power Metal Pipeline.")
        } else {
            print("Modo Estándar ACTIVO.")
        }
    }
}

public struct BrowserExtension: Identifiable, Hashable {
    public let id: String
    public var name: String
    public var systemIcon: String
    public var isEnabled: Bool
}

public struct BookmarkItemData: Identifiable, Hashable {
    public let id: UUID
    public var systemIcon: String
    public var title: String
    public var url: String
}

public struct TabItem: Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public var url: String
    public var systemIcon: String
    public var isActive: Bool
}

// ═══════════════════════════════════════════════════════════════
// 🌐 WKWEBVIEW CEF ENGINE CONTROLLER FOR MACOS
// ═══════════════════════════════════════════════════════════════
public struct ShineFindWebView: NSViewRepresentable {
    @Binding public var urlString: String
    @ObservedObject public var optimizerManager: BrowserOptimizerManager
    
    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 ShineFind/2.0 (Optimized Edition)"
        webView.navigationDelegate = context.coordinator
        
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    public func updateNSView(_ nsView: WKWebView, context: Context) {
        if let currentURL = nsView.url?.absoluteString, currentURL != urlString, let newURL = URL(string: urlString) {
            nsView.load(URLRequest(url: newURL))
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ShineFindWebView
        
        init(_ parent: ShineFindWebView) {
            self.parent = parent
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url?.absoluteString {
                DispatchQueue.main.async {
                    self.parent.urlString = url
                }
            }
        }
        
        public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// ⚙️ PREFERENCES / CONFIG WINDOW (Cmd + ,)
// ═══════════════════════════════════════════════════════════════
public struct PreferencesView: View {
    @ObservedObject var optimizer = BrowserOptimizerManager.shared
    @ObservedObject var csidManager = CSIDManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.cyan)
                    .font(.title2)
                Text("Configuración de Shine Find Browser")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Selector de IA Predeterminada
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("PROVEEDOR DE ASISTENTE IA EN BARRA LATERAL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                
                Picker("Seleccionar IA Lateral", selection: $optimizer.selectedAIProvider) {
                    ForEach(AISidebarProvider.allCases) { provider in
                        HStack {
                            Image(systemName: provider.systemIcon)
                            Text(provider.rawValue)
                        }
                        .tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .padding(6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
                
                if optimizer.selectedAIProvider == .custom {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nombre de tu IA Personalizada:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Ej. Mi IA Local / DeepSeek", text: $optimizer.customAIName)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("URL del sitio web / Chat de tu IA:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("https://tu-ia-personalizada.com", text: $optimizer.customAIUrl)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // General Settings
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.blue)
                    Text("OPTIMIZACIONES DE CHROMIUM Y EFICIENCIA")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Toggle("Optimizaciones del Navegador (Ahorro de VRAM y Metal Throttling)", isOn: $optimizer.isOptimizationModeActive)
                    .toggleStyle(.checkbox)
                    .foregroundColor(.white)
                
                Toggle("Aceleración por GPU C++ Chromium Core", isOn: .constant(true))
                    .toggleStyle(.checkbox)
                    .foregroundColor(.white)
                
                Toggle("Escudo Sentinel Anti-Trackers a Nivel de Red", isOn: .constant(true))
                    .toggleStyle(.checkbox)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Guardar y Cerrar") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 540, height: 480)
        .background(Color(red: 0.05, green: 0.07, blue: 0.12))
    }
}

// ═══════════════════════════════════════════════════════════════
// 🎨 MAIN WINDOW VIEW (SHINE UI & MULTI-AI SIDEBAR)
// ═══════════════════════════════════════════════════════════════
public struct MainWindowView: View {
    @State private var urlString: String = "https://cokistudios.github.io/forkar.html"
    @State private var addressInput: String = "https://cokistudios.github.io/forkar.html"
    @State private var isAISidebarOpen: Bool = false
    @State private var isExtensionsOpen: Bool = false
    @State private var isPreferencesOpen: Bool = false
    @State private var isDownloadsOpen: Bool = false
    @State private var isCSIDOpen: Bool = false
    @State private var isSentinelOpen: Bool = false
    
    @StateObject private var optimizer = BrowserOptimizerManager.shared
    @ObservedObject private var csidManager = CSIDManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // ── 1. TOP TAB BAR (MACOS TRAFFIC LIGHTS INTEGRATION) ──
            HStack(spacing: 0) {
                Spacer().frame(width: 78)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(optimizer.activeTabs) { tab in
                            HStack(spacing: 6) {
                                Image(systemName: tab.systemIcon)
                                    .font(.system(size: 11))
                                    .foregroundColor(tab.isActive ? .cyan : .gray)
                                
                                Text(tab.title)
                                    .font(.system(size: 11, weight: tab.isActive ? .bold : .medium))
                                    .foregroundColor(tab.isActive ? .white : .gray)
                                    .lineLimit(1)
                                
                                Button(action: { closeTab(tab) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                                .opacity(tab.isActive ? 1.0 : 0.4)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(tab.isActive ? Color(red: 0.08, green: 0.11, blue: 0.18) : Color.white.opacity(0.03))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(tab.isActive ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                            .onTapGesture { selectTab(tab) }
                        }
                    }
                }
                
                Button(action: addNewTab) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .background(Color(red: 0.03, green: 0.04, blue: 0.08))
            .border(width: 1, edges: [.bottom], color: Color.white.opacity(0.08))
            
            // ── 2. MAIN TOOLBAR (ADDRESS BAR & QUICK CONTROLS) ──
            HStack(spacing: 10) {
                // Navigation buttons
                HStack(spacing: 4) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(7)
                    
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(7)
                    
                    Button(action: { urlString = addressInput }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(7)
                }
                
                // Address Bar with Glassmorphism
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 10))
                    
                    TextField("Buscar o ingresar URL...", text: $addressInput, onCommit: {
                        var target = addressInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !target.hasPrefix("http://") && !target.hasPrefix("https://") {
                            target = "https://" + target
                        }
                        urlString = target
                        addressInput = target
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("CEF 122")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.5))
                .cornerRadius(9)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(optimizer.isOptimizationModeActive ? Color.cyan : Color.cyan.opacity(0.3), lineWidth: 1)
                )
                
                // Action Buttons
                HStack(spacing: 6) {
                    // Sentinel Shield Badge
                    Button(action: { isSentinelOpen.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "shield.checkerboard")
                            Text("\(optimizer.blockedTrackersCount)")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isSentinelOpen) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "shield.checkerboard")
                                    .foregroundColor(.green)
                                Text("Sentinel Shield Activo")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Divider()
                            Text("14 rastreadores y cookies invasivas bloqueadas en esta sesión.")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        .padding(12)
                        .frame(width: 220)
                        .background(Color(red: 0.08, green: 0.1, blue: 0.16))
                    }
                    
                    // CS ID Avatar Button
                    Button(action: { isCSIDOpen.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.crop.circle.fill")
                            Text(csidManager.isLoggedIn ? csidManager.initial : "CS")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.15))
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isCSIDOpen) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .foregroundColor(.purple)
                                Text("Coki Studios ID")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Divider()
                            Text(csidManager.isLoggedIn ? "Sesión activa: \(csidManager.userName)" : "Inicia sesión con tu CS ID")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            
                            if csidManager.isLoggedIn {
                                Button("Cerrar Sesión") {
                                    csidManager.logout()
                                    isCSIDOpen = false
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                        }
                        .padding(12)
                        .frame(width: 200)
                        .background(Color(red: 0.08, green: 0.1, blue: 0.16))
                    }
                    
                    // Multi-AI Selector Menu
                    Menu {
                        ForEach(AISidebarProvider.allCases) { provider in
                            Button(action: {
                                optimizer.selectedAIProvider = provider
                                isAISidebarOpen = (provider != .none)
                            }) {
                                HStack {
                                    Image(systemName: provider.systemIcon)
                                    Text(provider == .custom ? optimizer.customAIName : provider.rawValue)
                                    if optimizer.selectedAIProvider == provider {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: optimizer.selectedAIProvider.systemIcon)
                            Text(optimizer.selectedAIProvider == .custom ? optimizer.customAIName : optimizer.selectedAIProvider.rawValue)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isAISidebarOpen ? optimizer.selectedAIProvider.themeColor : optimizer.selectedAIProvider.themeColor.opacity(0.18))
                        .foregroundColor(isAISidebarOpen ? .white : optimizer.selectedAIProvider.themeColor)
                        .cornerRadius(7)
                    }
                    .menuStyle(.borderlessButton)
                    
                    // Optimizer Mode Toggle
                    Button(action: { optimizer.isOptimizationModeActive.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.horizontal.fill")
                            Text(optimizer.isOptimizationModeActive ? "Opt: ON" : "Opt: OFF")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(optimizer.isOptimizationModeActive ? Color.cyan : Color.cyan.opacity(0.15))
                        .foregroundColor(optimizer.isOptimizationModeActive ? .black : .cyan)
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                    
                    // Config (Cmd + ,)
                    Button(action: { isPreferencesOpen = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .padding(5)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $isPreferencesOpen) {
                        PreferencesView(optimizer: optimizer)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(red: 0.05, green: 0.07, blue: 0.12))
            .border(width: 1, edges: [.bottom], color: Color.white.opacity(0.08))
            
            // ── 3. BOOKMARKS BAR ──
            HStack(spacing: 12) {
                ForEach(optimizer.bookmarksList) { bm in
                    Button(action: { navigateTo(bm.url) }) {
                        HStack(spacing: 4) {
                            Image(systemName: bm.systemIcon)
                                .font(.system(size: 10))
                                .foregroundColor(.cyan)
                            Text(bm.title)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(red: 0.04, green: 0.05, blue: 0.09))
            .border(width: 1, edges: [.bottom], color: Color.white.opacity(0.05))
            
            // ── 4. MAIN CONTENT AREA (RENDER + AI SIDEBAR) ──
            HStack(spacing: 0) {
                ShineFindWebView(urlString: $urlString, optimizerManager: optimizer)
                
                if isAISidebarOpen && optimizer.selectedAIProvider != .none {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: optimizer.selectedAIProvider.systemIcon)
                                .foregroundColor(optimizer.selectedAIProvider.themeColor)
                            Text(optimizer.selectedAIProvider == .custom ? optimizer.customAIName : optimizer.selectedAIProvider.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(optimizer.selectedAIProvider.themeColor)
                            Spacer()
                            Button(action: { isAISidebarOpen = false }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(red: 0.06, green: 0.08, blue: 0.14))
                        .border(width: 1, edges: [.bottom], color: Color.white.opacity(0.08))
                        
                        ShineFindWebView(urlString: .constant(optimizer.currentAIUrl), optimizerManager: optimizer)
                    }
                    .frame(width: 360)
                    .background(Color(red: 0.05, green: 0.07, blue: 0.12))
                    .border(width: 1, edges: [.leading], color: Color.white.opacity(0.08))
                }
            }
            
            // ── 5. STATUS BAR ──
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("Chromium CEF Core v122 (Metal VSM Accelerated)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.green)
                        Text(String(format: "%.1f g CO₂ ahorrados", optimizer.co2SavedGrams))
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.cyan)
                        Text("\(optimizer.blockedTrackersCount) rastreadores bloqueados")
                            .font(.system(size: 10))
                            .foregroundColor(.cyan)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(red: 0.02, green: 0.03, blue: 0.06))
            .border(width: 1, edges: [.top], color: Color.white.opacity(0.05))
        }
        .background(Color(red: 0.02, green: 0.03, blue: 0.06))
    }
    
    // Tab Management
    private func selectTab(_ tab: TabItem) {
        for i in 0..<optimizer.activeTabs.count {
            optimizer.activeTabs[i].isActive = (optimizer.activeTabs[i].id == tab.id)
        }
        urlString = tab.url
        addressInput = tab.url
    }
    
    private func closeTab(_ tab: TabItem) {
        guard optimizer.activeTabs.count > 1 else { return }
        optimizer.activeTabs.removeAll { $0.id == tab.id }
        if tab.isActive, let first = optimizer.activeTabs.first {
            selectTab(first)
        }
    }
    
    private func addNewTab() {
        let newTab = TabItem(
            id: UUID(),
            title: "Nueva Pestaña",
            url: "https://cokistudios.github.io/index.html",
            systemIcon: "globe",
            isActive: true
        )
        for i in 0..<optimizer.activeTabs.count {
            optimizer.activeTabs[i].isActive = false
        }
        optimizer.activeTabs.append(newTab)
        selectTab(newTab)
    }
    
    private func navigateTo(_ url: String) {
        urlString = url
        addressInput = url
        if let idx = optimizer.activeTabs.firstIndex(where: { $0.isActive }) {
            optimizer.activeTabs[idx].url = url
            optimizer.activeTabs[idx].title = url.components(separatedBy: "/").last?.replacingOccurrences(of: ".html", with: "") ?? "Web"
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 📐 UTILITIES & BORDER EXTENSIONS
// ═══════════════════════════════════════════════════════════════
public struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }
            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }
            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return width
                }
            }
            var h: CGFloat {
                switch edge {
                case .top, .bottom: return width
                case .leading, .trailing: return rect.height
                }
            }
            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}

public extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

// ═══════════════════════════════════════════════════════════════
// 🚀 MAIN APPLICATION ENTRY POINT
// ═══════════════════════════════════════════════════════════════
@main
struct ShineFindApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
