import SwiftUI

struct PostDetailView: View {
    let post: Post
    
    @EnvironmentObject var authManager: SupabaseManager
    
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLiked = false
    @State private var isFollowingAuthor = false
    @State private var likesCount: Int = 0
    @State private var isLoadingComments = false
    @State private var showLogin = false
    
    @State private var showReportPostDialog = false
    @State private var showReportCommentDialog = false
    @State private var selectedCommentToReport: Comment? = nil
    @State private var showSuccessAlert = false
    @State private var activeChatRoom: ChatRoom? = nil
    @State private var isNavigatingToChat = false
    @State private var knownNames: [String] = []
    
    var body: some View {
        ZStack {
            ForkarTheme.bg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Author Card Header
                        HStack(spacing: 12) {
                            if let avatarURL = post.author_avatar, let url = URL(string: avatarURL) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                } placeholder: {
                                    CircleAvatarPlaceholder(initials: post.initials)
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            } else {
                                CircleAvatarPlaceholder(initials: post.initials)
                                    .frame(width: 44, height: 44)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(post.author_name)
                                    .font(.headline)
                                    .foregroundColor(ForkarTheme.text)
                                Text(post.formattedDate)
                                    .font(.subheadline)
                                    .foregroundColor(ForkarTheme.textSub)
                            }
                            
                            Spacer()
                            
                            // Follow and Message Buttons (if not current user)
                            if authManager.isLoggedIn && post.user_id != authManager.currentUser?.id {
                                HStack(spacing: 8) {
                                    // Chat / Message button
                                    Button(action: {
                                        startChat()
                                    }) {
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(ForkarTheme.card)
                                            .foregroundColor(ForkarTheme.accent)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(ForkarTheme.border, lineWidth: 1)
                                            )
                                    }
                                    
                                    // Follow Button
                                    Button(action: {
                                        Task {
                                            await toggleFollow()
                                        }
                                    }) {
                                        Text(isFollowingAuthor ? "Siguiendo" : "Seguir")
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 14)
                                            .background(isFollowingAuthor ? Color.clear : ForkarTheme.accent)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(isFollowingAuthor ? ForkarTheme.border : Color.clear, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Post Header (Category and Title)
                        VStack(alignment: .leading, spacing: 10) {
                            if let cat = post.category {
                                Text(cat.name)
                                    .font(.system(size: 11, weight: .black))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 12)
                                    .background(cat.themeColor.opacity(0.15))
                                    .foregroundColor(cat.themeColor)
                                    .cornerRadius(10)
                            }
                            
                            Text(post.title)
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(ForkarTheme.text)
                        }
                        
                        // Content Body
                        Text(parseMentions(post.content))
                            .font(.system(size: 15))
                            .lineSpacing(4)
                            .foregroundColor(ForkarTheme.text)
                            .textSelection(.enabled)
                        
                        // Like/Action bar
                        HStack(spacing: 24) {
                            Button(action: {
                                if authManager.isLoggedIn {
                                    Task {
                                        await toggleLike()
                                    }
                                } else {
                                    showLogin = true
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .foregroundColor(isLiked ? .red : ForkarTheme.textSub)
                                    Text("\(likesCount) Likes")
                                        .foregroundColor(ForkarTheme.textSub)
                                }
                                .font(.system(size: 13, weight: .bold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(ForkarTheme.card)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ForkarTheme.border, lineWidth: 1)
                                )
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        
                        Divider()
                            .background(ForkarTheme.border)
                        
                        // Comments Title
                        Text("Comentarios (\(comments.count))")
                            .font(.headline)
                            .foregroundColor(ForkarTheme.text)
                            .padding(.top, 4)
                        
                        // Comments List
                        if isLoadingComments {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                                Spacer()
                            }
                        } else if comments.isEmpty {
                            VStack(spacing: 8) {
                                Text("Aún no hay comentarios")
                                    .font(.subheadline)
                                    .foregroundColor(ForkarTheme.textSub)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            }
                        } else {
                            VStack(spacing: 12) {
                                ForEach(comments) { comment in
                                    CommentRowView(comment: comment, currentUserId: authManager.currentUser?.id, knownNames: knownNames) {
                                        selectedCommentToReport = comment
                                        showReportCommentDialog = true
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Bottom Write Comment Bar
                VStack(spacing: 0) {
                    Divider()
                        .background(ForkarTheme.border)
                    
                    HStack(spacing: 12) {
                        TextField("Escribe un comentario...", text: $newCommentText)
                            .foregroundColor(ForkarTheme.text)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ForkarTheme.border, lineWidth: 1)
                            )
                        
                        Button(action: {
                            if authManager.isLoggedIn {
                                Task {
                                    await submitComment()
                                }
                            } else {
                                showLogin = true
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(ForkarTheme.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(ForkarTheme.bg.opacity(0.85))
                }
            }
        }
        .navigationTitle("Publicación")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if authManager.isLoggedIn && post.user_id != authManager.currentUser?.id {
                    Button(action: {
                        showReportPostDialog = true
                    }) {
                        Image(systemName: "flag")
                            .foregroundColor(ForkarTheme.textSub)
                    }
                }
            }
        }
        .confirmationDialog("Reportar Publicación", isPresented: $showReportPostDialog, titleVisibility: .visible) {
            Button("Spam / Publicidad") { reportPost(reason: "spam") }
            Button("Acoso / Agresión") { reportPost(reason: "harassment") }
            Button("Contenido inapropiado") { reportPost(reason: "inappropriate") }
            Button("Otro motivo") { reportPost(reason: "other") }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Selecciona el motivo del reporte para esta publicación.")
        }
        .confirmationDialog("Reportar Comentario", isPresented: $showReportCommentDialog, titleVisibility: .visible) {
            Button("Spam / Publicidad") { reportComment(reason: "spam") }
            Button("Acoso / Agresión") { reportComment(reason: "harassment") }
            Button("Contenido inapropiado") { reportComment(reason: "inappropriate") }
            Button("Otro motivo") { reportComment(reason: "other") }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Selecciona el motivo del reporte para este comentario.")
        }
        .alert("Reporte Enviado", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Gracias por reportar. Revisaremos el contenido lo antes posible.")
        }
        .sheet(isPresented: $showLogin) {
            NavigationView {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let room = activeChatRoom {
                        ChatRoomDetailView(room: room)
                            .environmentObject(authManager)
                    } else {
                        EmptyView()
                    }
                },
                isActive: $isNavigatingToChat
            ) {
                EmptyView()
            }
        )
        .onAppear {
            likesCount = post.likes_count
            Task {
                await loadPostDetails()
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
    }
    
    private func startChat() {
        Task {
            do {
                let room = try await authManager.getOrCreateDirectChat(
                    with: post.user_id,
                    targetUserName: post.author_name,
                    targetUserAvatar: post.author_avatar
                )
                await MainActor.run {
                    self.activeChatRoom = room
                    self.isNavigatingToChat = true
                }
            } catch {
                print("Error starting direct chat: \(error.localizedDescription)")
            }
        }
    }
    
    private func parseMentions(_ text: String) -> LocalizedStringKey {
        var formatted = text
        let sortedNames = knownNames.sorted { $0.count > $1.count }
        for name in sortedNames {
            let mentionTag = "@\(name)"
            if formatted.contains(mentionTag) {
                let escapedName = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? name
                formatted = formatted.replacingOccurrences(of: mentionTag, with: "[\(mentionTag)](mention:\(escapedName))")
            }
        }
        
        let pattern = "@([a-zA-Z0-9_]+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(formatted.startIndex..., in: formatted)
            formatted = regex.stringByReplacingMatches(in: formatted, options: [], range: range, withTemplate: "[$0](mention:$1)")
        }
        return LocalizedStringKey(formatted)
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
                        self.isNavigatingToChat = true
                    }
                }
            } catch {
                print("Error opening direct chat from mention: \(error)")
            }
        }
    }
    
    private func loadPostDetails() async {
        isLoadingComments = true
        do {
            comments = try await authManager.fetchComments(postId: post.id)
            if authManager.isLoggedIn {
                isLiked = try await authManager.checkIfLiked(postId: post.id)
                isFollowingAuthor = try await authManager.checkFollowStatus(targetUserId: post.user_id)
            }
            updateKnownNames()
        } catch {
            print("Error loading post details: \(error)")
        }
        isLoadingComments = false
    }
    
    private func updateKnownNames() {
        var names = [post.author_name]
        for c in comments {
            if !names.contains(c.author_name) {
                names.append(c.author_name)
            }
        }
        if names.count != knownNames.count {
            self.knownNames = names
        }
    }
    
    private func toggleLike() async {
        do {
            let liked = try await authManager.toggleLike(postId: post.id)
            isLiked = liked
            likesCount += liked ? 1 : -1
        } catch {
            print("Error toggling like: \(error)")
        }
    }
    
    private func toggleFollow() async {
        do {
            let following = try await authManager.toggleFollow(targetUserId: post.user_id)
            isFollowingAuthor = following
        } catch {
            print("Error toggling follow: \(error)")
        }
    }
    
    private func submitComment() async {
        let cleanText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        do {
            let newComment = try await authManager.createComment(postId: post.id, content: cleanText)
            withAnimation {
                comments.append(newComment)
                newCommentText = ""
            }
        } catch {
            print("Error posting comment: \(error)")
        }
    }
    private func reportPost(reason: String) {
        Task {
            do {
                try await authManager.reportPost(postId: post.id, reason: reason)
                await MainActor.run {
                    showSuccessAlert = true
                }
            } catch {
                print("Error reporting post: \(error)")
            }
        }
    }
    
    private func reportComment(reason: String) {
        guard let comment = selectedCommentToReport else { return }
        Task {
            do {
                try await authManager.reportComment(commentId: comment.id, reason: reason)
                await MainActor.run {
                    showSuccessAlert = true
                }
            } catch {
                print("Error reporting comment: \(error)")
            }
        }
    }
}

// MARK: - Comment Row View Component
struct CommentRowView: View {
    let comment: Comment
    let currentUserId: UUID?
    let knownNames: [String]
    let onReport: () -> Void
    
    var formattedContent: LocalizedStringKey {
        var formatted = comment.content
        let sortedNames = knownNames.sorted { $0.count > $1.count }
        for name in sortedNames {
            let mentionTag = "@\(name)"
            if formatted.contains(mentionTag) {
                let escapedName = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? name
                formatted = formatted.replacingOccurrences(of: mentionTag, with: "[\(mentionTag)](mention:\(escapedName))")
            }
        }
        
        let pattern = "@([a-zA-Z0-9_]+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(formatted.startIndex..., in: formatted)
            formatted = regex.stringByReplacingMatches(in: formatted, options: [], range: range, withTemplate: "[$0](mention:$1)")
        }
        
        return LocalizedStringKey(formatted)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let avatarURL = comment.author_avatar, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        CircleAvatarPlaceholder(initials: comment.initials)
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                } else {
                    CircleAvatarPlaceholder(initials: comment.initials)
                        .frame(width: 24, height: 24)
                        .font(.system(size: 10, weight: .bold))
                }
                
                Text(comment.author_name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                
                Spacer()
                
                Text(comment.formattedDate)
                    .font(.system(size: 10))
                    .foregroundColor(ForkarTheme.textSub)
                
                if comment.user_id != currentUserId {
                    Button(action: onReport) {
                        Image(systemName: "flag")
                            .font(.system(size: 10))
                            .foregroundColor(ForkarTheme.textSub)
                            .padding(4)
                    }
                }
            }
            
            Text(formattedContent)
                .font(.system(size: 13))
                .foregroundColor(ForkarTheme.text)
                .padding(.leading, 32)
        }
        .padding()
        .background(ForkarTheme.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ForkarTheme.border, lineWidth: 1)
        )
    }
}
