import SwiftUI
import AVKit
import AppKit

// ══════════════════════════════════════════════════════════════════
// 💬 CSMS EXTENSION FOR FORKAR PC (NATIVE MACOS CLIENT)
// Extensión nativa de mensajería en tiempo real con Supabase chat_messages
// Basada 1:1 en la arquitectura probada de Web (messenger.html) y iOS
// Soporte de fotos, videos (AVKit), previsualización y subida a Supabase
// ══════════════════════════════════════════════════════════════════

struct CSMSExtensionView: View {
    @EnvironmentObject var manager: SupabaseManager
    @State private var messageText: String = ""
    @State private var isSending: Bool = false
    @State private var showingNewRoomSheet: Bool = false
    @State private var newRoomName: String = ""
    
    // Estado de archivos adjuntos (Fotos y Videos)
    @State private var attachedFileURL: URL? = nil
    @State private var attachedFileName: String = ""
    @State private var attachedFileSizeText: String = ""
    @State private var isUploadingMedia: Bool = false
    @State private var uploadErrorMessage: String? = nil
    
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
            
            // ─── 2. ÁREA DE CHAT EN VIVO CON MULTIMEDIA ───
            VStack(spacing: 0) {
                // Header del Canal Activo
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activeRoomTitle)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                        Text("Sincronización en tiempo real vía Supabase REST & Polling • Web & iOS CSMS")
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
                        LazyVStack(spacing: 14) {
                            if manager.csmsMessages.isEmpty {
                                VStack(spacing: 10) {
                                    Spacer(minLength: 60)
                                    Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                                        .font(.system(size: 36))
                                        .foregroundColor(ForkarTheme.textSub.opacity(0.5))
                                    Text("¡Sé el primero en escribir o compartir fotos y videos!")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(ForkarTheme.text)
                                    Text("Usa el botón de adjuntar (📎) para subir imágenes o videos de tu Mac.")
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
                
                // Barra de previsualización de archivo adjunto (si se seleccionó foto o video)
                if let fileURL = attachedFileURL {
                    Divider().background(ForkarTheme.border)
                    HStack(spacing: 12) {
                        Image(systemName: isVideoFile(fileURL) ? "video.fill" : "photo.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ForkarTheme.accent)
                            .frame(width: 36, height: 36)
                            .background(ForkarTheme.accent.opacity(0.15))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(attachedFileName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ForkarTheme.text)
                                .lineLimit(1)
                            
                            HStack(spacing: 6) {
                                Text(attachedFileSizeText)
                                    .font(.system(size: 10))
                                    .foregroundColor(ForkarTheme.textSub)
                                
                                if isUploadingMedia {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                                        .scaleEffect(0.6)
                                    Text("Subiendo a Supabase Storage...")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(ForkarTheme.accent)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: removeAttachment) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Eliminar adjunto")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ForkarTheme.bgTertiary)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if let err = uploadErrorMessage {
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                }
                
                Divider().background(ForkarTheme.border)
                
                // Input de Envío Real con Botón de Adjuntar
                HStack(spacing: 10) {
                    // Botón para adjuntar fotos o videos nativos de Mac
                    Button(action: selectMediaFile) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(attachedFileURL != nil ? ForkarTheme.accent : ForkarTheme.textSub)
                            .frame(width: 32, height: 32)
                            .background(ForkarTheme.card)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(attachedFileURL != nil ? ForkarTheme.accent : ForkarTheme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Adjuntar foto o video desde tu Mac")
                    .disabled(!manager.isAuthenticated || isSending)
                    
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
                        .disabled(!manager.isAuthenticated || isSending)
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
                    .disabled(
                        (messageText.trimmingCharacters(in: .whitespaces).isEmpty && attachedFileURL == nil)
                        || isSending
                        || !manager.isAuthenticated
                    )
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
    
    private func isVideoFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["mp4", "mov", "webm", "m4v"].contains(ext)
    }
    
    // ─── SELECCIÓN DE FOTO O VIDEO VÍA NSOpenPanel ───
    private func selectMediaFile() {
        let panel = NSOpenPanel()
        panel.title = "Selecciona una Foto o Video para CSMS"
        panel.prompt = "Adjuntar"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowedFileTypes = ["jpg", "jpeg", "png", "webp", "gif", "heic", "mp4", "mov", "webm", "m4v", "pdf"]
        
        if panel.runModal() == .OK, let selected = panel.url {
            withAnimation {
                self.attachedFileURL = selected
                self.attachedFileName = selected.lastPathComponent
                self.uploadErrorMessage = nil
                
                if let attr = try? FileManager.default.attributesOfItem(atPath: selected.path),
                   let size = attr[.size] as? Int64 {
                    let bcf = ByteCountFormatter()
                    bcf.countStyle = .file
                    self.attachedFileSizeText = bcf.string(fromByteCount: size)
                } else {
                    self.attachedFileSizeText = ""
                }
            }
        }
    }
    
    private func removeAttachment() {
        withAnimation {
            attachedFileURL = nil
            attachedFileName = ""
            attachedFileSizeText = ""
            uploadErrorMessage = nil
        }
    }
    
    // ─── ENVÍO DE MENSAJE Y MULTIMEDIA ───
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty || attachedFileURL != nil else { return }
        
        let pendingText = text
        let pendingFile = attachedFileURL
        
        messageText = ""
        isSending = true
        uploadErrorMessage = nil
        
        Task {
            do {
                var uploadedUrl: String? = nil
                var uploadedType: String? = nil
                
                if let file = pendingFile {
                    isUploadingMedia = true
                    let (url, type) = try await manager.uploadMedia(fileURL: file)
                    uploadedUrl = url
                    uploadedType = type
                    isUploadingMedia = false
                }
                
                let finalContent = pendingText.isEmpty ? (uploadedType == "video" ? "🎥 Video adjunto" : "📷 Foto adjunta") : pendingText
                try await manager.sendCSMSMessage(
                    content: finalContent,
                    roomId: manager.activeCSMSRoomId,
                    mediaUrl: uploadedUrl,
                    mediaType: uploadedType
                )
                
                await MainActor.run {
                    removeAttachment()
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    uploadErrorMessage = "Error enviando: \(error.localizedDescription)"
                    isUploadingMedia = false
                    isSending = false
                }
            }
        }
    }
}

// ─── REPRODUCTOR DE VIDEO NATIVO CSMS (AVKit / AVPlayer) ───
struct CSMSVideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isLoaded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                if let player = player, isLoaded {
                    VideoPlayer(player: player)
                        .frame(width: 280, height: 180)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 280, height: 180)
                        .overlay(
                            VStack(spacing: 8) {
                                Button(action: {
                                    let p = AVPlayer(url: url)
                                    self.player = p
                                    self.isLoaded = true
                                    p.play()
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(ForkarTheme.accent)
                                        Text("Reproducir Video")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        )
                }
            }
            
            HStack(spacing: 8) {
                Button(action: {
                    NSWorkspace.shared.open(url)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                        Text("Abrir en reproductor externo")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(ForkarTheme.accent)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .padding(6)
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
    }
}

// ─── BURBUJA DE MENSAJE CSMS (FOTOS, VIDEOS, ARCHIVOS) ───
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
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
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
                
                VStack(alignment: isMe ? .trailing : .leading, spacing: 8) {
                    // Texto del mensaje
                    if !message.content.isEmpty {
                        Text(message.content)
                            .font(.system(size: 13))
                            .foregroundColor(isMe ? .white : ForkarTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Adjunto Multimedia si existe (Foto, Video o Archivo)
                    if let mediaUrl = message.mediaUrl, let url = URL(string: mediaUrl) {
                        let type = resolvedMediaType(for: mediaUrl)
                        
                        if type == "image" {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 280, maxHeight: 220)
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            NSWorkspace.shared.open(url)
                                        }
                                        .help("Click para abrir en resolución completa")
                                case .failure(_):
                                    HStack(spacing: 6) {
                                        Image(systemName: "photo.badge.exclamationmark")
                                        Text("No se pudo cargar la imagen")
                                            .font(.system(size: 11))
                                    }
                                    .padding(8)
                                case .empty:
                                    ProgressView()
                                        .frame(width: 80, height: 80)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else if type == "video" {
                            CSMSVideoPlayerView(url: url)
                        } else {
                            // Tarjeta de Archivo genérico (Web & iOS compatible)
                            Button(action: {
                                NSWorkspace.shared.open(url)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(ForkarTheme.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(url.lastPathComponent)
                                            .font(.system(size: 11, weight: .semibold))
                                            .lineLimit(1)
                                        Text("Descargar archivo")
                                            .font(.system(size: 9))
                                            .foregroundColor(ForkarTheme.textSub)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundColor(ForkarTheme.accent)
                                }
                                .padding(8)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                                .frame(maxWidth: 240)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isMe
                        ? AnyView(ForkarTheme.brandGradient)
                        : AnyView(RoundedRectangle(cornerRadius: 12).fill(ForkarTheme.cardHover))
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.white.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            
            if !isMe { Spacer(minLength: 40) }
        }
    }
    
    private var initials: String {
        String(message.authorName.prefix(2)).uppercased()
    }
    
    private func resolvedMediaType(for urlStr: String) -> String {
        if let type = message.mediaType, !type.isEmpty {
            return type
        }
        let lower = urlStr.lowercased()
        if lower.contains(".mp4") || lower.contains(".mov") || lower.contains(".webm") || lower.contains(".m4v") {
            return "video"
        }
        if lower.contains(".jpg") || lower.contains(".jpeg") || lower.contains(".png") || lower.contains(".gif") || lower.contains(".webp") || lower.contains(".heic") {
            return "image"
        }
        return "file"
    }
}
