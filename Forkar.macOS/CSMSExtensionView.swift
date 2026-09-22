import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 💬 CSMS EXTENSION FOR FORKAR PC (NATIVE MACOS CLIENT)
// Extensión nativa de mensajería en tiempo real con Supabase chat_messages
// ══════════════════════════════════════════════════════════════════

struct CSMSExtensionView: View {
    @EnvironmentObject var manager: SupabaseManager
    @State private var messageText: String = ""
    @State private var isSending: Bool = false
    @State private var showingNewRoomSheet: Bool = false
    @State private var newRoomName: String = ""
    
    var body: some View {
        HSplitView {
            // ─── 1. BARRA LATERAL DE CANALES CSMS ───
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundColor(ForkarTheme.accent)
                    Text("Salas CSMS")
                        .font(.headline)
                        .foregroundColor(ForkarTheme.text)
                    Spacer()
                    
                    Circle()
                        .fill(manager.isCSMSConnected ? ForkarTheme.greenEco : Color(hex: "#F59E0B"))
                        .frame(width: 8, height: 8)
                        .help(manager.isCSMSConnected ? "Conectado a Supabase en vivo" : "Reconectando...")
                    
                    Button(action: { showingNewRoomSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(ForkarTheme.textSub)
                            .frame(width: 20, height: 20)
                            .background(ForkarTheme.card)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Crear nueva sala CSMS")
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
                                Text(room.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(room.id == manager.activeCSMSRoomId ? .white : ForkarTheme.text)
                                    .lineLimit(1)
                                
                                Text(room.isGroup ? "Canal público" : "Mensajes directos")
                                    .font(.system(size: 10))
                                    .foregroundColor(ForkarTheme.textSub)
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
                        Text("Sincronización en tiempo real vía Supabase REST & Polling")
                            .font(.system(size: 11))
                            .foregroundColor(ForkarTheme.textSub)
                    }
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await manager.fetchCSMSMessages(roomId: manager.activeCSMSRoomId)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(ForkarTheme.textSub)
                            .frame(width: 28, height: 28)
                            .background(ForkarTheme.card)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Refrescar mensajes")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(ForkarTheme.bgSecondary)
                
                Divider().background(ForkarTheme.border)
                
                // Mensajes Reales de Supabase
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if manager.csmsMessages.isEmpty {
                                VStack(spacing: 10) {
                                    Spacer(minLength: 60)
                                    Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                                        .font(.system(size: 36))
                                        .foregroundColor(ForkarTheme.textSub.opacity(0.5))
                                    Text("¡Sé el primero en escribir en esta sala de CSMS!")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(ForkarTheme.text)
                                    Text("Escribe un mensaje abajo para iniciar la conversación.")
                                        .font(.system(size: 11))
                                        .foregroundColor(ForkarTheme.textSub)
                                }
                            } else {
                                ForEach(manager.csmsMessages) { msg in
                                    CSMSMessageBubble(message: msg, isMe: msg.userId == manager.currentUser?.id)
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
                
                // Input de Envío Real
                HStack(spacing: 10) {
                    TextField(manager.isAuthenticated ? "Escribe un mensaje en CSMS..." : "Inicia sesión para chatear...", text: $messageText)
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
                        .disabled(!manager.isAuthenticated)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(ForkarTheme.brandGradient)
                                .cornerRadius(8)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending || !manager.isAuthenticated)
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
        .sheet(isPresented: $showingNewRoomSheet) {
            VStack(spacing: 16) {
                Text("Nueva Sala CSMS")
                    .font(.headline)
                    .foregroundColor(ForkarTheme.text)
                
                TextField("Nombre de la sala (Ej: Desarrolladores Coki)", text: $newRoomName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(10)
                    .background(ForkarTheme.bgTertiary)
                    .cornerRadius(8)
                
                HStack {
                    Button("Cancelar") { showingNewRoomSheet = false }
                    Spacer()
                    Button("Crear") {
                        if !newRoomName.isEmpty {
                            let newRoom = CSMSChatRoom(
                                id: UUID().uuidString.lowercased(),
                                name: newRoomName,
                                isGroup: true,
                                createdBy: manager.currentUser?.id,
                                createdAt: nil
                            )
                            manager.csmsRooms.insert(newRoom, at: 0)
                            manager.activeCSMSRoomId = newRoom.id
                            newRoomName = ""
                            showingNewRoomSheet = false
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(ForkarTheme.accent)
                    .cornerRadius(6)
                }
            }
            .padding(20)
            .frame(width: 360)
            .background(ForkarTheme.bgSecondary)
        }
    }
    
    private var activeRoomTitle: String {
        manager.csmsRooms.first(where: { $0.id == manager.activeCSMSRoomId })?.displayName ?? "CSMS Chat"
    }
    
    private func iconForRoom(_ id: String) -> String {
        if id.contains("1") { return "bubble.left.fill" }
        if id.contains("3") { return "car.fill" }
        if id.contains("2") { return "leaf.fill" }
        return "person.2.fill"
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
                HStack(spacing: 6) {
                    if !isMe {
                        Text(message.authorName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ForkarTheme.accent)
                    }
                    Text(message.formattedTime)
                        .font(.system(size: 9))
                        .foregroundColor(ForkarTheme.textSub)
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
        String(message.authorName.prefix(2)).uppercased()
    }
}
