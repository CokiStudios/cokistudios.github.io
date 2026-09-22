import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 💬 CSMS EXTENSION FOR FORKAR PC (NATIVE MACOS CLIENT)
// Extensión nativa de mensajería en tiempo real de Coki Studios
// ══════════════════════════════════════════════════════════════════

struct CSMSExtensionView: View {
    @EnvironmentObject var manager: SupabaseManager
    @State private var messageText: String = ""
    @State private var isSending: Bool = false
    
    var body: some View {
        HSplitView {
            // ─── 1. BARRA LATERAL DE CANALES CSMS ───
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundColor(ForkarTheme.accent)
                    Text("CSMS Canales")
                        .font(.headline)
                        .foregroundColor(ForkarTheme.text)
                    Spacer()
                    Circle()
                        .fill(ForkarTheme.greenEco)
                        .frame(width: 8, height: 8)
                        .help("Conectado en tiempo real")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(ForkarTheme.bgTertiary)
                
                Divider()
                    .background(ForkarTheme.border)
                
                List(manager.csmsRooms, id: \.id) { room in
                    Button(action: {
                        manager.activeCSMSRoomId = room.id
                        Task {
                            await manager.fetchCSMSMessages(roomId: room.id)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(room.id == manager.activeCSMSRoomId ? ForkarTheme.accent : ForkarTheme.cardActive)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: iconForRoom(room.id))
                                        .font(.system(size: 14))
                                        .foregroundColor(room.id == manager.activeCSMSRoomId ? .white : ForkarTheme.textSub)
                                )
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(room.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(room.id == manager.activeCSMSRoomId ? .white : ForkarTheme.text)
                                    .lineLimit(1)
                                
                                if let last = room.lastMessage {
                                    Text(last)
                                        .font(.system(size: 11))
                                        .foregroundColor(ForkarTheme.textSub)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(
                        room.id == manager.activeCSMSRoomId
                            ? RoundedRectangle(cornerRadius: 8).fill(ForkarTheme.cardActive)
                            : RoundedRectangle(cornerRadius: 8).fill(Color.clear)
                    )
                }
                .listStyle(SidebarListStyle())
            }
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
            
            // ─── 2. ÁREA DE CHAT EN VIVO ───
            VStack(spacing: 0) {
                // Header del Canal Activo
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activeRoomTitle)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                        Text("Extensión oficial de mensajería para Forkar PC")
                            .font(.system(size: 11))
                            .foregroundColor(ForkarTheme.textSub)
                    }
                    Spacer()
                    
                    Button(action: {
                        if let url = URL(string: "https://cokistudios.com/messenger") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Pantalla completa")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ForkarTheme.textSub)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ForkarTheme.card)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(ForkarTheme.bgSecondary)
                
                Divider().background(ForkarTheme.border)
                
                // Mensajes
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if manager.csmsMessages.isEmpty {
                                VStack(spacing: 10) {
                                    Spacer(minLength: 60)
                                    Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                                        .font(.system(size: 36))
                                        .foregroundColor(ForkarTheme.textSub.opacity(0.5))
                                    Text("¡Sé el primero en escribir en este canal!")
                                        .font(.system(size: 13))
                                        .foregroundColor(ForkarTheme.textSub)
                                }
                            } else {
                                ForEach(manager.csmsMessages) { msg in
                                    CSMSMessageBubble(message: msg, isMe: msg.senderId == manager.currentUser?.id)
                                        .id(msg.id)
                                }
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: manager.csmsMessages.count) { _ in
                        if let lastId = manager.csmsMessages.last?.id {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider().background(ForkarTheme.border)
                
                // Input de Envío
                HStack(spacing: 10) {
                    TextField("Escribe un mensaje en CSMS...", text: $messageText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ForkarTheme.card)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ForkarTheme.border, lineWidth: 1)
                        )
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(ForkarTheme.brandGradient)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ForkarTheme.bgSecondary)
            }
        }
        .background(ForkarTheme.bg)
        .onAppear {
            Task {
                await manager.fetchCSMSMessages(roomId: manager.activeCSMSRoomId)
            }
        }
    }
    
    private var activeRoomTitle: String {
        manager.csmsRooms.first(where: { $0.id == manager.activeCSMSRoomId })?.name ?? "CSMS Chat"
    }
    
    private func iconForRoom(_ id: String) -> String {
        switch id {
        case "00000000-0000-4000-8000-000000000001": return "bubble.left.fill"
        case "00000000-0000-4000-8000-000000000003": return "car.fill"
        case "00000000-0000-4000-8000-000000000002": return "leaf.fill"
        default: return "person.fill"
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messageText = ""
        isSending = true
        
        Task {
            do {
                try await manager.sendCSMSMessage(content: text, roomId: manager.activeCSMSRoomId)
            } catch {
                print("Error enviando mensaje: \(error.localizedDescription)")
            }
            isSending = false
        }
    }
}

// ─── BURBUJA DE MENSAJE CSMS ───
struct CSMSMessageBubble: View {
    let message: CSMSMessage
    let isMe: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 40) }
            
            if !isMe {
                Circle()
                    .fill(ForkarTheme.accent.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ForkarTheme.accent)
                    )
            }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                if !isMe, let author = message.authorName {
                    Text(author)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(ForkarTheme.accent)
                }
                
                Text(message.content)
                    .font(.system(size: 13))
                    .foregroundColor(isMe ? .white : ForkarTheme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        isMe
                            ? AnyView(ForkarTheme.brandGradient)
                            : AnyView(RoundedRectangle(cornerRadius: 12).fill(ForkarTheme.cardHover))
                    )
                    .cornerRadius(12)
            }
            
            if !isMe { Spacer(minLength: 40) }
        }
    }
    
    private var initials: String {
        let name = message.authorName ?? "U"
        return String(name.prefix(2)).uppercased()
    }
}
