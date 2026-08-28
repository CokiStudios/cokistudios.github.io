import SwiftUI
import WebKit
import AppKit

@main
struct hiOPApp: App {
    var body: some Scene {
        WindowGroup {
            hiOPMainView()
                .frame(minWidth: 1200, minHeight: 760)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New .loop File") {
                    // Custom action
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandMenu("Looping Core") {
                Button("Run .loop Code") {
                    NotificationCenter.default.post(name: NSNotification.Name("RunLoopCode"), object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}

// MARK: - Native macOS IDE View with Embedded High-Performance WebKit Monaco Core
struct hiOPMainView: View {
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.09).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Native macOS Window Title Accent
                HStack {
                    HStack(spacing: 6) {
                        Text("L∞ping")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(Color(red: 0.2, green: 0.85, blue: 1.0))
                        
                        Text("hiOP IDE — Native macOS Studio")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("CS PROPRIETARY CORE v2.0")
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(colors: [Color.indigo, Color.purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.03, green: 0.04, blue: 0.07))
                .border(Color.white.opacity(0.06), width: 1)
                
                // Embedded Native Monaco Engine
                hiOPWebView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct hiOPWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        
        // Load Local WebCore / Monaco engine or Online fallback
        if let indexPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "WebCore") {
            let fileURL = URL(fileURLWithPath: indexPath)
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        } else if let remoteURL = URL(string: "https://cokistudios.com/hiop-ide") {
            webView.load(URLRequest(url: remoteURL))
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RunLoopCode"), object: nil, queue: .main) { _ in
            webView.evaluateJavaScript("document.getElementById('btn-run-code').click();", completionHandler: nil)
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
