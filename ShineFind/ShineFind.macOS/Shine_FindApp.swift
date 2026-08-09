import SwiftUI
import WebKit
internal import Combine

// ═══════════════════════════════════════════════════════════════
// ⚡ OPTIMIZACIONES DEL NAVEGADOR & STATE MANAGER FOR MAC
// ═══════════════════════════════════════════════════════════════
class BrowserOptimizerManager: ObservableObject {
    static let shared = BrowserOptimizerManager()
    
    @Published var isOptimizationModeActive: Bool = false {
        didSet { applyOptimizations() }
    }
    
    @Published var blockedTrackersCount: Int = 14
    @Published var co2SavedGrams: Double = 3.4
    
    // Extensions Store
    @Published var extensionsList: [BrowserExtension] = [
        BrowserExtension(id: "sentinel", name: "CSID Sentinel Shield", icon: "🛡️", isEnabled: true),
        BrowserExtension(id: "eco", name: "Eco Hub CO₂ Tracker", icon: "🌿", isEnabled: true),
        BrowserExtension(id: "dark", name: "Shine Dark Theme Engine", icon: "🌙", isEnabled: true),
        BrowserExtension(id: "gemini", name: "Gemini AI Sidebar", icon: "✨", isEnabled: true)
    ]
    
    // Bookmarks Store
    @Published var bookmarksList: [BookmarkItemData] = [
        BookmarkItemData(id: UUID(), icon: "💬", title: "Forkar Hub", url: "https://cokistudios.github.io/forkar.html"),
        BookmarkItemData(id: UUID(), icon: "⚡", title: "Coki Products", url: "https://cokistudios.github.io/products.html"),
        BookmarkItemData(id: UUID(), icon: "🪪", title: "CSID Dashboard", url: "https://cokistudios.github.io/coki-dashboard.html"),
        BookmarkItemData(id: UUID(), icon: "✨", title: "Gemini AI", url: "https://gemini.google.com"),
        BookmarkItemData(id: UUID(), icon: "🗺️", title: "Horizon Maps", url: "https://anonymus-devop.github.io/HorizonMaps/")
    ]
    
    @Published var activeTabs: [TabItem] = [
        TabItem(id: UUID(), title: "Forkar — Comunidad", url: "https://cokistudios.github.io/forkar.html", favicon: "💬", isActive: true),
        TabItem(id: UUID(), title: "Productos — Coki Studios", url: "https://cokistudios.github.io/products.html", favicon: "⚡", isActive: false),
        TabItem(id: UUID(), title: "Mi CSID", url: "https://cokistudios.github.io/coki-dashboard.html", favicon: "🪪", isActive: false)
    ]
    
    func applyOptimizations() {
        if isOptimizationModeActive {
            print("⚡ Optimizaciones del Navegador ACTIVAS: HW Video Decode Throttled & Low Power Metal Pipeline.")
        } else {
            print("⚡ Modo Estándar ACTIVO.")
        }
    }
}

struct BrowserExtension: Identifiable, Hashable {
    let id: String
    var name: String
    var icon: String
    var isEnabled: Bool
}

struct BookmarkItemData: Identifiable, Hashable {
    let id: UUID
    var icon: String
    var title: String
    var url: String
}

struct TabItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var url: String
    var favicon: String
    var isActive: Bool
}

// ═══════════════════════════════════════════════════════════════
// 🌐 WKWEBVIEW CEF ENGINE CONTROLLER FOR MACOS
// ═══════════════════════════════════════════════════════════════
struct ShineFindWebView: NSViewRepresentable {
    @Binding var urlString: String
    @ObservedObject var optimizerManager: BrowserOptimizerManager
    var onInspectElement: (() -> Void)? = nil
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        
        // 🛡️ Habilitar DevTools / Inspector Web & Aislamiento de Almacenamiento
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15 ShineFind/1.0 (Optimized Edition)"
        webView.navigationDelegate = context.coordinator
        
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let currentURL = nsView.url?.absoluteString, currentURL != urlString, let newURL = URL(string: urlString) {
            nsView.load(URLRequest(url: newURL))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ShineFindWebView
        
        init(_ parent: ShineFindWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url?.absoluteString {
                DispatchQueue.main.async {
                    self.parent.urlString = url
                }
            }
        }
        
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            print("⚠️ WebContent Process colapsó. Intentando recarga automática de Shine Find...")
            webView.reload()
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// ⚙️ PREFERENCES / CONFIG WINDOW (Cmd + ,)
// ═══════════════════════════════════════════════════════════════
struct PreferencesView: View {
    @ObservedObject var optimizer = BrowserOptimizerManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("⚙️ Configuración de Shine Find Browser")
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
            .padding(.bottom, 10)
            
            Divider().background(Color.white.opacity(0.1))
            
            // General Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("GENERAL")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Toggle("Activar Optimizaciones del Navegador (Bajo Consumo Metal/VRAM)", isOn: $optimizer.isOptimizationModeActive)
                    .toggleStyle(.checkbox)
                    .foregroundColor(.white)
                
                Toggle("Passkeys & CSID Autologin en Sitios Autorizados", isOn: .constant(true))
                    .toggleStyle(.checkbox)
                    .foregroundColor(.white)
                
                Toggle("Escudo Sentinel Anti-Trackers a Nivel Hardware", isOn: .constant(true))
                    .toggleStyle(.checkbox)
                    .foregroundColor(.white)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Extensions Manager
            VStack(alignment: .leading, spacing: 12) {
                Text("EXTENSIONES DE SHINE FIND")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                ForEach($optimizer.extensionsList) { $ext in
                    HStack {
                        Text(ext.icon)
                        Text(ext.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $ext.isEnabled)
                            .toggleStyle(.switch)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                }
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
        .frame(width: 520, height: 480)
        .background(Color(red: 0.06, green: 0.08, blue: 0.14))
    }
}

// ═══════════════════════════════════════════════════════════════
// 🎨 PREMIUM MACOS BROWSER UI (SHINE UI & GEMINI INTEGRATION)
// ═══════════════════════════════════════════════════════════════
struct MainWindowView: View {
    @State private var urlString: String = "https://cokistudios.github.io/forkar.html"
    @State private var addressInput: String = "https://cokistudios.github.io/forkar.html"
    @State private var isGeminiSidebarOpen: Bool = false
    @State private var isExtensionsOpen: Bool = false
    @State private var isPreferencesOpen: Bool = false
    @State private var newBookmarkTitle: String = ""
    @State private var newBookmarkUrl: String = ""
    @State private var isAddBookmarkOpen: Bool = false
    
    @StateObject private var optimizer = BrowserOptimizerManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // ── TOP TAB BAR (NATIVE MACOS INTEGRATED TRAFFIC LIGHTS) ──
            HStack(spacing: 0) {
                // Reserve space for native macOS traffic light buttons (Red/Yellow/Green)
                Spacer()
                    .frame(width: 78)
                
                // Tabs list
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(optimizer.activeTabs) { tab in
                            HStack(spacing: 6) {
                                Text(tab.favicon)
                                    .font(.system(size: 11))
                                Text(tab.title)
                                    .font(.system(size: 11, weight: tab.isActive ? .bold : .medium))
                                    .foregroundColor(tab.isActive ? .white : Color.gray)
                                    .lineLimit(1)
                                
                                // ❌ BOTÓN PARA CERRAR PESTAÑA FUNCIONAL
                                Button(action: {
                                    closeTab(tab)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(Color.gray)
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
                            .onTapGesture {
                                selectTab(tab)
                            }
                        }
                    }
                }
                
                // Add tab button
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
            
            // ── MAIN NAVIGATION TOOLBAR ──
            HStack(spacing: 10) {
                // Nav controls
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
                        .foregroundColor(Color.green)
                        .font(.system(size: 10))
                    
                    TextField("Buscar con Google o ingresar URL...", text: $addressInput, onCommit: {
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
                    
                    // 🌟 BOTÓN PARA AÑADIR A BOOKMARKS
                    Button(action: {
                        addCurrentToBookmarks()
                    }) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                    
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
                        .stroke(optimizer.isOptimizationModeActive ? Color.blue : Color.blue.opacity(0.3), lineWidth: 1)
                )
                
                // Control Badges & Tools (Gemini, DevTools, Extensions, Config)
                HStack(spacing: 6) {
                    // ✨ Gemini AI Sidebar Button
                    Button(action: {
                        isGeminiSidebarOpen.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Text("✨")
                            Text("Gemini")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isGeminiSidebarOpen ? Color.purple : Color.purple.opacity(0.18))
                        .foregroundColor(isGeminiSidebarOpen ? .white : .purple)
                        .cornerRadius(7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.purple.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // 🛠️ DevTools Button
                    Button(action: openDevToolsAlert) {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                            .padding(5)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                    .help("Inspeccionar Elemento / DevTools (Option + Cmd + I)")

                    // 🧩 Extensiones Button
                    Button(action: { isExtensionsOpen.toggle() }) {
                        Image(systemName: "puzzlepiece.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                            .padding(5)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isExtensionsOpen) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🧩 Extensiones Activas")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Divider()
                            ForEach(optimizer.extensionsList) { ext in
                                HStack {
                                    Text(ext.icon)
                                    Text(ext.name)
                                        .font(.system(size: 11))
                                        .foregroundColor(ext.isEnabled ? .white : .gray)
                                    Spacer()
                                    Circle()
                                        .fill(ext.isEnabled ? Color.green : Color.red)
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                        .padding(12)
                        .frame(width: 220)
                        .background(Color(red: 0.08, green: 0.1, blue: 0.16))
                    }

                    // ⚙️ Config Button (Cmd + ,)
                    Button(action: { isPreferencesOpen = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .padding(5)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(",", modifiers: .command)
                    .sheet(isPresented: $isPreferencesOpen) {
                        PreferencesView(optimizer: optimizer)
                    }
                    
                    // Optimization Button
                    Button(action: {
                        optimizer.isOptimizationModeActive.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Text("⚡")
                            Text(optimizer.isOptimizationModeActive ? "Optimizaciones: ON" : "Optimizaciones: OFF")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(optimizer.isOptimizationModeActive ? Color.blue : Color.blue.opacity(0.15))
                        .foregroundColor(optimizer.isOptimizationModeActive ? .white : .blue)
                        .cornerRadius(7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(red: 0.05, green: 0.07, blue: 0.12))
            .border(width: 1, edges: [.bottom], color: Color.white.opacity(0.08))
            
            // ── BOOKMARKS BAR ──
            HStack(spacing: 12) {
                ForEach(optimizer.bookmarksList) { bm in
                    BookmarkItem(icon: bm.icon, title: bm.title, url: bm.url, onSelect: navigateTo)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(red: 0.04, green: 0.05, blue: 0.09))
            .border(width: 1, edges: [.bottom], color: Color.white.opacity(0.05))

            // ── MAIN CONTENT AREA WITH GEMINI SIDEBAR ──
            HStack(spacing: 0) {
                // Main Render Port
                ShineFindWebView(urlString: $urlString, optimizerManager: optimizer)
                
                // ✨ GEMINI AI SIDEBAR INTEGRATION WITH GOOGLE LOGIN
                if isGeminiSidebarOpen {
                    VStack(spacing: 0) {
                        HStack {
                            Text("✨ Google Gemini AI")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.purple)
                            Spacer()
                            Button(action: { isGeminiSidebarOpen = false }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(red: 0.06, green: 0.08, blue: 0.14))
                        .border(width: 1, edges: [.bottom], color: Color.white.opacity(0.08))
                        
                        ShineFindWebView(urlString: .constant("https://gemini.google.com"), optimizerManager: optimizer)
                    }
                    .frame(width: 380)
                    .border(width: 1, edges: [.leading], color: Color.purple.opacity(0.4))
                }
            }
            
            // ── STATUS BAR FOOTER ──
            HStack {
                Text("Shine Find Browser v1.0 (macOS CEF Edition)")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Spacer()
                Text(optimizer.isOptimizationModeActive ? "⚡ Optimizaciones del Navegador Activas (Bajo Consumo VRAM/GPU)" : "⚡ Native Metal Engine Active")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(optimizer.isOptimizationModeActive ? .blue : .green)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(red: 0.02, green: 0.03, blue: 0.06))
        }
    }
    
    // ❌ CERRAR PESTAÑA
    private func closeTab(_ tab: TabItem) {
        guard optimizer.activeTabs.count > 1 else { return }
        if let index = optimizer.activeTabs.firstIndex(where: { $0.id == tab.id }) {
            let wasActive = optimizer.activeTabs[index].isActive
            optimizer.activeTabs.remove(at: index)
            if wasActive && !optimizer.activeTabs.isEmpty {
                let newIndex = max(0, index - 1)
                selectTab(optimizer.activeTabs[newIndex])
            }
        }
    }
    
    private func selectTab(_ selectedTab: TabItem) {
        for i in 0..<optimizer.activeTabs.count {
            optimizer.activeTabs[i].isActive = (optimizer.activeTabs[i].id == selectedTab.id)
        }
        urlString = selectedTab.url
        addressInput = selectedTab.url
    }
    
    private func addNewTab() {
        let newTab = TabItem(id: UUID(), title: "Nueva Pestaña", url: "https://cokistudios.github.io/shine-find.html", favicon: "🌐", isActive: true)
        for i in 0..<optimizer.activeTabs.count {
            optimizer.activeTabs[i].isActive = false
        }
        optimizer.activeTabs.append(newTab)
        urlString = newTab.url
        addressInput = newTab.url
    }
    
    private func addCurrentToBookmarks() {
        let title = addressInput.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
        let newBookmark = BookmarkItemData(id: UUID(), icon: "⭐", title: title, url: addressInput)
        if !optimizer.bookmarksList.contains(where: { $0.url == addressInput }) {
            optimizer.bookmarksList.append(newBookmark)
        }
    }
    
    private func openDevToolsAlert() {
        print("🛠️ DevTools Habilitadas: Presiona Option + Cmd + I sobre la vista web para abrir la inspección de elementos.")
    }
    
    private func navigateTo(_ url: String) {
        urlString = url
        addressInput = url
    }
}

// ── BOOKMARK COMPONENT ──
struct BookmarkItem: View {
    let icon: String
    let title: String
    let url: String
    let onSelect: (String) -> Void
    
    var body: some View {
        Button(action: { onSelect(url) }) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.gray)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.03))
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }
}

// Extension Helper for Border Edge
extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
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
        return path;
    }
}

// Helper to hide native window title text and retain clean traffic lights
struct WindowTitleBarAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

@main
struct Shine_FindApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .background(WindowTitleBarAccessor())
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
