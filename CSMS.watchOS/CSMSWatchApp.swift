import SwiftUI
import WatchKit

// MARK: - Models
struct WatchChatRoom: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String?
    let is_group: Bool
    let created_at: String
    
    var displayName: String {
        name ?? "Chat Privado"
    }
}

struct WatchChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let room_id: UUID
    let sender_id: UUID
    let content: String
    let created_at: String
    
    var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: created_at) ?? ISO8601DateFormatter().date(from: created_at) else {
            return ""
        }
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: date)
    }
}

// MARK: - Supabase Watch Manager
class WatchSupabaseManager: ObservableObject {
    static let shared = WatchSupabaseManager()
    
    let baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"
    
    @Published var currentUserEmail: String = "ceosupport@cokistudios.com"
    @Published var currentUserId: UUID = UUID(uuidString: "88888888-4444-4444-4444-121212121212") ?? UUID()
    @Published var rooms: [WatchChatRoom] = []
    @Published var isLoading = false
    
    init() {
        if let storedEmail = UserDefaults.standard.string(forKey: "cs_watch_user_email") {
            currentUserEmail = storedEmail
        }
        if let storedId = UserDefaults.standard.string(forKey: "cs_watch_user_id"), let uuid = UUID(uuidString: storedId) {
            currentUserId = uuid
        }
    }
    
    func fetchRooms() async {
        await MainActor.run { isLoading = true }
        guard let url = URL(string: "\(baseURL)/rest/v1/chat_rooms?select=*&order=created_at.desc") else { return }
        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                let decoded = try JSONDecoder().decode([WatchChatRoom].self, from: data)
                await MainActor.run {
                    self.rooms = decoded
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
    
    func fetchMessages(roomId: UUID) async -> [WatchChatMessage] {
        guard let url = URL(string: "\(baseURL)/rest/v1/chat_messages?select=*&room_id=eq.\(roomId.uuidString)&order=created_at.asc") else { return [] }
        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                return (try? JSONDecoder().decode([WatchChatMessage].self, from: data)) ?? []
            }
        } catch {}
        return []
    }
    
    func sendMessage(roomId: UUID, content: String) async -> Bool {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let url = URL(string: "\(baseURL)/rest/v1/chat_messages") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let payload: [String: Any] = [
            "room_id": roomId.uuidString,
            "sender_id": currentUserId.uuidString,
            "content": content
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return false }
        request.httpBody = httpBody
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                return true
            }
        } catch {}
        return false
    }
}

// MARK: - App Entry Point
@main
struct CSMSWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRoomsListView()
        }
    }
}

// MARK: - Watch Rooms List View
struct WatchRoomsListView: View {
    @StateObject private var supabase = WatchSupabaseManager.shared
    @State private var showQuickReplies = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if supabase.isLoading && supabase.rooms.isEmpty {
                    ProgressView()
                        .tint(Color(red: 99/255, green: 102/255, blue: 241/255))
                } else if supabase.rooms.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 99/255, green: 102/255, blue: 241/255))
                        Text("No hay chats")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("Desliza para actualizar")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(supabase.rooms) { room in
                            NavigationLink(destination: WatchChatDetailView(room: room)) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 139/255, green: 92/255, blue: 246/255)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 28, height: 28)
                                        
                                        Image(systemName: room.is_group ? "person.2.fill" : "message.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(room.displayName)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Text(room.is_group ? "Grupo CSMS" : "Directo")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(white: 0.12))
                            )
                        }
                    }
                    .listStyle(.carousel)
                }
            }
            .navigationTitle("CSMS Chats")
            .task {
                await supabase.fetchRooms()
            }
            .refreshable {
                await supabase.fetchRooms()
            }
        }
    }
}

// MARK: - Watch Chat Detail View with Voice & Quick Dictation
struct WatchChatDetailView: View {
    let room: WatchChatRoom
    @StateObject private var supabase = WatchSupabaseManager.shared
    @State private var messages: [WatchChatMessage] = []
    @State private var isLoading = false
    @State private var quickText = ""
    @State private var showVoiceInput = false
    
    let quickReplies = [
        "¡Hola! 👋",
        "En camino 🏃‍♂️",
        "Listo ✅",
        "Hablamos luego ⏳",
        "De acuerdo 👍",
        "Revisando Forkar 🌿"
    ]
    
    @State private var showQuickRepliesSheet = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    // Quick Action Bar
                    HStack(spacing: 6) {
                        Button(action: {
                            showQuickRepliesSheet = true
                        }) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.yellow)
                                .frame(width: 32, height: 32)
                                .background(Color(white: 0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        TextField("Mensaje...", text: $quickText)
                            .font(.system(size: 12))
                            .onSubmit {
                                sendQuickReply(quickText)
                                quickText = ""
                            }
                    }
                    .padding(.horizontal, 4)
                    
                    if messages.isEmpty && !isLoading {
                        Text("Sin mensajes recientes")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    } else {
                        ForEach(messages) { msg in
                            let isMe = msg.sender_id == supabase.currentUserId
                            
                            HStack {
                                if isMe { Spacer() }
                                
                                VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                                    Text(msg.content)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            isMe
                                            ? Color(red: 99/255, green: 102/255, blue: 241/255)
                                            : Color(white: 0.18)
                                        )
                                        .cornerRadius(12)
                                    
                                    Text(msg.formattedTime)
                                        .font(.system(size: 9))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                }
                                .id(msg.id)
                                
                                if !isMe { Spacer() }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle(room.displayName)
            .sheet(isPresented: $showQuickRepliesSheet) {
                ScrollView {
                    VStack(spacing: 6) {
                        Text("Respuestas Rápidas")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 4)
                        
                        ForEach(quickReplies, id: \.self) { reply in
                            Button(action: {
                                showQuickRepliesSheet = false
                                sendQuickReply(reply)
                            }) {
                                HStack {
                                    Text(reply)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color(white: 0.16))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(8)
                }
            }
            .task {
                await loadMessages()
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .refreshable {
                await loadMessages()
            }
        }
    }
    
    private func loadMessages() async {
        isLoading = true
        let msgs = await supabase.fetchMessages(roomId: room.id)
        await MainActor.run {
            self.messages = msgs
            self.isLoading = false
        }
    }
    
    private func sendQuickReply(_ text: String) {
        guard !text.isEmpty else { return }
        WKInterfaceDevice.current().play(.click)
        Task {
            let success = await supabase.sendMessage(roomId: room.id, content: text)
            if success {
                await loadMessages()
            }
        }
    }
}
