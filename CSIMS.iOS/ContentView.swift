import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: SupabaseManager
    
    @State private var channels: [CSIMSChatRoom] = []
    @State private var selectedChannel: CSIMSChatRoom? = nil
    @State private var messages: [CSIMSMessage] = []
    @State private var typedMessage: String = ""
    @State private var isSending: Bool = false
    @State private var showLogin: Bool = false
    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""
    @State private var authErrorMessage: String? = nil
    @State private var isAuthenticating: Bool = false
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .tint(ForkarTheme.accent)
        .onAppear {
            Task {
                await loadChannels()
            }
        }
    }
    
    // MARK: - Sidebar
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ForkarTheme.primaryGradient)
                        .frame(width: 32, height: 32)
                    Text("CS")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("CSIMS Internal")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(ForkarTheme.green)
                            .frame(width: 6, height: 6)
                        Text("Zero Trust Active")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ForkarTheme.green)
                    }
                }
                Spacer()
            }
            .padding(16)
            
            Divider().background(ForkarTheme.border)
            
            // Channels List
            List(channels, selection: $selectedChannel) { channel in
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(selectedChannel?.id == channel.id ? ForkarTheme.accent : ForkarTheme.textSub)
                    
                    Text(channel.name)
                        .font(.system(size: 13, weight: selectedChannel?.id == channel.id ? .bold : .medium))
                        .foregroundColor(selectedChannel?.id == channel.id ? ForkarTheme.text : ForkarTheme.textSub)
                    
                    Spacer()
                    
                    Text("E2EE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ForkarTheme.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ForkarTheme.green.opacity(0.12))
                        .cornerRadius(4)
                }
                .tag(channel)
            }
            .listStyle(.sidebar)
            
            Divider().background(ForkarTheme.border)
            
            // User Footer
            if let user = manager.currentUser {
                HStack(spacing: 10) {
                    Circle()
                        .fill(ForkarTheme.primaryGradient)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text(user.email?.prefix(1).uppercased() ?? "C")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(user.user_metadata?.full_name ?? user.email ?? "")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.text)
                            .lineLimit(1)
                        Text(user.email ?? "")
                            .font(.system(size: 10))
                            .foregroundColor(ForkarTheme.textSub)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: { manager.logout() }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(ForkarTheme.textSub)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(ForkarTheme.card)
            } else {
                Button(action: { showLogin = true }) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                        Text("Acceso @cokistudios.com")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(12)
            }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        .background(ForkarTheme.bg)
    }
    
    // MARK: - Detail Chat Content
    private var detailContent: some View {
        ZStack {
            ForkarTheme.bg.ignoresSafeArea()
            
            if let channel = selectedChannel {
                VStack(spacing: 0) {
                    // Chat Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("# \(channel.name)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(ForkarTheme.text)
                                
                                Text("🔒 AES-256-GCM")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(ForkarTheme.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ForkarTheme.green.opacity(0.12))
                                    .cornerRadius(6)
                            }
                            Text(CSIMSEncryption.shared.hardwareSecurityBadge)
                                .font(.system(size: 10))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(ForkarTheme.card)
                    
                    Divider().background(ForkarTheme.border)
                    
                    // Messages Scroll
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { msg in
                                    messageRow(msg)
                                }
                            }
                            .padding(20)
                        }
                        .onChange(of: messages.count) { _ in
                            if let last = messages.last {
                                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                            }
                        }
                    }
                    
                    Divider().background(ForkarTheme.border)
                    
                    // Input Bar
                    HStack(spacing: 12) {
                        TextField("Mensaje cifrado para el equipo...", text: $typedMessage)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(ForkarTheme.card)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ForkarTheme.border, lineWidth: 1))
                            .onSubmit {
                                Task { await sendCurrentMessage() }
                            }
                        
                        Button(action: {
                            Task { await sendCurrentMessage() }
                        }) {
                            HStack(spacing: 4) {
                                if isSending {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Enviar")
                                }
                            }
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(ForkarTheme.primaryGradient)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(typedMessage.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                    }
                    .padding(14)
                    .background(ForkarTheme.card.opacity(0.5))
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 48))
                        .foregroundColor(ForkarTheme.textSub)
                    Text("Selecciona un canal interno")
                        .font(.headline)
                        .foregroundColor(ForkarTheme.text)
                    Text("Comunicaciones de equipo cifradas de extremo a extremo.")
                        .font(.subheadline)
                        .foregroundColor(ForkarTheme.textSub)
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            loginSheet
        }
    }
    
    private func messageRow(_ msg: CSIMSMessage) -> some View {
        let isMine = msg.user_id == manager.currentUser?.id.uuidString.lowercased()
        return HStack {
            if isMine { Spacer() }
            
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(msg.author_name)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ForkarTheme.textSub)
                    if msg.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(ForkarTheme.green)
                    }
                }
                
                Text(msg.content)
                    .font(.system(size: 13))
                    .foregroundColor(ForkarTheme.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isMine ? ForkarTheme.accent.opacity(0.3) : ForkarTheme.card)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isMine ? ForkarTheme.accent.opacity(0.4) : ForkarTheme.border, lineWidth: 1))
            }
            
            if !isMine { Spacer() }
        }
        .id(msg.id)
    }
    
    // MARK: - Login Sheet
    private var loginSheet: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                .font(.system(size: 48))
                .foregroundColor(ForkarTheme.accent)
            
            VStack(spacing: 6) {
                Text("Autenticación Zero Trust")
                    .font(.title2.bold())
                    .foregroundColor(ForkarTheme.text)
                Text("Solo los correos corporativos @cokistudios.com están autorizados para acceder a CSIMS.")
                    .font(.caption)
                    .foregroundColor(ForkarTheme.textSub)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                TextField("nombre@cokistudios.com", text: $emailInput)
                    .padding(12)
                    .background(ForkarTheme.card)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ForkarTheme.border, lineWidth: 1))
                
                SecureField("Contraseña", text: $passwordInput)
                    .padding(12)
                    .background(ForkarTheme.card)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ForkarTheme.border, lineWidth: 1))
            }
            
            if let err = authErrorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button(action: {
                Task {
                    isAuthenticating = true
                    authErrorMessage = nil
                    do {
                        try await manager.login(email: emailInput, pass: passwordInput)
                        showLogin = false
                    } catch {
                        authErrorMessage = error.localizedDescription
                    }
                    isAuthenticating = false
                }
            }) {
                HStack {
                    if isAuthenticating {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Text("Verificar y Acceder")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isAuthenticating)
            
            Button("Cancelar") {
                showLogin = false
            }
            .foregroundColor(ForkarTheme.textSub)
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 380)
        .background(ForkarTheme.bg)
    }
    
    // MARK: - Actions
    private func loadChannels() async {
        do {
            channels = try await manager.fetchInternalChannels()
            if selectedChannel == nil {
                selectedChannel = channels.first
            }
            if let first = selectedChannel {
                messages = try await manager.fetchMessages(roomId: first.id)
            }
        } catch {
            print("Error cargando canales CSIMS: \(error)")
        }
    }
    
    private func sendCurrentMessage() async {
        guard let channel = selectedChannel else { return }
        let text = typedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isSending = true
        do {
            let newMsg = try await manager.sendMessage(roomId: channel.id, content: text)
            messages.append(newMsg)
            typedMessage = ""
        } catch {
            print("Error enviando en CSIMS: \(error)")
        }
        isSending = false
    }
}
