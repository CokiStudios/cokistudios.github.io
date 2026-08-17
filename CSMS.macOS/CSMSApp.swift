import SwiftUI
internal import Combine

// ═══════════════════════════════════════════════════════════════
// 💬 CSMS NATIVE CLIENT FOR MACOS (100% Native SwiftUI & Safari Pop-Up Auth)
// ═══════════════════════════════════════════════════════════════

@main
struct CSMSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = SupabaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            CSMSNativeRootView()
                .environmentObject(authManager)
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("Nuevo Chat Directo / Email") {
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
        setenv("OS_ACTIVITY_MODE", "disable", 1)
        UserDefaults.standard.set(false, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // Captura callbacks de deep link (ej. forkar://oauth o csms://oauth)
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "forkar" || url.scheme == "csms" {
                Task {
                    try? await SupabaseManager.shared.signInWithOAuth(provider: "google")
                }
            }
        }
    }
}

// MARK: - Root Native View
struct CSMSNativeRootView: View {
    @EnvironmentObject var authManager: SupabaseManager
    
    var body: some View {
        ZStack {
            ForkarTheme.bg.ignoresSafeArea()
            
            if authManager.isLoggedIn {
                CSMSMasterDetailView()
            } else {
                CSMSNativeLoginView()
            }
        }
    }
}

// MARK: - Native Safari Pop-Up Auth Screen
struct CSMSNativeLoginView: View {
    @EnvironmentObject var authManager: SupabaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var isRegisterMode = false
    @State private var fullName = ""
    
    var body: some View {
        ZStack {
            XtrapsBackground(strokeColor: ForkarTheme.accent, opacity: 0.25)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Header Brand
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Text("C")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(ForkarTheme.primaryGradient)
                            .cornerRadius(10)
                        
                        Text("CSMS")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(ForkarTheme.text)
                    }
                    
                    Text("Coki Studios Messenger Service")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ForkarTheme.textSub)
                }
                
                // Card
                VStack(spacing: 18) {
                    // Botón Safari Pop-Up OAuth (Google / GitHub)
                    VStack(spacing: 10) {
                        Button(action: { loginWithSafariPopup(provider: "google") }) {
                            HStack(spacing: 10) {
                                Image(systemName: "safari.fill")
                                    .font(.system(size: 15))
                                Text("Continuar con Google (Safari Pop-Up)")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .foregroundColor(ForkarTheme.text)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForkarTheme.border, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { loginWithSafariPopup(provider: "github") }) {
                            HStack(spacing: 10) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Continuar con GitHub")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForkarTheme.border, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        Rectangle().fill(ForkarTheme.border).frame(height: 1)
                        Text("o con tu CSID").font(.caption).foregroundColor(ForkarTheme.textMuted)
                        Rectangle().fill(ForkarTheme.border).frame(height: 1)
                    }
                    .padding(.vertical, 4)
                    
                    // Formulario Tradicional
                    VStack(spacing: 12) {
                        if isRegisterMode {
                            TextField("Nombre Completo", text: $fullName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(12)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(ForkarTheme.border, lineWidth: 1))
                        }
                        
                        TextField("Correo Electrónico", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(12)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ForkarTheme.border, lineWidth: 1))
                        
                        SecureField("Contraseña", text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(12)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ForkarTheme.border, lineWidth: 1))
                    }
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: handleEmailAuth) {
                        HStack {
                            if isLoading {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8)
                            } else {
                                Text(isRegisterMode ? "Crear Cuenta CSID" : "Entrar a CSMS")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ForkarTheme.primaryGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isLoading)
                    
                    Button(action: { isRegisterMode.toggle(); errorMessage = nil }) {
                        Text(isRegisterMode ? "¿Ya tienes cuenta? Inicia Sesión" : "¿No tienes cuenta? Regístrate aquí")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.accent)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(28)
                .frame(width: 380)
                .background(Color(red: 13/255, green: 17/255, blue: 23/255).opacity(0.95))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ForkarTheme.border, lineWidth: 1.5))
                .shadow(color: Color.black.opacity(0.3), radius: 20, y: 8)
            }
        }
    }
    
    private func loginWithSafariPopup(provider: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authManager.signInWithOAuth(provider: provider)
                await MainActor.run { isLoading = false }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleEmailAuth() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Completa todos los campos"
            return
        }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isRegisterMode {
                    try await authManager.signUp(email: email, password: password, name: fullName.isEmpty ? "Usuario" : fullName)
                } else {
                    try await authManager.login(email: email, password: password)
                }
                await MainActor.run { isLoading = false }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Native Master-Detail Messenger View (macOS Layout)
struct CSMSMasterDetailView: View {
    @EnvironmentObject var authManager: SupabaseManager
    @State private var rooms: [ChatRoom] = []
    @State private var selectedRoom: ChatRoom? = nil
    @State private var isLoadingRooms = true
    @State private var showCreateDM = false
    @State private var showCreateGroup = false
    @State private var newGroupName = ""
    @State private var directEmail = ""
    @State private var isSearching = false
    
    var body: some View {
        HSplitView {
            // Panel Izquierdo: Lista de Conversaciones
            VStack(spacing: 0) {
                // Header Sidebar
                HStack {
                    HStack(spacing: 8) {
                        Text("C")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(ForkarTheme.primaryGradient)
                            .cornerRadius(5)
                        
                        Text("Chats")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                    }
                    
                    Spacer()
                    
                    Button(action: { showCreateDM = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ForkarTheme.accent)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Nuevo Mensaje Directo o Email (⌘N)")
                    
                    Button(action: { showCreateGroup = true }) {
                        Image(systemName: "person.2.badge.gearshape.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ForkarTheme.accent)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Nuevo Grupo (⇧⌘G)")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(red: 13/255, green: 17/255, blue: 23/255))
                
                Divider().background(ForkarTheme.border)
                
                // Lista de Salas
                if isLoadingRooms {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                    Spacer()
                } else if rooms.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 36))
                            .foregroundColor(ForkarTheme.textMuted)
                        Text("Sin conversaciones")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ForkarTheme.textSub)
                        Button("Iniciar nuevo chat") {
                            showCreateDM = true
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ForkarTheme.accent)
                        Spacer()
                    }
                } else {
                    List(rooms, id: \.id, selection: $selectedRoom) { room in
                        ChatRoomRowView(room: room)
                            .tag(room)
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    }
                    .listStyle(SidebarListStyle())
                }
                
                // Footer Usuario
                Divider().background(ForkarTheme.border)
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(ForkarTheme.primaryGradient)
                            .frame(width: 28, height: 28)
                        Text(String((authManager.currentUser?.user_metadata?.full_name ?? authManager.currentUser?.email ?? "U").prefix(1)).uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authManager.currentUser?.user_metadata?.full_name ?? "Usuario")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                            .lineLimit(1)
                        Text(authManager.currentUser?.email ?? "")
                            .font(.system(size: 10))
                            .foregroundColor(ForkarTheme.textMuted)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: { authManager.logout() }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Cerrar Sesión")
                }
                .padding(12)
                .background(Color(red: 10/255, green: 14/255, blue: 20/255))
            }
            .frame(minWidth: 260, idealWidth: 300, maxWidth: 360)
            
            // Panel Derecho: Detalle del Chat Seleccionado
            ZStack {
                if let activeRoom = selectedRoom {
                    ChatRoomDetailView(room: activeRoom)
                        .id(activeRoom.id)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "message.badge.waveform.fill")
                            .font(.system(size: 54))
                            .foregroundColor(ForkarTheme.accent.opacity(0.6))
                        Text("Selecciona una conversación")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                        Text("Elige un chat de la lista lateral o inicia una conversación con otro usuario por su correo electrónico.")
                            .font(.system(size: 13))
                            .foregroundColor(ForkarTheme.textSub)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                    }
                }
            }
            .frame(minWidth: 500)
        }
        .sheet(isPresented: $showCreateDM) {
            NativeNewDMSheet(isPresented: $showCreateDM) { newRoom in
                Task {
                    await loadRooms()
                    self.selectedRoom = newRoom
                }
            }
        }
        .sheet(isPresented: $showCreateGroup) {
            NativeNewGroupSheet(isPresented: $showCreateGroup) { newRoom in
                Task {
                    await loadRooms()
                    self.selectedRoom = newRoom
                }
            }
        }
        .onAppear {
            Task { await loadRooms() }
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name("CSMSNewDM"), object: nil, queue: .main) { _ in
                showCreateDM = true
            }
            NotificationCenter.default.addObserver(forName: NSNotification.Name("CSMSNewGroup"), object: nil, queue: .main) { _ in
                showCreateGroup = true
            }
        }
    }
    
    private func loadRooms() async {
        do {
            let fetched = try await authManager.fetchChatRooms()
            await MainActor.run {
                self.rooms = fetched
                self.isLoadingRooms = false
                if selectedRoom == nil && !fetched.isEmpty {
                    self.selectedRoom = fetched.first
                }
            }
        } catch {
            await MainActor.run { self.isLoadingRooms = false }
        }
    }
}

// MARK: - Native Direct Message & Email Lookup Sheet
struct NativeNewDMSheet: View {
    @EnvironmentObject var authManager: SupabaseManager
    @Binding var isPresented: Bool
    let onRoomCreated: (ChatRoom) -> Void
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var statusMsg: String? = nil
    
    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Nuevo Mensaje Directo")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                Spacer()
                Button("✕") { isPresented = false }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(ForkarTheme.textSub)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Correo Electrónico del Destinatario")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ForkarTheme.textSub)
                
                TextField("amigo@correo.com", text: $email)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(10)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ForkarTheme.border, lineWidth: 1))
            }
            
            if let status = statusMsg {
                Text(status)
                    .font(.caption)
                    .foregroundColor(status.contains("Error") ? .red : ForkarTheme.accent)
            }
            
            HStack {
                Button("Cancelar") { isPresented = false }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                
                Spacer()
                
                Button(action: startChat) {
                    if isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.7)
                    } else {
                        Text("Iniciar Chat")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(ForkarTheme.accent)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
        .padding(20)
        .frame(width: 380)
        .background(Color(red: 13/255, green: 17/255, blue: 23/255))
    }
    
    private func startChat() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else { return }
        
        isLoading = true
        statusMsg = "Localizando usuario..."
        
        Task {
            do {
                let userFound = try await authManager.findUserByEmail(email: cleanEmail)
                let targetId = userFound?.id ?? UUID()
                let targetName = userFound?.name ?? cleanEmail
                let targetAvatar = userFound?.avatar
                
                let room = try await authManager.getOrCreateDirectChat(with: targetId, targetUserName: targetName, targetUserAvatar: targetAvatar)
                
                await MainActor.run {
                    isLoading = false
                    isPresented = false
                    onRoomCreated(room)
                }
            } catch {
                await MainActor.run {
                    self.statusMsg = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Native New Group Sheet
struct NativeNewGroupSheet: View {
    @EnvironmentObject var authManager: SupabaseManager
    @Binding var isPresented: Bool
    let onGroupCreated: (ChatRoom) -> Void
    
    @State private var groupName = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Crear Nuevo Grupo")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                Spacer()
                Button("✕") { isPresented = false }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(ForkarTheme.textSub)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Nombre del Grupo")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ForkarTheme.textSub)
                
                TextField("Ej: Equipo de Desarrollo", text: $groupName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(10)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ForkarTheme.border, lineWidth: 1))
            }
            
            HStack {
                Button("Cancelar") { isPresented = false }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                
                Spacer()
                
                Button(action: createGroup) {
                    if isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.7)
                    } else {
                        Text("Crear Grupo")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(ForkarTheme.accent)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
        .padding(20)
        .frame(width: 380)
        .background(Color(red: 13/255, green: 17/255, blue: 23/255))
    }
    
    private func createGroup() {
        let name = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        isLoading = true
        Task {
            do {
                let room = try await authManager.createGroupChat(name: name)
                await MainActor.run {
                    isLoading = false
                    isPresented = false
                    onGroupCreated(room)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}
