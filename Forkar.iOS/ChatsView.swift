import SwiftUI

struct ChatsView: View {
    @EnvironmentObject var authManager: SupabaseManager
    
    @State private var rooms: [ChatRoom] = []
    @State private var isLoading = false
    @State private var showCreateGroup = false
    @State private var newGroupName = ""
    @State private var isCreatingGroup = false
    @State private var showLogin = false
    @StateObject private var securityManager = SecurityAndNotificationManager.shared
    @State private var isFaceIDUnlocked = false
    
    var body: some View {
        MultiplatformNavigationStack {
            ZStack {
                ForkarTheme.bg
                    .ignoresSafeArea()
                XtrapsBackground(strokeColor: ForkarTheme.accent, opacity: 0.65)
                    .ignoresSafeArea()
                
                if authManager.isLoggedIn {
                    if isFaceIDUnlocked {
                        ScrollView {
                            VStack(spacing: 16) {
                                if isLoading && rooms.isEmpty {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                                        Spacer()
                                    }
                                    .padding()
                                } else if rooms.isEmpty {
                                    VStack(spacing: 20) {
                                        Image(systemName: "message.and.waveform.fill")
                                            .font(.system(size: 64))
                                            .foregroundColor(ForkarTheme.textSub)
                                        Text("Bandeja de Entrada Vacía")
                                            .font(.title3.bold())
                                            .foregroundColor(ForkarTheme.text)
                                        Text("Comienza un chat directo con otro usuario en sus posts o crea un grupo de chat con tus amigos.")
                                            .font(.subheadline)
                                            .foregroundColor(ForkarTheme.textSub)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 40)
                                    }
                                    .padding(.vertical, 80)
                                } else {
                                    ForEach(rooms) { room in
                                        NavigationLink(destination: ChatRoomDetailView(room: room).environmentObject(authManager)) {
                                            ChatRoomRowView(room: room)
                                                .environmentObject(authManager)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal)
                                        .contextMenu {
                                            if room.created_by == authManager.currentUser?.id && !CSMSCanonicalRooms.isProtected(roomId: room.id) {
                                                Button(role: .destructive) {
                                                    deleteRoom(room)
                                                } label: {
                                                    Label("Eliminar Conversación", systemImage: "trash")
                                                }
                                            }
                                        }
                                        #if os(iOS)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            if room.created_by == authManager.currentUser?.id && !CSMSCanonicalRooms.isProtected(roomId: room.id) {
                                                Button(role: .destructive) {
                                                    deleteRoom(room)
                                                } label: {
                                                    Label("Eliminar", systemImage: "trash")
                                                }
                                            }
                                        }
                                        #endif
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                        .refreshable {
                            await loadRooms()
                        }
                    } else {
                        // Face ID Locked State Overlay
                        VStack(spacing: 24) {
                            Image(systemName: "faceid")
                                .font(.system(size: 72))
                                .foregroundColor(ForkarTheme.accent)
                            
                            VStack(spacing: 8) {
                                Text("Chats Privados Protegidos")
                                    .font(.title2.bold())
                                    .foregroundColor(ForkarTheme.text)
                                Text("Se requiere Face ID / Touch ID para ver tus conversaciones privadas en Forkar.")
                                    .font(.subheadline)
                                    .foregroundColor(ForkarTheme.textSub)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            
                            Button(action: unlockChats) {
                                HStack {
                                    Image(systemName: "lock.open.fill")
                                    Text("Desbloquear con Face ID")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 28)
                                .background(ForkarTheme.primaryGradient)
                                .cornerRadius(14)
                                .shadow(color: ForkarTheme.accent.opacity(0.4), radius: 10, y: 4)
                            }
                        }
                        .padding(32)
                        .liquidGlass(cornerRadius: 20, glowColor: ForkarTheme.accent)
                        .padding(.horizontal, 20)
                        .onAppear {
                            unlockChats()
                        }
                    }
                } else {
                    // Not logged in state
                    VStack(spacing: 24) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 72))
                            .foregroundColor(ForkarTheme.textSub)
                        
                        VStack(spacing: 8) {
                            Text("Mensajería Privada")
                                .font(.title2.bold())
                                .foregroundColor(ForkarTheme.text)
                            
                            Text("Inicia sesión para poder enviar mensajes privados y crear grupos de chat con otros desarrolladores.")
                                .font(.subheadline)
                                .foregroundColor(ForkarTheme.textSub)
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
                    .sheet(isPresented: $showLogin, onDismiss: {
                        if authManager.isLoggedIn {
                            Task {
                                await loadRooms()
                            }
                        }
                    }) {
                        NavigationStack {
                            LoginView()
                                .environmentObject(authManager)
                        }
                        #if os(macOS)
                        .frame(minWidth: 460, idealWidth: 500, maxWidth: 600, minHeight: 560, idealHeight: 640)
                        #endif
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                if authManager.isLoggedIn && isFaceIDUnlocked {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showCreateGroup = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Crear Grupo")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ForkarTheme.accent)
                        }
                    }
                    #else
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            showCreateGroup = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Crear Grupo")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ForkarTheme.accent)
                        }
                    }
                    #endif
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupSheetView(
                    isPresented: $showCreateGroup,
                    groupName: $newGroupName,
                    isCreating: $isCreatingGroup,
                    onCreate: {
                        createGroup()
                    }
                )
            }
            .onAppear {
                if authManager.isLoggedIn && isFaceIDUnlocked {
                    Task {
                        await loadRooms()
                    }
                }
            }
        }
    }
    
    private func unlockChats() {
        securityManager.authenticateBiometrics { success in
            self.isFaceIDUnlocked = success
            if success {
                Task {
                    await loadRooms()
                }
            }
        }
    }
    
    private func loadRooms() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let fetched = try await authManager.fetchChatRooms()
            await MainActor.run {
                self.rooms = fetched
                self.isLoading = false
            }
        } catch {
            print("Error loading chat rooms: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func deleteRoom(_ room: ChatRoom) {
        Task {
            do {
                try await authManager.deleteChatRoom(roomId: room.id)
                await MainActor.run {
                    withAnimation {
                        self.rooms.removeAll { $0.id == room.id }
                    }
                }
            } catch {
                print("Error deleting room: \(error.localizedDescription)")
            }
        }
    }
    
    private func createGroup() {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        isCreatingGroup = true
        Task {
            do {
                let _ = try await authManager.createGroupChat(name: name)
                await MainActor.run {
                    self.newGroupName = ""
                    self.isCreatingGroup = false
                    self.showCreateGroup = false
                }
                await loadRooms()
            } catch {
                print("Error creating group: \(error.localizedDescription)")
                await MainActor.run {
                    self.isCreatingGroup = false
                }
            }
        }
    }
}

struct ChatRoomRowView: View {
    @EnvironmentObject var authManager: SupabaseManager
    let room: ChatRoom
    @State private var displayName: String = ""
    @State private var initials: String = "?"
    @State private var avatarUrl: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            if room.is_group {
                // Group Icon
                ZStack {
                    Circle()
                        .fill(ForkarTheme.accent.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ForkarTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name ?? "Grupo de Chat")
                        .font(.headline)
                        .foregroundColor(ForkarTheme.text)
                    
                    Text("Grupo Privado • E2EE")
                        .font(.caption)
                        .foregroundColor(ForkarTheme.textSub)
                }
            } else {
                // Direct Message Icon with resolved avatar
                ZStack {
                    if let urlStr = avatarUrl ?? room.displayAvatar, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                            default:
                                fallbackAvatarView
                            }
                        }
                        .frame(width: 48, height: 48)
                    } else {
                        fallbackAvatarView
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(displayName.isEmpty ? room.displayName : displayName)
                            .font(.headline)
                            .foregroundColor(ForkarTheme.text)
                            .lineLimit(1)
                        
                        // Hardware E2EE Protected Badge
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 11))
                            .foregroundColor(ForkarTheme.green)
                    }
                    
                    Text("Mensaje Directo • E2EE")
                        .font(.caption)
                        .foregroundColor(ForkarTheme.textSub)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ForkarTheme.textSub)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 14, glowColor: room.is_group ? ForkarTheme.accent2 : ForkarTheme.accent)
        .onAppear {
            self.displayName = room.displayName
            self.initials = room.initials
            self.avatarUrl = room.displayAvatar
            if !room.is_group && (room.directContactName == nil || room.directContactName?.isEmpty == true) {
                Task {
                    await loadPartnerInfo()
                }
            }
        }
    }
    
    private var fallbackAvatarView: some View {
        ZStack {
            Circle()
                .fill(ForkarTheme.primaryGradient)
                .frame(width: 48, height: 48)
            
            Text(initials.isEmpty ? room.initials : initials)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private func loadPartnerInfo() async {
        do {
            let members = try await authManager.fetchRoomMembers(roomId: room.id)
            if let partner = members.first(where: { $0.user_id != authManager.currentUser?.id }),
               !partner.user_name.isEmpty {
                await MainActor.run {
                    self.displayName = partner.user_name
                    self.initials = partner.initials
                    self.avatarUrl = partner.user_avatar
                }
            }
        } catch {
            print("Error loading partner info: \(error.localizedDescription)")
        }
    }
}

struct CreateGroupSheetView: View {
    @Binding var isPresented: Bool
    @Binding var groupName: String
    @Binding var isCreating: Bool
    let onCreate: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                ForkarTheme.bg
                    .ignoresSafeArea()
                XtrapsBackground(strokeColor: ForkarTheme.accent.opacity(0.12))
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre del Grupo")
                            .font(.headline)
                            .foregroundColor(ForkarTheme.text)
                        
                        TextField("Ej. Club de Lectura, Hacks, etc.", text: $groupName)
                            .padding()
                            .background(ForkarTheme.card)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ForkarTheme.border, lineWidth: 1)
                            )
                            .disabled(isCreating)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        onCreate()
                    }) {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Crear Grupo")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Nuevo Grupo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                    .foregroundColor(ForkarTheme.textSub)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, idealWidth: 500, minHeight: 340, idealHeight: 380)
        #endif
    }
}
