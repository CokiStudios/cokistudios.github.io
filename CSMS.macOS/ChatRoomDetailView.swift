import SwiftUI
internal import Combine

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
    @State private var knownNames: [String] = []
    
    var body: some View {
        ZStack {
            ForkarTheme.bg
                .ignoresSafeArea()
            XtrapsBackground(strokeColor: ForkarTheme.accent.opacity(0.12))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (if direct chat, shows partner's name) con Liquid Glass
                HStack {
                    ZStack {
                        Circle()
                            .fill(ForkarTheme.primaryGradient)
                            .frame(width: 36, height: 36)
                        Text(String((room.is_group ? room.displayName : partnerName).prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
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
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                )
                .overlay(
                    VStack {
                        Spacer()
                        Rectangle().fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.indigo.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        ).frame(height: 1)
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
                                    MessageBubbleView(message: message, isCurrentUser: message.user_id == authManager.currentUser?.id, knownNames: knownNames)
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
                        .onChange(of: messages.count) { _ in
                            if let last = messages.last {
                                withAnimation {
                                    scrollView.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Message Input Area con Liquid Glass
                HStack(spacing: 12) {
                    TextField("Escribe un mensaje...", text: $newMessageText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(ForkarTheme.text)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .disabled(isSending)
                    
                    Button(action: {
                        sendCurrentMessage()
                    }) {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 38, height: 38)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : ForkarTheme.accent)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.0)
                                )
                                .shadow(color: newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : ForkarTheme.accent.opacity(0.5), radius: 8, y: 3)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                )
                .overlay(
                    VStack {
                        Rectangle().fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.indigo.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        ).frame(height: 1)
                        Spacer()
                    }
                )
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
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
            #else
            ToolbarItem(placement: .primaryAction) {
                if room.is_group {
                    Button(action: {
                        showInviteSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(ForkarTheme.accent)
                    }
                }
            }
            #endif
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
        updateKnownNames()
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
                    updateKnownNames()
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
        // First clean the username from URL escaping (e.g. %20 -> space)
        let cleanName = name.removingPercentEncoding ?? name
        Task {
            do {
                if let target = try await authManager.findUserByName(name: cleanName) {
                    let room = try await authManager.getOrCreateDirectChat(with: target.id, targetUserName: cleanName, targetUserAvatar: target.avatar)
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
    
    private func updateKnownNames() {
        var names = knownNames
        for msg in messages {
            if !names.contains(msg.author_name) {
                names.append(msg.author_name)
            }
        }
        if !room.is_group && partnerName != "Cargando..." && !names.contains(partnerName) {
            names.append(partnerName)
        }
        for u in communityUsers {
            if !names.contains(u.name) {
                names.append(u.name)
            }
        }
        if names.count != knownNames.count {
            self.knownNames = names
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
                XtrapsBackground(strokeColor: ForkarTheme.accent.opacity(0.12))
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(ForkarTheme.textSub)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(ForkarTheme.textSub)
                }
                #endif
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let knownNames: [String]

    var formattedContent: LocalizedStringKey {
        var formatted = message.content
        let sortedNames = knownNames.sorted { $0.count > $1.count }
        for name in sortedNames {
            let mentionTag = "@\(name)"
            if formatted.contains(mentionTag) {
                let escapedName = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? name
                formatted = formatted.replacingOccurrences(of: mentionTag, with: "[\(mentionTag)](mention:\(escapedName))")
            }
        }
        
        // Alphanumeric fallback regex for single words
        let pattern = "@([a-zA-Z0-9_]+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(formatted.startIndex..., in: formatted)
            formatted = regex.stringByReplacingMatches(in: formatted, options: [], range: range, withTemplate: "[$0](mention:$1)")
        }
        
        return LocalizedStringKey(formatted)
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
                
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 6) {
                    if !message.content.isEmpty {
                        Text(formattedContent)
                            .font(.system(size: 14))
                    }
                    
                    // 📎 Media Attachments
                    if let mediaUrl = message.media_url, let url = URL(string: mediaUrl) {
                        let type = message.media_type ?? (mediaUrl.hasSuffix(".mp4") || mediaUrl.hasSuffix(".mov") ? "video" : "image")
                        if type == "image" {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 240, maxHeight: 200)
                                    .cornerRadius(10)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            }
                        } else if type == "video" {
                            Link(destination: url) {
                                HStack(spacing: 6) {
                                    Image(systemName: "video.fill")
                                    Text("Reproducir Video")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                            }
                        } else {
                            Link(destination: url) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.fill")
                                    Text("Descargar Archivo")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    ZStack {
                        if isCurrentUser {
                            ForkarTheme.primaryGradient
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Rectangle().fill(.ultraThinMaterial)
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .foregroundColor(isCurrentUser ? .white : ForkarTheme.text)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: isCurrentUser ? [Color.white.opacity(0.5), Color.white.opacity(0.1)] : [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: isCurrentUser ? ForkarTheme.accent.opacity(0.35) : Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 4)
                
                Text(message.formattedTime)
                    .font(.system(size: 9))
                    .foregroundColor(ForkarTheme.textMuted)
                    .padding(.horizontal, 6)
            }
            
            if isCurrentUser {
                CircleAvatarPlaceholder(initials: message.initials)
            } else {
                Spacer()
            }
        }
    }
}

// MARK: - Rounded Corner Helper Extension (Pure SwiftUI, Platform-Agnostic)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        let tr = min(min(self.radius, height/2), width/2)
        let tl = min(min(self.radius, height/2), width/2)
        let bl = min(min(self.radius, height/2), width/2)
        let br = min(min(self.radius, height/2), width/2)
        
        let hasTopLeft = corners.contains(.topLeft)
        let hasTopRight = corners.contains(.topRight)
        let hasBottomLeft = corners.contains(.bottomLeft)
        let hasBottomRight = corners.contains(.bottomRight)
        
        path.move(to: CGPoint(x: width / 2, y: 0))
        
        if hasTopRight {
            path.addLine(to: CGPoint(x: width - tr, y: 0))
            path.addArc(center: CGPoint(x: width - tr, y: tr), radius: tr,
                        startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        
        if hasBottomRight {
            path.addLine(to: CGPoint(x: width, y: height - br))
            path.addArc(center: CGPoint(x: width - br, y: height - br), radius: br,
                        startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: width, y: height))
        }
        
        if hasBottomLeft {
            path.addLine(to: CGPoint(x: bl, y: height))
            path.addArc(center: CGPoint(x: bl, y: height - bl), radius: bl,
                        startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: height))
        }
        
        if hasTopLeft {
            path.addLine(to: CGPoint(x: 0, y: tl))
            path.addArc(center: CGPoint(x: tl, y: tl), radius: tl,
                        startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        path.closeSubpath()
        return path
    }
}

struct RectCorner: OptionSet, Sendable {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
