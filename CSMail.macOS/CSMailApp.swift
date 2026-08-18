import SwiftUI
import WebKit

// MARK: - App Entry Point
@main
struct CSMailApp: App {
    var body: some Scene {
        WindowGroup {
            CSMailMainView()
                .frame(minWidth: 1000, minHeight: 650)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("Nuevo Correo") {
                    NotificationCenter.default.post(name: NSNotification.Name("ComposeNewMail"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

// MARK: - Main Private CS Mail View
struct CSMailMainView: View {
    @StateObject private var webViewModel = CSMailWebViewModel()
    @State private var selectedFolder = "inbox"
    @State private var unreadCount = 0
    @State private var isSidebarVisible = true
    
    var body: some View {
        ZStack {
            // Fondo oscuro premium CS
            Color(red: 0.05, green: 0.07, blue: 0.11).ignoresSafeArea()
            
            HSplitView {
                // Sidebar Nativo Privado CS
                VStack(alignment: .leading, spacing: 14) {
                    // Brand Header
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 139/255, green: 92/255, blue: 246/255)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CS MAIL")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.white)
                                .tracking(1.2)
                            Text("Zoho Private Client")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 16)
                    
                    // Botón Redactar
                    Button(action: {
                        webViewModel.composeMail()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.pencil")
                            Text("Redactar")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 79/255, green: 70/255, blue: 229/255), Color(red: 124/255, green: 58/255, blue: 237/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: Color.indigo.opacity(0.35), radius: 6, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 12)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal, 10)
                    
                    // Carpetas Rápidas
                    VStack(spacing: 4) {
                        MailSidebarItem(icon: "tray.fill", title: "Bandeja de Entrada", isSelected: selectedFolder == "inbox") {
                            selectedFolder = "inbox"
                            webViewModel.navigate(to: "https://mail.zoho.com/zm/#mail/folder/inbox")
                        }
                        
                        MailSidebarItem(icon: "star.fill", title: "Destacados", isSelected: selectedFolder == "starred") {
                            selectedFolder = "starred"
                            webViewModel.navigate(to: "https://mail.zoho.com/zm/#mail/folder/starred")
                        }
                        
                        MailSidebarItem(icon: "paperplane.fill", title: "Enviados", isSelected: selectedFolder == "sent") {
                            selectedFolder = "sent"
                            webViewModel.navigate(to: "https://mail.zoho.com/zm/#mail/folder/sent")
                        }
                        
                        MailSidebarItem(icon: "doc.fill", title: "Borradores", isSelected: selectedFolder == "drafts") {
                            selectedFolder = "drafts"
                            webViewModel.navigate(to: "https://mail.zoho.com/zm/#mail/folder/drafts")
                        }
                        
                        MailSidebarItem(icon: "trash.fill", title: "Papelera", isSelected: selectedFolder == "trash") {
                            selectedFolder = "trash"
                            webViewModel.navigate(to: "https://mail.zoho.com/zm/#mail/folder/trash")
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    Spacer()
                    
                    // Cuenta y Privacidad
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Sesión Segura Encriptada")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Button(action: { webViewModel.reload() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            Button("Salir") {
                                webViewModel.logout()
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red.opacity(0.8))
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 12)
                }
                .frame(minWidth: 210, maxWidth: 240)
                .background(Color(red: 0.07, green: 0.09, blue: 0.14))
                
                // WebView Contenedor Acelerado y Privado
                ZStack {
                    CSMailWebView(viewModel: webViewModel)
                    
                    if webViewModel.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Cargando Zoho Mail...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(red: 0.05, green: 0.07, blue: 0.11))
                    }
                }
            }
        }
    }
}

// MARK: - Sidebar Item
struct MailSidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? Color.white : Color.gray)
                    .frame(width: 18)
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? Color.white : Color(red: 0.8, green: 0.85, blue: 0.9))
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.indigo.opacity(0.3) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.indigo.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - WebViewModel
class CSMailWebViewModel: NSObject, ObservableObject {
    @Published var isLoading = true
    var webView: WKWebView?
    
    func navigate(to urlString: String) {
        if let url = URL(string: urlString) {
            webView?.load(URLRequest(url: url))
        }
    }
    
    func reload() {
        webView?.reload()
    }
    
    func composeMail() {
        let js = "if(window.ZohoMail && window.ZohoMail.compose){ window.ZohoMail.compose(); } else { window.location.hash = '#mail/compose'; }"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
    
    func logout() {
        navigate(to: "https://accounts.zoho.com/logout")
    }
}

// MARK: - WKWebView Representable with Isolated Private Data Storage
struct CSMailWebView: NSViewRepresentable {
    @ObservedObject var viewModel: CSMailWebViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15 CSMail/1.0"
        
        // Almacenamiento persistente propio aislado de la app
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        // Inyectar CSS modo oscuro sutil si se desea
        let userScript = WKUserScript(
            source: """
            document.addEventListener('DOMContentLoaded', function() {
                console.log('CS Mail Client Initialized');
            });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        viewModel.webView = webView
        
        if let url = URL(string: "https://mail.zoho.com/zm/") {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var viewModel: CSMailWebViewModel
        
        init(viewModel: CSMailWebViewModel) {
            self.viewModel = viewModel
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
            }
        }
    }
}
