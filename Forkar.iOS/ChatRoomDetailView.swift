import SwiftUI
import Combine

struct ChatRoomDetailView: View {
    @EnvironmentObject var authManager: SupabaseManager
    let room: ChatRoom
    
    @State private var messages: [ChatMessage] = []
    @State private var newMessageText = ""
    @State private var isSending = false
    @State private var isLoading = true
    @State private var partnerName: String = "Cargando..."
    
    // Timer to pull new messages every 3 seconds
    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    @State private var showInviteSheet = false
    @State private var communityUsers: [CommunityUser] = []
    @State private var isLoadingUsers = false
    
    @State private var activeChatRoom: ChatRoom? = nil
    @State private var navigateToChat = false
    
    var body: some View {
        ZStack {
            ForkarTheme.bg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (if direct chat, shows partner's name)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(room.is_group ? room.displayName : partnerName)
                            .font(.headline)
                            .foregroundColor(ForkarTheme.text)
                        
                        Text(room.is_group ? "Grupo de Chat" : "Mensaje Privado")
                            .font(.caption)
                            .foregroundColor(ForkarTheme.textSub)
                    }
                    Spacer()
                }
                .padding()
                .background(ForkarTheme.card)
                .overlay(
                    VStack {
                        Spacer()
                        Divider().background(ForkarTheme.border)
                    }
                )
                
                // Message List
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                    Spacer()
                } else if messages.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 44))
                            .foregroundColor(ForkarTheme.textSub)
                        Text("No hay mensajes")
                            .font(.headline)
                            .foregroundColor(ForkarTheme.text)
                        Text("¡Escribe el primer mensaje para iniciar la conversación!")
                            .font(.subheadline)
                            .foregroundColor(ForkarTheme.textSub)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollViewReader { scrollView in
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(messages) { message in
                                    MessageBubbleView(message: message, isCurrentUser: message.user_id == authManager.currentUser?.id)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onAppear {
                            if let last = messages.last {
                                scrollView.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: messages) { oldValue, newValue in
                            if let last = newValue.last {
                                withAnimation {
                                    scrollView.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Message Input Area
                HStack(spacing: 12) {
                    TextField("Escribe un mensaje...", text: $newMessageText)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(ForkarTheme.card)
                        .foregroundColor(ForkarTheme.text)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(ForkarTheme.border, lineWidth: 1)
                        )
                        .disabled(isSending)
                    
                    Button(action: {
                        sendCurrentMessage()
                    }) {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(10)
                    .background(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : ForkarTheme.accent)
                    .clipShape(Circle())
                    .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .padding()
                .background(ForkarTheme.card)
                .overlay(
                    VStack {
                        Divider().background(ForkarTheme.border)
                        Spacer()
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if room.is_group {
                    Button(action: {
                        showInviteSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(ForkarTheme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteUsersSheetView(roomId: room.id, communityUsers: $communityUsers, isLoading: $isLoadingUsers, onInvite: { user in
                inviteUser(user)
            })
            .environmentObject(authManager)
            .onAppear {
                Task {
                    await loadCommunityUsers()
                }
            }
        }
        .onAppear {
            Task {
                await loadInitialData()
            }
        }
        .onReceive(timer) { _ in
            Task {
                await loadMessagesSilently()
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "mention" {
                let username = url.host ?? ""
                openDirectChat(withUsername: username)
                return .handled
            }
            return .systemAction
        })
        .background(
            NavigationLink(
                destination: Group {
                    if let room = activeChatRoom {
                        ChatRoomDetailView(room: room)
                            .environmentObject(authManager)
                    }
                },
                isActive: $navigateToChat,
                label: { EmptyView() }
            )
        )
    }
    
    private func loadInitialData() async {
        await loadMessages()
        if !room.is_group {
            await loadPartnerName()
        }
    }
    
    private func loadMessages() async {
        do {
            let fetched = try await authManager.fetchMessages(roomId: room.id)
            await MainActor.run {
                self.messages = fetched
                self.isLoading = false
            }
        } catch {
            print("Error loading messages: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func loadMessagesSilently() async {
        do {
            let fetched = try await authManager.fetchMessages(roomId: room.id)
            await MainActor.run {
                if fetched.count != self.messages.count {
                    self.messages = fetched
                }
            }
        } catch {
            print("Error silently refreshing messages: \(error.localizedDescription)")
        }
    }
    
    private func loadPartnerName() async {
        do {
            let members = try await authManager.fetchRoomMembers(roomId: room.id)
            if let partner = members.first(where: { $0.user_id != authManager.currentUser?.id }) {
                await MainActor.run {
                    self.partnerName = partner.user_name
                }
            } else {
                await MainActor.run {
                    self.partnerName = "Chat Privado"
                }
            }
        } catch {
            print("Error loading partner name: \(error.localizedDescription)")
        }
    }
    
    private func sendCurrentMessage() {
        let content = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        isSending = true
        newMessageText = ""
        
        Task {
            do {
                let newMsg = try await authManager.sendMessage(roomId: room.id, content: content)
                await MainActor.run {
                    self.messages.append(newMsg)
                    self.isSending = false
                }
            } catch {
                print("Error sending message: \(error.localizedDescription)")
                await MainActor.run {
                    self.isSending = false
                }
            }
        }
    }
    
    private func loadCommunityUsers() async {
        isLoadingUsers = true
        do {
            let posts = try await authManager.fetchPosts()
            let members = try await authManager.fetchRoomMembers(roomId: room.id)
            let memberIds = Set(members.map { $0.user_id })
            
            // Filter out logged in user, current group members, and duplicate post authors
            let unique = posts.reduce(into: [CommunityUser]()) { result, post in
                if post.user_id != authManager.currentUser?.id &&
                   !memberIds.contains(post.user_id) &&
                   !result.contains(where: { $0.id == post.user_id }) {
                    result.append(CommunityUser(id: post.user_id, name: post.author_name, avatar: post.author_avatar))
                }
            }
            await MainActor.run {
                self.communityUsers = unique
                self.isLoadingUsers = false
            }
        } catch {
            print("Error loading community users: \(error)")
            await MainActor.run {
                self.isLoadingUsers = false
            }
        }
    }
    
    private func inviteUser(_ user: CommunityUser) {
        Task {
            do {
                try await authManager.inviteUserToGroup(roomId: room.id, userId: user.id, userName: user.name, userAvatar: user.avatar)
            } catch {
                print("Error inviting user: \(error.localizedDescription)")
            }
        }
    }
    
    private func openDirectChat(withUsername name: String) {
        Task {
            do {
                if let target = try await authManager.findUserByName(name: name) {
                    let room = try await authManager.getOrCreateDirectChat(with: target.id, targetUserName: name, targetUserAvatar: target.avatar)
                    await MainActor.run {
                        self.activeChatRoom = room
                        self.navigateToChat = true
                    }
                }
            } catch {
                print("Error opening direct chat from mention: \(error)")
            }
        }
    }
}

// MARK: - Invite Users Sheet Component
struct InviteUsersSheetView: View {
    let roomId: UUID
    @Binding var communityUsers: [CommunityUser]
    @Binding var isLoading: Bool
    let onInvite: (CommunityUser) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var invitedUserIds: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                ForkarTheme.bg
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                } else if communityUsers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundColor(ForkarTheme.textSub)
                        Text("No hay usuarios para invitar")
                            .font(.headline)
                            .foregroundColor(ForkarTheme.text)
                        Text("Todos los usuarios activos ya son miembros de este grupo.")
                            .font(.subheadline)
                            .foregroundColor(ForkarTheme.textSub)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(communityUsers) { user in
                            HStack {
                                CircleAvatarPlaceholder(initials: user.name.prefix(1).uppercased())
                                    .frame(width: 36, height: 36)
                                    .font(.system(size: 14, weight: .bold))
                                
                                Text(user.name)
                                    .font(.body)
                                    .foregroundColor(ForkarTheme.text)
                                
                                Spacer()
                                
                                Button(action: {
                                    invitedUserIds.insert(user.id)
                                    onInvite(user)
                                }) {
                                    Text(invitedUserIds.contains(user.id) ? "Invitado" : "Invitar")
                                        .font(.system(size: 12, weight: .bold))
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(invitedUserIds.contains(user.id) ? Color.gray : ForkarTheme.accent)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .disabled(invitedUserIds.contains(user.id))
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Invitar al Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(ForkarTheme.textSub)
                }
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool

    var formattedContent: LocalizedStringKey {
        let pattern = "@([a-zA-Z0-9_]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return LocalizedStringKey(message.content)
        }
        let text = message.content
        let range = NSRange(text.startIndex..., in: text)
        let markdown = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "[$0](mention:$1)")
        return LocalizedStringKey(markdown)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isCurrentUser {
                CircleAvatarPlaceholder(initials: message.initials)
            } else {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.author_name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ForkarTheme.textSub)
                }
                
                Text(formattedContent)
                    .font(.system(size: 14))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(isCurrentUser ? ForkarTheme.accent : ForkarTheme.card)
                    .foregroundColor(isCurrentUser ? .white : ForkarTheme.text)
                    .cornerRadius(16, corners: isCurrentUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isCurrentUser ? Color.clear : ForkarTheme.border, lineWidth: 1)
                    )
                
                Text(message.formattedTime)
                    .font(.system(size: 9))
                    .foregroundColor(ForkarTheme.textMuted)
            }
            
            if isCurrentUser {
                CircleAvatarPlaceholder(initials: message.initials)
            } else {
                Spacer()
            }
        }
    }
}

// MARK: - Rounded Corner Helper Extension
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
