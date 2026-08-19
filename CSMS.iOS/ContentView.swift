import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: SupabaseManager
    
    @State private var rooms: [CSMSChatRoom] = []
    @State private var isLoading = false
    @State private var showCreateGroup = false
    @State private var newGroupName = ""
    @State private var isCreating = false
    @State private var showLogin = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ForkarTheme.bg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Bar
                    if let user = manager.currentUser {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(ForkarTheme.primaryGradient)
                                    .frame(width: 36, height: 36)
                                Text(user.email?.prefix(1).uppercased() ?? "U")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.user_metadata?.full_name ?? user.email ?? "Usuario")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ForkarTheme.text)
                                Text(user.email ?? "")
                                    .font(.system(size: 11))
                                    .foregroundColor(ForkarTheme.textSub)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                manager.logout()
                            }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 15))
                                    .foregroundColor(ForkarTheme.textSub)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.04))
                    }
                    
                    if !manager.isLoggedIn {
                        Spacer()
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ForkarTheme.accent.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(ForkarTheme.accent)
                            }
                            
                            Text("Inicia sesión en CSMS")
                                .font(.title3.bold())
                                .foregroundColor(ForkarTheme.text)
                            
                            Text("Para sincronizar tus chats con Forkar y Apple Watch, inicia sesión con tu cuenta de Coki Studios.")
                                .font(.subheadline)
                                .foregroundColor(ForkarTheme.textSub)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: { showLogin = true }) {
                                HStack {
                                    Image(systemName: "person.badge.key.fill")
                                    Text("Iniciar Sesión")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 28)
                                .background(ForkarTheme.accent)
                                .cornerRadius(14)
                                .shadow(color: ForkarTheme.accent.opacity(0.3), radius: 10, y: 4)
                            }
                            .padding(.top, 8)
                        }
                        Spacer()
                    } else if isLoading && rooms.isEmpty {
                        Spacer()
                        ProgressView("Cargando salas CSMS...")
                            .tint(ForkarTheme.accent)
                            .foregroundColor(ForkarTheme.textSub)
                        Spacer()
                    } else if rooms.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ForkarTheme.accent.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(ForkarTheme.accent)
                            }
                            
                            Text("No hay conversaciones")
                                .font(.title3.bold())
                                .foregroundColor(ForkarTheme.text)
                            
                            Text("Crea un grupo de chat CSMS con el botón (+) superior para comenzar.")
                                .font(.subheadline)
                                .foregroundColor(ForkarTheme.textSub)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(rooms) { room in
                                    NavigationLink(destination: ConversationView(room: room)) {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                Circle()
                                                    .fill(ForkarTheme.primaryGradient)
                                                    .frame(width: 48, height: 48)
                                                
                                                Image(systemName: room.is_group == true ? "person.2.fill" : "message.fill")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(room.displayName)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(ForkarTheme.text)
                                                
                                                Text(room.is_group == true ? "Grupo CSMS" : "Mensaje Directo")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(ForkarTheme.textSub)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(ForkarTheme.textMuted)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .liquidGlass(cornerRadius: 16, glowColor: ForkarTheme.accent)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .refreshable {
                            await loadRooms()
                        }
                    }
                }
            }
            .navigationTitle("CSMS Chats")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(ForkarTheme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if manager.isLoggedIn {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showCreateGroup = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(ForkarTheme.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showLogin) {
                LoginView()
                    .environmentObject(manager)
            }
            .sheet(isPresented: $showCreateGroup) {
                NavigationStack {
                    ZStack {
                        ForkarTheme.bg.ignoresSafeArea()
                        
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nombre del Grupo")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ForkarTheme.textSub)
                                
                                TextField("Ej: Amigos Forkar, CS Devs...", text: $newGroupName)
                                    .padding(14)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .foregroundColor(ForkarTheme.text)
                            }
                            .padding(.top, 20)
                            
                            Button(action: createGroup) {
                                HStack {
                                    if isCreating {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "plus.bubble.fill")
                                        Text("Crear Sala CSMS")
                                    }
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(newGroupName.isEmpty ? Color.gray.opacity(0.3) : ForkarTheme.accent)
                                .cornerRadius(14)
                            }
                            .disabled(newGroupName.isEmpty || isCreating)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    .navigationTitle("Nuevo Grupo CSMS")
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") { showCreateGroup = false }
                                .foregroundColor(ForkarTheme.textSub)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .task {
                await loadRooms()
            }
        }
    }
    
    private func loadRooms() async {
        isLoading = true
        if let list = try? await manager.fetchChatRooms() {
            self.rooms = list
        }
        isLoading = false
    }
    
    private func createGroup() {
        guard !newGroupName.isEmpty else { return }
        isCreating = true
        Task {
            _ = try? await manager.createGroupChat(name: newGroupName)
            newGroupName = ""
            isCreating = false
            showCreateGroup = false
            await loadRooms()
        }
    }
}

// MARK: - Conversation View
struct ConversationView: View {
    @EnvironmentObject var manager: SupabaseManager
    let room: CSMSChatRoom
    
    @State private var messages: [CSMSChatMessage] = []
    @State private var typedText = ""
    @State private var timer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            ForkarTheme.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty {
                                VStack(spacing: 8) {
                                    Text("Esta sala está lista.")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(ForkarTheme.text)
                                    Text("Escribe el primer mensaje para chatear en tiempo real.")
                                        .font(.system(size: 12))
                                        .foregroundColor(ForkarTheme.textSub)
                                }
                                .padding(.vertical, 40)
                            } else {
                                ForEach(messages) { msg in
                                    let currentUserIdString = manager.currentUser?.id.uuidString ?? ""
                                    let isMine = msg.sender_id == currentUserIdString
                                    
                                    HStack {
                                        if isMine { Spacer() }
                                        
                                        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                                            Text(msg.content)
                                                .font(.system(size: 15))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .foregroundColor(.white)
                                                .background(
                                                    isMine
                                                    ? ForkarTheme.accent
                                                    : Color(white: 0.16)
                                                )
                                                .cornerRadius(18)
                                        }
                                        .id(msg.id)
                                        
                                        if !isMine { Spacer() }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Bar
                HStack(spacing: 10) {
                    TextField("Escribe un mensaje...", text: $typedText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(20)
                        .foregroundColor(ForkarTheme.text)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : ForkarTheme.accent)
                            .clipShape(Circle())
                    }
                    .disabled(typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
            }
        }
        .navigationTitle(room.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadMessages()
        }
        .onReceive(timer) { _ in
            Task { await loadMessages() }
        }
    }
    
    private func loadMessages() async {
        if let list = try? await manager.fetchChatMessages(roomId: room.id) {
            self.messages = list
        }
    }
    
    private func sendMessage() {
        let text = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        typedText = ""
        Task {
            _ = try? await manager.sendMessage(roomId: room.id, content: text)
            await loadMessages()
        }
    }
}
