import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = SupabaseManager.shared
    
    @State private var connectedApps: [ConnectedApp] = []
    @State private var editName = ""
    @State private var editCompany = ""
    
    @State private var isLoadingApps = false
    @State private var isSavingProfile = false
    @State private var showLogin = false
    @State private var toastMessage = ""
    @State private var showToast = false
    
    var body: some View {
        NavigationView {
            ZStack {
                CokiTheme.bg
                    .ignoresSafeArea()
                
                if authManager.isLoggedIn, let user = authManager.currentUser {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // 1. Profile Box Card
                            VStack(spacing: 16) {
                                HStack(spacing: 20) {
                                    // Avatar
                                    let initials = user.initials
                                    let meta = user.user_metadata
                                    let avatarURL = meta?.avatar_url ?? meta?.picture
                                    
                                    if let avatar = avatarURL, let url = URL(string: avatar) {
                                        AsyncImage(url: url) { image in
                                            image.resizable()
                                        } placeholder: {
                                            CircleAvatarPlaceholder(initials: initials)
                                        }
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(CokiTheme.accent.opacity(0.4), lineWidth: 1))
                                    } else {
                                        CircleAvatarPlaceholder(initials: initials)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(user.displayName)
                                            .font(.title2.bold())
                                            .foregroundColor(CokiTheme.text)
                                        
                                        Text(user.email ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(CokiTheme.textSub)
                                        
                                        // Badge
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.seal.fill")
                                            Text("Cuenta verificada")
                                        }
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 10)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(100)
                                    }
                                    Spacer()
                                }
                            }
                            .glassCard()
                            .padding(.horizontal)
                            
                            // 2. Stats Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                StatCard(title: "Apps Conectadas", value: "\(connectedApps.count)", color: CokiTheme.text)
                                StatCard(title: "Estado de Cuenta", value: "Activo", color: .green)
                            }
                            .padding(.horizontal)
                            
                            // 3. Connected Apps Box
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Apps conectadas")
                                    .font(.headline)
                                    .foregroundColor(CokiTheme.text)
                                
                                if isLoadingApps {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: CokiTheme.accent))
                                        Spacer()
                                    }
                                    .padding(.vertical, 20)
                                } else if connectedApps.isEmpty {
                                    VStack(spacing: 8) {
                                        Text("No tienes apps conectadas aún")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(CokiTheme.text)
                                        Text("Las apps aparecerán aquí cuando uses \"Iniciar sesión con CS ID\"")
                                            .font(.system(size: 13))
                                            .foregroundColor(CokiTheme.textSub)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 32)
                                    .background(Color.white.opacity(0.015))
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(CokiTheme.border, lineWidth: 1))
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(connectedApps) { app in
                                            ConnectedAppRow(app: app) {
                                                Task {
                                                    await revokeApp(app: app)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .glassCard()
                            .padding(.horizontal)
                            
                            // 4. Edit Profile Box
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Configuración de Perfil")
                                    .font(.headline)
                                    .foregroundColor(CokiTheme.text)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Nombre completo")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(CokiTheme.textSub)
                                    
                                    TextField("Tu nombre", text: $editName)
                                        .foregroundColor(CokiTheme.text)
                                        .padding()
                                        .background(Color.black.opacity(0.2))
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(CokiTheme.border, lineWidth: 1))
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Empresa / Organización")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(CokiTheme.textSub)
                                    
                                    TextField("Tu empresa", text: $editCompany)
                                        .foregroundColor(CokiTheme.text)
                                        .padding()
                                        .background(Color.black.opacity(0.2))
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(CokiTheme.border, lineWidth: 1))
                                }
                                
                                Button(action: {
                                    Task {
                                        await saveProfile()
                                    }
                                }) {
                                    HStack {
                                        if isSavingProfile {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Guardar cambios")
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(isSavingProfile)
                            }
                            .glassCard()
                            .padding(.horizontal)
                            
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await loadDashboardData()
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                authManager.logout()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "power")
                                    Text("Salir")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red)
                            }
                        }
                    }
                } else {
                    // Not logged in view
                    VStack(spacing: 24) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 72))
                            .foregroundColor(CokiTheme.textSub)
                        
                        VStack(spacing: 8) {
                            Text("Coki Studios ID")
                                .font(.title2.bold())
                                .foregroundColor(CokiTheme.text)
                            
                            Text("Tu cuenta global de desarrollador y usuario.")
                                .font(.subheadline)
                                .foregroundColor(CokiTheme.textSub)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Button(action: {
                            showLogin = true
                        }) {
                            Text("Iniciar Sesión / Registrarse")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 32)
                    }
                }
                
                // Toast popup overlay
                if showToast {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.green)
                            .cornerRadius(24)
                            .shadow(radius: 5)
                            .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: showToast)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("C")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(CokiTheme.primaryGradient)
                            .cornerRadius(6)
                        
                        Text("Coki Studios ID")
                            .font(.headline)
                            .foregroundColor(CokiTheme.text)
                    }
                }
            }
            .sheet(isPresented: $showLogin, onDismiss: {
                if authManager.isLoggedIn {
                    Task {
                        await loadDashboardData()
                    }
                }
            }) {
                NavigationView {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .onAppear {
                if authManager.isLoggedIn {
                    Task {
                        await loadDashboardData()
                    }
                }
            }
        }
    }
    
    private func loadDashboardData() async {
        guard let user = authManager.currentUser else { return }
        
        // Load input fields
        editName = user.displayName
        editCompany = user.user_metadata?.company ?? ""
        
        isLoadingApps = true
        do {
            connectedApps = try await authManager.fetchConnectedApps()
        } catch {
            print("Error loading apps: \(error)")
        }
        isLoadingApps = false
    }
    
    private func saveProfile() async {
        isSavingProfile = true
        do {
            try await authManager.updateProfile(name: editName, company: editCompany)
            triggerToast(message: "✅ Perfil actualizado")
        } catch {
            triggerToast(message: "❌ \(error.localizedDescription)")
        }
        isSavingProfile = false
    }
    
    private func revokeApp(app: ConnectedApp) async {
        do {
            try await authManager.revokeConnectedApp(clientId: app.client_id)
            triggerToast(message: "✅ App desconectada")
            await loadDashboardData()
        } catch {
            triggerToast(message: "❌ \(error.localizedDescription)")
        }
    }
    
    private func triggerToast(message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// MARK: - Subviews
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(CokiTheme.textMuted)
                .tracking(0.5)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CokiTheme.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(CokiTheme.border, lineWidth: 1))
    }
}

struct CircleAvatarPlaceholder: View {
    let initials: String
    
    var body: some View {
        Text(initials)
            .font(.system(size: 28, weight: .black))
            .foregroundColor(CokiTheme.accent)
            .frame(width: 80, height: 80)
            .background(CokiTheme.accent.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(CokiTheme.border, lineWidth: 1))
    }
}

struct ConnectedAppRow: View {
    let app: ConnectedApp
    let onRevoke: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Icon
                if let logo = app.oauth_clients?.logo_url, let url = URL(string: logo) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        AppLetterPlaceholder(letter: app.appIconLetter)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    AppLetterPlaceholder(letter: app.appIconLetter)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.appName)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(CokiTheme.text)
                    
                    Text("Permisos: \(app.scopesString)")
                        .font(.system(size: 12))
                        .foregroundColor(CokiTheme.textSub)
                    
                    Text("Conectada: \(app.formattedDate)")
                        .font(.system(size: 11))
                        .foregroundColor(CokiTheme.textMuted)
                }
                Spacer()
            }
            
            Button(action: onRevoke) {
                Text("Revocar acceso")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.2), lineWidth: 1))
            }
        }
        .padding()
        .background(Color.white.opacity(0.015))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(CokiTheme.border, lineWidth: 1))
    }
}

struct AppLetterPlaceholder: View {
    let letter: String
    
    var body: some View {
        Text(letter)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(CokiTheme.accent)
            .frame(width: 48, height: 48)
            .background(CokiTheme.accent.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(CokiTheme.border, lineWidth: 1))
    }
}

#Preview {
    ContentView()
}
