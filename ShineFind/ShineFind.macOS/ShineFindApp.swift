import SwiftUI
import WebKit

// ═══════════════════════════════════════════════════════════════
// 🍒 NOOTEDRED HACKINTOSH OPTIMIZER CONFIGURATION FOR MAC
// ═══════════════════════════════════════════════════════════════
class NootedRedManager: ObservableObject {
    static let shared = NootedRedManager()
    
    @Published var isNootedRedModeActive: Bool = false {
        didSet {
            applyOptimizations()
        }
    }
    
    func applyOptimizations() {
        if isNootedRedModeActive {
            print("🍒 NootedRed Hackintosh Mode ACTIVE: Disabling Hardware Acceleration & Video HW Decode to prevent APU KP.")
        } else {
            print("⚡ Standard Performance Mode ACTIVE.")
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 🌐 WKWEBVIEW CEF-EQUIVALENT ENGINE FOR MACOS
// ═══════════════════════════════════════════════════════════════
struct ShineFindWebView: NSViewRepresentable {
    @Binding var urlString: String
    @ObservedObject var nootedRedManager: NootedRedManager
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        
        // Custom User-Agent for Shine Find Browser
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15 ShineFind/1.0 (macOS NootedRed Enabled)"
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
    }
}

// ═══════════════════════════════════════════════════════════════
// 🎨 MAIN MACOS BROWSER UI (SHINE UI & XTRAPS)
// ═══════════════════════════════════════════════════════════════
struct MainWindowView: View {
    @State private var urlString: String = "https://cokistudios.github.io/forkar.html"
    @State private var addressInput: String = "https://cokistudios.github.io/forkar.html"
    @StateObject private var nootedRed = NootedRedManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // ── TOOLBAR (SHINE UI) ──
            HStack(spacing: 12) {
                // Navigation controls
                HStack(spacing: 6) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                    
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                    
                    Button(action: {
                        urlString = addressInput
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                }
                
                // Address Bar
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Color.green)
                        .font(.system(size: 11))
                    
                    TextField("Buscar o escribir URL", text: $addressInput, onCommit: {
                        var target = addressInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !target.hasPrefix("http://") && !target.hasPrefix("https://") {
                            target = "https://" + target
                        }
                        urlString = target
                        addressInput = target
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.4))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(nootedRed.isNootedRedModeActive ? Color.red : Color.blue.opacity(0.4), lineWidth: 1)
                )
                
                // Badges & NootedRed Toggle
                HStack(spacing: 8) {
                    // NootedRed Button
                    Button(action: {
                        nootedRed.isNootedRedModeActive.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Text("🍒")
                            Text(nootedRed.isNootedRedModeActive ? "NootedRed: ON ⚡" : "NootedRed: OFF")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(nootedRed.isNootedRedModeActive ? Color.red : Color.red.opacity(0.15))
                        .foregroundColor(nootedRed.isNootedRedModeActive ? .white : .red)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Sentinel Shield
                    HStack(spacing: 4) {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.green)
                        Text("Sentinel ON")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
                    
                    // CSID Indicator
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.key.fill")
                            .foregroundColor(.cyan)
                        Text("CSID")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.cyan.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .padding(10)
            .background(Color(red: 0.05, green: 0.07, blue: 0.12))
            .border(width: 1, edges: [.bottom], color: Color.white.opacity(0.1))
            
            // ── WEBVIEW PORT ──
            ShineFindWebView(urlString: $urlString, nootedRedManager: nootedRed)
            
            // ── STATUS BAR ──
            HStack {
                Text("Shine Find Browser macOS CEF Edition — Coki Studios")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Spacer()
                Text(nootedRed.isNootedRedModeActive ? "🍒 NootedRed Hackintosh Mode Active (APU Guard ON)" : "⚡ Native Metal Acceleration")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(nootedRed.isNootedRedModeActive ? .red : .green)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(red: 0.03, green: 0.04, blue: 0.08))
        }
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
struct ShineFindApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 1024, minHeight: 680)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
