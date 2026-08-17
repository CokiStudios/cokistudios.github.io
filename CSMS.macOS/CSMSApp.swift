import SwiftUI
import WebKit
import Combine

// ═══════════════════════════════════════════════════════════════
// 💬 CSMS NATIVE CLIENT FOR MACOS (Universal: Apple Silicon & Intel)
// ═══════════════════════════════════════════════════════════════

@main
struct CSMSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            CSMSMainView()
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("Nuevo Mensaje Directo") {
                    NotificationCenter.default.post(name: NSNotification.Name("CSMSNewDM"), object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("Nuevo Grupo") {
                    NotificationCenter.default.post(name: NSNotification.Name("CSMSNewGroup"), object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Silenciar mensajes internos de linkd y WebContent sandbox logging en la consola de Xcode
        setenv("OS_ACTIVITY_MODE", "disable", 1)
        UserDefaults.standard.set(false, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

struct CSMSMainView: View {
    @StateObject private var webViewModel = CSMSWebViewModel()
    
    var body: some View {
        ZStack {
            // Fondo oscuro nativo estilo Liquid Glass de Coki Studios
            Color(red: 6/255, green: 9/255, blue: 15/255)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Barra de Título personalizada para macOS
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("C")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(LinearGradient(colors: [Color(hex: "#6366f1") ?? .indigo, Color(hex: "#8b5cf6") ?? .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(6)
                        
                        Text("CSMS")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text("Coki Studios Messenger")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#94a3b8") ?? .gray)
                    }
                    .padding(.leading, 78) // Espacio para los semáforos de macOS
                    
                    Spacer()
                    
                    // Botones de acción rápida
                    HStack(spacing: 8) {
                        Button(action: { webViewModel.reload() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(6)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Recargar CSMS (⌘R)")
                        
                        Button(action: { webViewModel.goHome() }) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(6)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Inicio de CSMS")
                    }
                    .padding(.trailing, 16)
                }
                .frame(height: 44)
                .background(Color(red: 13/255, green: 17/255, blue: 23/255).opacity(0.95))
                .overlay(
                    VStack {
                        Spacer()
                        Divider().background(Color.white.opacity(0.08))
                    }
                )
                
                // WebView contenedor de CSMS optimizado para macOS
                CSMSWebView(viewModel: webViewModel)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
            }
        }
    }
}

class CSMSWebViewModel: ObservableObject {
    var webView: WKWebView?
    
    func reload() {
        webView?.reload()
    }
    
    func goHome() {
        let url = URL(string: "https://cokistudios.com/coki-messenger.html")!
        webView?.load(URLRequest(url: url))
    }
    
    func triggerNewDM() {
        webView?.evaluateJavaScript("document.getElementById('btn-new-dm')?.click();", completionHandler: nil)
    }
    
    func triggerNewGroup() {
        webView?.evaluateJavaScript("document.getElementById('btn-new-group')?.click();", completionHandler: nil)
    }
}

struct CSMSWebView: NSViewRepresentable {
    @ObservedObject var viewModel: CSMSWebViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        // Habilitar soporte para WebAuthn / Passkeys, audio y video nativo en macOS
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Establecer User-Agent de CSMS macOS App
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) CSMSNativeApp/2.0 Version/17.0 Safari/605.1.15"
        
        viewModel.webView = webView
        
        // Cargar CSMS
        let url = URL(string: "https://cokistudios.com/coki-messenger.html")!
        webView.load(URLRequest(url: url))
        
        // Listeners para atajos de teclado de la app nativa
        NotificationCenter.default.addObserver(forName: NSNotification.Name("CSMSNewDM"), object: nil, queue: .main) { _ in
            viewModel.triggerNewDM()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("CSMSNewGroup"), object: nil, queue: .main) { _ in
            viewModel.triggerNewGroup()
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: CSMSWebView
        
        init(_ parent: CSMSWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Inyectar ajustes visuales de ventana si es necesario
            webView.evaluateJavaScript("document.body.style.userSelect = 'text';", completionHandler: nil)
        }
    }
}

// Color Hex Helper
extension Color {
    init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: cleanHex).scanHexInt64(&rgb) else { return nil }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
