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
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
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
                
                Text(message.content)
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
