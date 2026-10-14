import SwiftUI
internal import Combine
#if canImport(ImagePlayground)
import ImagePlayground
#endif

struct ChatRoomDetailView: View {
    @EnvironmentObject var authManager: SupabaseManager
    @Environment(\.presentationMode) var presentationMode
    let room: ChatRoom
    
    @State private var messages: [ChatMessage] = []
    @State private var newMessageText = ""
    @State private var isSending = false
    @State private var isLoading = true
    @State private var partnerName: String = ""
    @State private var showDeleteConfirmation = false
    @State private var isDeletingRoom = false
    
    // Timer to pull new messages every 3 seconds
    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    @State private var showInviteSheet = false
    @State private var communityUsers: [CommunityUser] = []
    @State private var isLoadingUsers = false
    @State private var showCokiSummarySheet = false
    @State private var cokiSummaryText = ""
    @State private var isSummarizingWithCoki = false
    
    // Coki with Apple Intelligence & Apple Playground
    @State private var showImagePlayground = false
    @State private var playgroundConcept = "auto deportivo eléctrico y sostenible"
    @State private var isProcessingCokiAI = false
    
    @State private var activeChatRoom: ChatRoom? = nil
    @State private var navigateToChat = false
    @State private var knownNames: [String] = []
    @State private var moderationErrorAlert: String? = nil
    @State private var showModerationErrorAlert = false
    
    var body: some View {
        ZStack {
            ForkarTheme.bg
                .ignoresSafeArea()
            XtrapsBackground(strokeColor: ForkarTheme.accent.opacity(0.12))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (if direct chat, shows partner's name)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(room.is_group ? room.displayName : partnerName)
                                .font(.headline)
                                .foregroundColor(ForkarTheme.text)
                            Image(systemName: "lock.shield.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        HStack(spacing: 4) {
                            Text(room.is_group ? "Grupo de Chat" : "Mensaje Privado")
                            Text("•")
                            Text(CSMSEncryption.shared.hardwareSecurityBadge)
                                .foregroundColor(ForkarTheme.accent)
                        }
                        .font(.caption2)
                        .foregroundColor(ForkarTheme.textSub)
                    Spacer()
                    
                    if !messages.isEmpty {
                        Button(action: {
                            summarizeChatWithCoki()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "apple.intelligence")
                                    .font(.system(size: 12))
                                Text("Resumen Coki")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(ForkarTheme.accent.opacity(0.12))
                            .foregroundColor(ForkarTheme.accent)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ForkarTheme.accent.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Resumir conversación privada on-device con Coki with Apple Intelligence")
                    }
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
                                    MessageBubbleView(
                                        message: message,
                                        isCurrentUser: message.user_id == authManager.currentUser?.id,
                                        knownNames: knownNames,
                                        currentUserName: authManager.currentUser?.resolvedName
                                    )
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
                
                // Indicador de Respuesta Coki AI en progreso
                if isProcessingCokiAI {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.intelligence")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.purple)
                        Text("Coki with Apple Intelligence está respondiendo...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(ForkarTheme.textSub)
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.purple))
                            .scaleEffect(0.7)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.08))
                    .transition(.opacity)
                }
                
                // Barra Flotante de Sugerencias de Menciones (@alguien, /Coki, /Genimg)
                if !activeMentionSuggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(activeMentionSuggestions) { item in
                                Button(action: {
                                    selectMentionSuggestion(item)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: item.iconName)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(item.isAI ? Color.purple : (item.isPlayground ? Color.pink : ForkarTheme.accent))
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(item.displayTitle)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(ForkarTheme.text)
                                            Text(item.subtitle)
                                                .font(.system(size: 9))
                                                .foregroundColor(ForkarTheme.textSub)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(ForkarTheme.card)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(item.isAI ? Color.purple.opacity(0.5) : (item.isPlayground ? Color.pink.opacity(0.5) : ForkarTheme.border), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                    }
                    .background(ForkarTheme.card.opacity(0.92))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Message Input Area
                HStack(spacing: 10) {
                    // Botón Menú Rápido de IA y Playground
                    Menu {
                        Button(action: {
                            insertCommand("/Coki ")
                        }) {
                            Label("Preguntar a /Coki (IA)", systemImage: "apple.intelligence")
                        }
                        
                        Button(action: {
                            launchPlaygroundGeneration()
                        }) {
                            Label("Generar con /Genimg (Apple Playground)", systemImage: "sparkles.rectangle.stack.fill")
                        }
                        
                        Divider()
                        
                        ForEach(knownNames.prefix(6), id: \.self) { name in
                            Button(action: {
                                insertMention("@\(name)")
                            }) {
                                Label("Mencionar @\(name)", systemImage: "at")
                            }
                        }
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.purple)
                            .frame(width: 36, height: 36)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.purple.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Comandos rápidos: /Coki y /Genimg (Apple Playground)")
                    
                    TextField("Escribe un mensaje, /Coki o @usuario...", text: $newMessageText)
                        .foregroundColor(ForkarTheme.text)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(ForkarTheme.card)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(newMessageText.hasPrefix("/Coki") || newMessageText.hasPrefix("@Coki") ? Color.purple.opacity(0.6) : (newMessageText.hasPrefix("/Genimg") ? Color.pink.opacity(0.6) : ForkarTheme.border), lineWidth: 1)
                        )
                        .disabled(isSending)
                        .onSubmit {
                            sendCurrentMessage()
                        }
                    
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
                                .background(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : ForkarTheme.accent)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.black, lineWidth: 2.0))
                                .background(Circle().fill(Color.black).offset(x: 2, y: 2))
                        }
                    }
                    .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                    .padding(.trailing, 2)
                    .padding(.bottom, 2)
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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if room.is_group {
                    Button(action: {
                        showInviteSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(ForkarTheme.accent)
                    }
                }
                
                if room.created_by == authManager.currentUser?.id && !CSMSCanonicalRooms.isProtected(roomId: room.id) {
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            #else
            ToolbarItemGroup(placement: .primaryAction) {
                if room.is_group {
                    Button(action: {
                        showInviteSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(ForkarTheme.accent)
                    }
                }
                
                if room.created_by == authManager.currentUser?.id && !CSMSCanonicalRooms.isProtected(roomId: room.id) {
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            #endif
        }
        .alert("Eliminar Conversación", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                deleteRoomAction()
            }
        } message: {
            Text("¿Estás seguro de que deseas eliminar esta conversación? Esta acción no se puede deshacer.")
        }
        .alert("Moderación de Contenido", isPresented: $showModerationErrorAlert) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text(moderationErrorAlert ?? "")
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
        .sheet(isPresented: $showCokiSummarySheet) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.intelligence")
                            .font(.system(size: 20))
                            .foregroundColor(ForkarTheme.accent)
                        Text("Coki with Apple Intelligence")
                            .font(.headline)
                            .foregroundColor(ForkarTheme.text)
                    }
                    .padding(.top, 4)
                    
                    Text("Resumen Privado On-Device (Hardware Neural Engine)")
                        .font(.caption)
                        .foregroundColor(ForkarTheme.textSub)
                    
                    if isSummarizingWithCoki {
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                            Text("Generando resumen local...")
                                .font(.subheadline)
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ScrollView {
                            Text(cokiSummaryText)
                                .font(.body)
                                .foregroundColor(ForkarTheme.text)
                                .lineSpacing(4)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ForkarTheme.card)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForkarTheme.border, lineWidth: 1))
                        }
                    }
                    
                    Spacer()
                    
                    Button("Entendido") {
                        showCokiSummarySheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ForkarTheme.accent)
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
                .frame(minWidth: 420, idealWidth: 480, minHeight: 320, idealHeight: 420)
                .background(ForkarTheme.bg)
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
                if username.lowercased() == "coki" {
                    newMessageText = "/Coki "
                    return .handled
                }
                openDirectChat(withUsername: username)
                return .handled
            } else if url.scheme == "action" && url.host == "genimg" {
                launchPlaygroundGeneration()
                return .handled
            }
            return .systemAction
        })
        .csmsImagePlayground(
            isPresented: $showImagePlayground,
            concept: playgroundConcept,
            onCompletion: { url in
                handlePlaygroundImageGenerated(url: url)
            },
            onCancellation: {
                showImagePlayground = false
            }
        )
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
    }
    
    private func loadInitialData() async {
        if !room.is_group {
            let initialResolved = room.displayName
            await MainActor.run {
                self.partnerName = initialResolved
            }
        }
        await loadMessages()
        if !room.is_group && (room.directContactName == nil || room.directContactName?.isEmpty == true) {
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
            if let partner = members.first(where: { $0.user_id != authManager.currentUser?.id }),
               !partner.user_name.isEmpty {
                await MainActor.run {
                    self.partnerName = partner.user_name
                }
            }
        } catch {
            print("Error loading partner name: \(error.localizedDescription)")
        }
    }
    
    private func deleteRoomAction() {
        isDeletingRoom = true
        Task {
            do {
                try await authManager.deleteChatRoom(roomId: room.id)
                await MainActor.run {
                    self.isDeletingRoom = false
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Error deleting room: \(error.localizedDescription)")
                await MainActor.run {
                    self.isDeletingRoom = false
                }
            }
        }
    }
    
    private var activeMentionSuggestions: [CSMSMentionSuggestion] {
        let text = newMessageText
        guard !text.isEmpty else { return [] }
        
        let tokens = text.components(separatedBy: " ")
        guard let lastToken = tokens.last, !lastToken.isEmpty else { return [] }
        
        if lastToken.hasPrefix("@") {
            let query = String(lastToken.dropFirst()).lowercased()
            var list: [CSMSMentionSuggestion] = []
            
            if "coki".contains(query) || query.isEmpty {
                list.append(
                    CSMSMentionSuggestion(
                        id: "mention_coki",
                        trigger: "@",
                        displayTitle: "@Coki",
                        subtitle: "Coki with Apple Intelligence (Copiloto IA)",
                        iconName: "apple.intelligence",
                        isAI: true,
                        isPlayground: false,
                        insertText: "@Coki "
                    )
                )
            }
            
            for name in knownNames {
                if query.isEmpty || name.lowercased().contains(query) {
                    list.append(
                        CSMSMentionSuggestion(
                            id: "mention_\(name)",
                            trigger: "@",
                            displayTitle: "@\(name)",
                            subtitle: "Miembro de la sala",
                            iconName: "person.crop.circle.fill",
                            isAI: false,
                            isPlayground: false,
                            insertText: "@\(name) "
                        )
                    )
                }
            }
            return list
        } else if lastToken.hasPrefix("/") {
            let query = String(lastToken.dropFirst()).lowercased()
            var list: [CSMSMentionSuggestion] = []
            
            if "coki".contains(query) || query.isEmpty {
                list.append(
                    CSMSMentionSuggestion(
                        id: "slash_coki",
                        trigger: "/",
                        displayTitle: "/Coki",
                        subtitle: "Consulta rápida con Apple Intelligence",
                        iconName: "apple.intelligence",
                        isAI: true,
                        isPlayground: false,
                        insertText: "/Coki "
                    )
                )
            }
            
            if "genimg".contains(query) || "imagen".contains(query) || query.isEmpty {
                list.append(
                    CSMSMentionSuggestion(
                        id: "slash_genimg",
                        trigger: "/",
                        displayTitle: "/Genimg",
                        subtitle: "Generar imagen con Apple Playground API",
                        iconName: "sparkles.rectangle.stack.fill",
                        isAI: false,
                        isPlayground: true,
                        insertText: "/Genimg "
                    )
                )
            }
            return list
        }
        return []
    }
    
    private func selectMentionSuggestion(_ item: CSMSMentionSuggestion) {
        var tokens = newMessageText.components(separatedBy: " ")
        if !tokens.isEmpty {
            tokens.removeLast()
        }
        tokens.append(item.insertText)
        newMessageText = tokens.joined(separator: " ")
        
        if item.isPlayground {
            launchPlaygroundGeneration()
        }
    }
    
    private func insertCommand(_ command: String) {
        newMessageText = command
    }
    
    private func insertMention(_ mention: String) {
        if newMessageText.isEmpty {
            newMessageText = "\(mention) "
        } else {
            newMessageText += " \(mention) "
        }
    }
    
    private func launchPlaygroundGeneration(concept: String? = nil) {
        let clean = concept?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !clean.isEmpty {
            self.playgroundConcept = clean
        } else if self.playgroundConcept.isEmpty {
            self.playgroundConcept = "auto deportivo eléctrico y sostenible"
        }
        
        #if canImport(ImagePlayground) && !os(watchOS) && !os(tvOS)
        if #available(iOS 18.2, macOS 15.2, *) {
            if ImagePlaygroundViewController.isAvailable {
                self.showImagePlayground = true
                return
            }
        }
        #endif
        
        self.moderationErrorAlert = "🎨 Apple Playground API requiere iOS 18.2+, macOS 15.2+ y soporte de Apple Intelligence en el hardware."
        self.showModerationErrorAlert = true
    }
    
    private func handlePlaygroundImageGenerated(url: URL) {
        showImagePlayground = false
        Task {
            do {
                let data = try Data(contentsOf: url)
                let base64 = data.base64EncodedString()
                let dataUri = "data:image/png;base64,\(base64)"
                let text = "🎨 Creado con Apple Playground API: \"\(playgroundConcept)\""
                
                let newMsg = try await authManager.sendMessage(
                    roomId: room.id,
                    content: text,
                    mediaUrl: dataUri,
                    mediaType: "image"
                )
                await MainActor.run {
                    self.messages.append(newMsg)
                }
            } catch {
                print("Error loading playground image: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendCurrentMessage() {
        let content = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        // Atajo directo para /Genimg
        if content.hasPrefix("/Genimg") {
            let prompt = String(content.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
            newMessageText = ""
            launchPlaygroundGeneration(concept: prompt.isEmpty ? nil : prompt)
            return
        }
        
        isSending = true
        newMessageText = ""
        
        Task {
            // On-Device Content Safety Check via Apple Foundation Models (macOS 27)
            let verdict = await AppleContentModerator.shared.checkContent(content, title: room.name)
            if !verdict.isSafe {
                await MainActor.run {
                    self.isSending = false
                    self.newMessageText = content
                    self.moderationErrorAlert = "⚠️ Mensaje no enviado (\(verdict.engine)): \(verdict.reason)"
                    self.showModerationErrorAlert = true
                }
                return
            }
            
            let isCokiQuery = content.hasPrefix("/Coki") || content.hasPrefix("@Coki")
            
            do {
                let newMsg = try await authManager.sendMessage(roomId: room.id, content: content)
                await MainActor.run {
                    self.messages.append(newMsg)
                    self.isSending = false
                }
                
                // Si el mensaje es una consulta a Coki, responder en tiempo real con la IA
                if isCokiQuery {
                    var query = content
                    if query.hasPrefix("/Coki") {
                        query = String(query.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                    } else if query.hasPrefix("@Coki") {
                        query = String(query.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    await MainActor.run {
                        self.isProcessingCokiAI = true
                    }
                    
                    let answer = await AppleContentModerator.shared.askCokiAI(query: query, context: room.displayName)
                    
                    do {
                        let cokiMsg = try await authManager.sendMessage(
                            roomId: room.id,
                            content: answer,
                            customAuthor: "Coki with Apple Intelligence"
                        )
                        await MainActor.run {
                            self.messages.append(cokiMsg)
                            self.isProcessingCokiAI = false
                        }
                    } catch {
                        print("Error posting Coki response: \(error.localizedDescription)")
                        await MainActor.run {
                            self.isProcessingCokiAI = false
                        }
                    }
                }
            } catch {
                print("Error sending message: \(error.localizedDescription)")
                await MainActor.run {
                    self.isSending = false
                }
            }
        }
    }
    
    private func summarizeChatWithCoki() {
        guard !messages.isEmpty else { return }
        isSummarizingWithCoki = true
        showCokiSummarySheet = true
        cokiSummaryText = "Coki with Apple Intelligence está analizando la conversación privada en el Neural Engine local..."
        
        Task {
            let contents = messages.map { $0.content }
            let summary = await AppleContentModerator.shared.summarizeChat(messages: contents, roomName: room.displayName)
            await MainActor.run {
                self.cokiSummaryText = summary
                self.isSummarizingWithCoki = false
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
        NavigationStack {
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
        #if os(macOS)
        .frame(minWidth: 460, idealWidth: 520, minHeight: 480, idealHeight: 560)
        #endif
    }
}

// MARK: - CSMS Mention Suggestion Item
struct CSMSMentionSuggestion: Identifiable, Hashable {
    let id: String
    let trigger: String // "@" or "/"
    let displayTitle: String
    let subtitle: String
    let iconName: String
    let isAI: Bool
    let isPlayground: Bool
    let insertText: String
}

// MARK: - CSMS Media Image View (Universal: Data URI, file URL & HTTP)
struct CSMSMediaImageView: View {
    let urlString: String
    
    var body: some View {
        if urlString.hasPrefix("data:image"),
           let commaIndex = urlString.firstIndex(of: ","),
           let data = Data(base64Encoded: String(urlString[urlString.index(after: commaIndex)...])) {
            #if os(macOS)
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 260, maxHeight: 220)
                    .cornerRadius(10)
            }
            #else
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 260, maxHeight: 220)
                    .cornerRadius(10)
            }
            #endif
        } else if let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 260, maxHeight: 220)
                    .cornerRadius(10)
            } placeholder: {
                ProgressView()
                    .frame(width: 80, height: 80)
            }
        }
    }
}

// MARK: - Apple Image Playground View Modifier
extension View {
    @ViewBuilder
    func csmsImagePlayground(
        isPresented: Binding<Bool>,
        concept: String,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        #if canImport(ImagePlayground) && !os(watchOS) && !os(tvOS)
        if #available(iOS 18.2, macOS 15.2, *) {
            self.imagePlaygroundSheet(
                isPresented: isPresented,
                concept: concept,
                onCompletion: onCompletion,
                onCancellation: onCancellation
            )
        } else {
            self
        }
        #else
        self
        #endif
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let knownNames: [String]
    var currentUserName: String? = nil

    var isCokiAssistant: Bool {
        message.author_name.contains("Coki") ||
        message.author_name.contains("Apple Intelligence") ||
        message.author_name.contains("Gemini")
    }

    var isUserMentioned: Bool {
        guard let current = currentUserName, !current.isEmpty else { return false }
        return message.content.localizedCaseInsensitiveContains("@\(current)")
    }

    var formattedContent: LocalizedStringKey {
        var formatted = message.content
        
        // Highlight /Coki and /Genimg commands
        if formatted.contains("/Coki") {
            formatted = formatted.replacingOccurrences(of: "/Coki", with: "**[🤖 /Coki](mention:Coki)**")
        }
        if formatted.contains("@Coki") {
            formatted = formatted.replacingOccurrences(of: "@Coki", with: "**[🤖 @Coki](mention:Coki)**")
        }
        if formatted.contains("/Genimg") {
            formatted = formatted.replacingOccurrences(of: "/Genimg", with: "**[🎨 /Genimg](action:genimg)**")
        }

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
            if isCokiAssistant {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.indigo, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            } else if !isCurrentUser {
                CircleAvatarPlaceholder(initials: message.initials)
            } else {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser && !isCokiAssistant ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser || isCokiAssistant {
                    HStack(spacing: 6) {
                        Text(message.author_name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isCokiAssistant ? Color.purple : ForkarTheme.textSub)
                        
                        if isCokiAssistant {
                            HStack(spacing: 3) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8))
                                Text("Copiloto On-Device")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(Color.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.12))
                            .cornerRadius(6)
                        } else if isUserMentioned {
                            HStack(spacing: 3) {
                                Image(systemName: "at")
                                    .font(.system(size: 8, weight: .black))
                                Text("Te mencionó")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(Color.emerald)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.emerald.opacity(0.15))
                            .cornerRadius(6)
                        }
                    }
                }
                
                VStack(alignment: isCurrentUser && !isCokiAssistant ? .trailing : .leading, spacing: 6) {
                    if !message.content.isEmpty {
                        Text(formattedContent)
                            .font(.system(size: 14))
                    }
                    
                    // 📎 Media Attachments (Supports base64 data URIs, local files & HTTP)
                    if let mediaUrl = message.media_url, !mediaUrl.isEmpty {
                        let type = message.media_type ?? (mediaUrl.hasSuffix(".mp4") || mediaUrl.hasSuffix(".mov") ? "video" : "image")
                        if type == "image" {
                            CSMSMediaImageView(urlString: mediaUrl)
                        } else if type == "video", let url = URL(string: mediaUrl) {
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
                        } else if let url = URL(string: mediaUrl) {
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
                .background(isCokiAssistant ? ForkarTheme.card : (isCurrentUser ? ForkarTheme.accent : ForkarTheme.card))
                .foregroundColor(isCurrentUser && !isCokiAssistant ? .white : ForkarTheme.text)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCokiAssistant
                                ? LinearGradient(colors: [.purple, .indigo, .orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : (isUserMentioned
                                    ? LinearGradient(colors: [Color.emerald, Color.green], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)),
                            lineWidth: isCokiAssistant || isUserMentioned ? 1.5 : 1
                        )
                )
                .shadow(color: isCokiAssistant ? Color.purple.opacity(0.2) : Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                .padding(.horizontal, 4)
                
                HStack(spacing: 4) {
                    if message.isEncrypted {
                        Text("🔒")
                            .font(.system(size: 9))
                    }
                    Text(message.formattedTime)
                        .font(.system(size: 9))
                        .foregroundColor(ForkarTheme.textMuted)
                }
                .padding(.horizontal, 6)
            }
            
            if isCurrentUser && !isCokiAssistant {
                CircleAvatarPlaceholder(initials: message.initials)
            } else if !isCokiAssistant {
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
