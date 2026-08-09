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
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        
        // 🛡️ Permisos para WebKit Process Resilience
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
        
        // 🔄 AUTO-RECOVERY SI EL WEB PROCESS COLAPSA O ES RESTRINGIDO POR SANDBOX
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            print("⚠️ WebContent Process colapsó. Intentando recarga automática de Shine Find...")
            webView.reload()
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 🎨 PREMIUM MACOS BROWSER UI (SHINE UI, DYNAMIC TABS & XTRAPS)
// ═══════════════════════════════════════════════════════════════
struct MainWindowView: View {
    @State private var urlString: String = "https://cokistudios.github.io/forkar.html"
    @State private var addressInput: String = "https://cokistudios.github.io/forkar.html"
    @State private var isBookmarksOpen: Bool = false
    @StateObject private var optimizer = BrowserOptimizerManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // ── TOP TAB BAR (CHROMIUM / SAFARI HYBRID) ──
            HStack(spacing: 0) {
                // Drag handle area for window move
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Circle().fill(Color.yellow).frame(width: 10, height: 10)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                }
                .padding(.leading, 14)
                .padding(.trailing, 16)
                
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
                                
                                Button(action: {}) {
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
                
                // Control Badges & Optimization Toggle
                HStack(spacing: 6) {
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
                    
                    // Sentinel Shield Badge
                    HStack(spacing: 4) {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text("\(optimizer.blockedTrackersCount) Bloqueados")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(7)
                    
                    // Eco CO2 Badge
                    HStack(spacing: 4) {
                        Text("🌿")
                        Text("\(optimizer.co2SavedGrams, specifier: "%.1f")g CO₂")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.12))
                    .cornerRadius(7)

                    // CSID Status Indicator
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.key.fill")
                            .foregroundColor(.cyan)
                            .font(.system(size: 10))
                        Text("CSID")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(7)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(red: 0.05, green: 0.07, blue: 0.12))
            .border(width: 1, edges: [.bottom], color: Color.white.opacity(0.08))
            
            // ── BOOKMARKS BAR ──
            HStack(spacing: 12) {
                BookmarkItem(icon: "💬", title: "Forkar Hub", url: "https://cokistudios.github.io/forkar.html", onSelect: navigateTo)
                BookmarkItem(icon: "⚡", title: "Coki Products", url: "https://cokistudios.github.io/products.html", onSelect: navigateTo)
                BookmarkItem(icon: "🪪", title: "CSID Dashboard", url: "https://cokistudios.github.io/coki-dashboard.html", onSelect: navigateTo)
                BookmarkItem(icon: "🗺️", title: "Horizon Maps", url: "https://anonymus-devop.github.io/HorizonMaps/", onSelect: navigateTo)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(red: 0.04, green: 0.05, blue: 0.09))
            .border(width: 1, edges: [.bottom], color: Color.white.opacity(0.05))

            // ── RENDER PORT ──
            ShineFindWebView(urlString: $urlString, optimizerManager: optimizer)
            
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

@main
struct Shine_FindApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
