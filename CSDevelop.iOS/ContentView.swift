import SwiftUI
internal import Combine

struct ContentView: View {
    @ObservedObject var manager = SupabaseManager.shared
    
    @State private var apps: [DeveloperApp] = []
    @State private var loading = false
    @State private var showingForm = false
    @State private var selectedAppForEdit: DeveloperApp? = nil
    @State private var errorMessage: String? = nil
    @State private var copyToastMessage: String? = nil
    
    var body: some View {
        Group {
            if manager.isLoggedIn {
                mainAppView
            } else {
                LoginView()
            }
        }
        .onAppear {
            if manager.isLoggedIn {
                Task {
                    await loadApps()
                }
            }
        }
    }
    
    // MARK: - Dashboard Main View
    private var mainAppView: some View {
        NavigationStack {
            ZStack {
                CSDevelopTheme.bg
                    .ignoresSafeArea()
                XtrapsBackground(strokeColor: CSDevelopTheme.accent.opacity(0.12))
                    .ignoresSafeArea()
                
                // ambient glow background
                VStack {
                    HStack {
                        Circle()
                            .fill(CSDevelopTheme.primaryGradient)
                            .frame(width: 250, height: 250)
                            .blur(radius: 90)
                            .opacity(0.12)
                            .offset(x: -80, y: -40)
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Error message if any
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.octagon.fill")
                                    .foregroundColor(CSDevelopTheme.red)
                                Text(error)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(CSDevelopTheme.red)
                                Spacer()
                                Button("OK") { errorMessage = nil }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(CSDevelopTheme.red)
                            }
                            .padding()
                            .background(CSDevelopTheme.red.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(CSDevelopTheme.red.opacity(0.2), lineWidth: 1))
                            .padding(.horizontal)
                        }
                        
                        // 1. Stats Grid
                        statsGridSection
                        
                        // 2. Integration Tip Box
                        integrationDocsSection
                        
                        // 3. Applications List
                        applicationsHeaderSection
                        
                        if loading && apps.isEmpty {
                            ProgressView("Cargando aplicaciones...")
                                .tint(CSDevelopTheme.accent)
                                .padding(.top, 40)
                        } else if apps.isEmpty {
                            emptyStateSection
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(apps) { app in
                                    appCard(app)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                .refreshable {
                    await loadApps()
                }
                
                // Copy Toast Overlay
                if let toastMsg = copyToastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(CSDevelopTheme.green)
                            Text(toastMsg)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color(hex: "#111827")?.opacity(0.9) ?? Color.black.opacity(0.9))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(CSDevelopTheme.border, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: copyToastMessage)
                }
            }
            .navigationTitle("Consola")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(CSDevelopTheme.primaryGradient)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(manager.currentUser?.initials ?? "D")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        VStack(alignment: .leading, spacing: 1) {
                            Text(manager.currentUser?.displayName ?? "Desarrollador")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(CSDevelopTheme.text)
                            Text("Consola Developer")
                                .font(.system(size: 10))
                                .foregroundColor(CSDevelopTheme.textMuted)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            selectedAppForEdit = nil
                            showingForm = true
                        } label: {
                            Label("Nueva App", systemImage: "plus.app")
                        }
                        
                        Button {
                            Task {
                                await loadApps()
                            }
                        } label: {
                            Label("Recargar", systemImage: "arrow.clockwise")
                        }
                        
                        Button(role: .destructive) {
                            manager.logout()
                        } label: {
                            Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(CSDevelopTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingForm, onDismiss: {
                Task {
                    await loadApps()
                }
            }) {
                AppDetailFormView(appToEdit: selectedAppForEdit)
            }
        }
    }
    
    // MARK: - Components
    
    private var statsGridSection: some View {
        HStack(spacing: 12) {
            // Total Card
            VStack(alignment: .leading, spacing: 6) {
                Text("APPLICATIONS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(CSDevelopTheme.textMuted)
                Text("\(apps.count)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(CSDevelopTheme.text)
                Text("Apps registradas")
                    .font(.system(size: 11))
                    .foregroundColor(CSDevelopTheme.textSub)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .csGlassCard()
            
            // Active Card
            VStack(alignment: .leading, spacing: 6) {
                Text("ACTIVES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(CSDevelopTheme.textMuted)
                Text("\(apps.filter({ $0.is_active }).count)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(CSDevelopTheme.green)
                Text("Aceptando logins")
                    .font(.system(size: 11))
                    .foregroundColor(CSDevelopTheme.textSub)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .csGlassCard()
        }
        .padding(.horizontal)
    }
    
    private var integrationDocsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🚀 Integración Coki ID")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(CSDevelopTheme.text)
                Spacer()
            }
            Text("Usa el client_id de tu app y redirige a los usuarios a la URL de autorización para el inicio de sesión OAuth2.")
                .font(.system(size: 12))
                .foregroundColor(CSDevelopTheme.textSub)
                .lineLimit(nil)
            
            Text("https://cokistudios.github.io/coki-authorize.html")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(CSDevelopTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.15))
                .cornerRadius(6)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [CSDevelopTheme.accent.opacity(0.12), CSDevelopTheme.accent2.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(CSDevelopTheme.accent.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var applicationsHeaderSection: some View {
        HStack {
            Text("Mis Aplicaciones")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(CSDevelopTheme.text)
            Spacer()
            Button(action: {
                selectedAppForEdit = nil
                showingForm = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Nueva App")
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(CSDevelopTheme.accent)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Text("🔌")
                .font(.system(size: 50))
            Text("Sin aplicaciones todavía")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(CSDevelopTheme.text)
            Text("Registra tu primera aplicación para integrar el inicio de sesión único Coki ID.")
                .font(.system(size: 13))
                .foregroundColor(CSDevelopTheme.textSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Button("+ Crear mi primera app") {
                selectedAppForEdit = nil
                showingForm = true
            }
            .buttonStyle(CSPrimaryButton())
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(CSDevelopTheme.card)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(CSDevelopTheme.border, lineWidth: 1))
        .padding(.horizontal)
    }
    
    private func appCard(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // App Name & Toggle
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(CSDevelopTheme.primaryGradient.opacity(0.12))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(app.appIconLetter)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(CSDevelopTheme.accent)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.client_name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(CSDevelopTheme.text)
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(app.is_active ? CSDevelopTheme.green : CSDevelopTheme.textMuted)
                                .frame(width: 6, height: 6)
                            Text(app.is_active ? "Activa" : "Inactiva")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(app.is_active ? CSDevelopTheme.green : CSDevelopTheme.textMuted)
                        }
                    }
                }
                
                Spacer()
                
                // Actions Menu
                Menu {
                    Button {
                        selectedAppForEdit = app
                        showingForm = true
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    
                    Button {
                        toggleActive(app)
                    } label: {
                        Label(app.is_active ? "Desactivar" : "Activar", systemImage: app.is_active ? "bolt.slash" : "bolt")
                    }
                    
                    Button(role: .destructive) {
                        confirmAndDelete(app)
                    } label: {
                        Label("Eliminar app", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(CSDevelopTheme.textSub)
                        .padding(8)
                        .background(Color.white.opacity(0.04))
                        .clipShape(Circle())
                }
            }
            
            // Client ID Row
            VStack(alignment: .leading, spacing: 6) {
                Text("CLIENT ID")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(CSDevelopTheme.textMuted)
                
                HStack {
                    Text(app.client_id)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(CSDevelopTheme.accent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button(action: {
                        copyToClipboard(app.client_id)
                    }) {
                        Text("Copiar")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(CSDevelopTheme.accent)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(CSDevelopTheme.accent.opacity(0.12))
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Website if exists
            if let web = app.website_url, !web.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SITIO WEB")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(CSDevelopTheme.textMuted)
                    
                    Link(web, destination: URL(string: web) ?? URL(string: "https://google.com")!)
                        .font(.system(size: 13))
                        .foregroundColor(CSDevelopTheme.textSub)
                        .underline()
                        .lineLimit(1)
                }
            }
            
            // Redirect URIs List
            VStack(alignment: .leading, spacing: 6) {
                Text("REDIRECT URIS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(CSDevelopTheme.textMuted)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(app.redirect_uris, id: \.self) { uri in
                            Text(uri)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(CSDevelopTheme.textSub)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(CSDevelopTheme.border, lineWidth: 1))
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(CSDevelopTheme.card)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(app.is_active ? CSDevelopTheme.border : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 3)
    }
    
    // MARK: - Actions
    
    private func loadApps() async {
        await MainActor.run { loading = true }
        do {
            let fetched = try await manager.fetchApps()
            await MainActor.run {
                self.apps = fetched
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        await MainActor.run { loading = false }
    }
    
    private func toggleActive(_ app: DeveloperApp) {
        Task {
            do {
                try await manager.toggleActive(clientId: app.client_id, isActive: app.is_active)
                await loadApps()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func confirmAndDelete(_ app: DeveloperApp) {
        let alert = UIAlertController(title: "Eliminar App", message: "¿Estás seguro de que quieres eliminar \(app.client_name)? Esta acción no se puede deshacer.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive, handler: { _ in
            Task {
                do {
                    try await manager.deleteApp(clientId: app.client_id)
                    await loadApps()
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }))
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(alert, animated: true)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        copyToastMessage = "Copiado al portapapeles"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            copyToastMessage = nil
        }
    }
}

#Preview {
    ContentView()
}
