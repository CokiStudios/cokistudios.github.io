import Foundation
import SwiftUI
import AuthenticationServices
internal import Combine

// ══════════════════════════════════════════════════════════════════
// ⚡ SUPABASE MANAGER — FORKAR MACOS & CSMS EXTENSION
// Conexión REST nativa optimizada con URLSession, OAuth & Polling
// ══════════════════════════════════════════════════════════════════

@MainActor
final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    // Configuración canónica de Coki Studios
    let supabaseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"
    
    // Estado de Sesión
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false
    @Published var accessToken: String?
    
    // Estado de Datos de Forkar
    @Published var posts: [Post] = []
    @Published var categories: [Category] = []
    @Published var isLoadingPosts: Bool = false
    
    // Estado de la Extensión CSMS
    @Published var csmsRooms: [CSMSChatRoom] = []
    @Published var csmsMessages: [CSMSMessage] = []
    @Published var unreadCSMSCount: Int = 0
    @Published var activeCSMSRoomId: String = "00000000-0000-4000-8000-000000000001"
    
    private var csmsPollTimer: AnyCancellable?
    
    private init() {
        loadDefaultCategories()
        restoreSession()
        startCSMSPolling()
    }
    
    // ─── 1. CATEGORÍAS CANÓNICAS ───
    private func loadDefaultCategories() {
        self.categories = [
            Category(id: "all", name: "Todos", slug: "all", color: "#6366F1", icon: "square.grid.2x2.fill"),
            Category(id: "cat-general", name: "General", slug: "general", color: "#6366F1", icon: "bubble.left.fill"),
            Category(id: "cat-dev", name: "Código & Dev", slug: "dev", color: "#38BDF8", icon: "chevron.left.forwardslash.chevron.right"),
            Category(id: "cat-eco", name: "Eco Hub", slug: "eco", color: "#10B981", icon: "leaf.fill"),
            Category(id: "cat-gaming", name: "Gaming", slug: "gaming", color: "#EC4899", icon: "gamecontroller.fill"),
            Category(id: "cat-design", name: "Diseño", slug: "design", color: "#F59E0B", icon: "paintpalette.fill")
        ]
    }
    
    // ─── 2. AUTENTICACIÓN ───
    func restoreSession() {
        if let token = UserDefaults.standard.string(forKey: "forkar_access_token"),
           let uid = UserDefaults.standard.string(forKey: "forkar_user_id"),
           let email = UserDefaults.standard.string(forKey: "forkar_user_email") {
            let name = UserDefaults.standard.string(forKey: "forkar_user_name") ?? email.components(separatedBy: "@").first ?? "Usuario"
            let avatar = UserDefaults.standard.string(forKey: "forkar_user_avatar")
            
            self.accessToken = token
            self.currentUser = UserProfile(id: uid, email: email, fullName: name, avatarUrl: avatar, bio: "Comunidad Forkar", followersCount: 12, followingCount: 8)
            self.isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String) async throws {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=password") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Credenciales incorrectas"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["access_token"] as? String,
           let userObj = json["user"] as? [String: Any],
           let uid = userObj["id"] as? String {
            
            let userMeta = userObj["user_metadata"] as? [String: Any]
            let name = userMeta?["full_name"] as? String ?? email.components(separatedBy: "@").first ?? "Usuario"
            let avatar = userMeta?["avatar_url"] as? String
            
            UserDefaults.standard.set(token, forKey: "forkar_access_token")
            UserDefaults.standard.set(uid, forKey: "forkar_user_id")
            UserDefaults.standard.set(email, forKey: "forkar_user_email")
            UserDefaults.standard.set(name, forKey: "forkar_user_name")
            UserDefaults.standard.set(avatar, forKey: "forkar_user_avatar")
            
            self.accessToken = token
            self.currentUser = UserProfile(id: uid, email: email, fullName: name, avatarUrl: avatar, bio: "Comunidad Forkar", followersCount: 1, followingCount: 0)
            self.isAuthenticated = true
        }
    }
    
    // MARK: - OAuth (Google & GitHub)
    func signInWithOAuth(provider: String) async throws {
        let callbackScheme = "forkar"
        guard let authURL = URL(string: "\(supabaseURL)/auth/v1/authorize?provider=\(provider)&redirect_to=forkar://oauth") else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL de autorización inválida"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta de autenticación"]))
                    return
                }
                
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    do {
                        try await self.handleOAuthCallback(url: callbackURL)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            session.presentationContextProvider = PresentationAnchorProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
    
    func handleOAuthCallback(url: URL) async throws {
        var token: String?
        
        // Revisar fragmento (#access_token=...)
        if let fragment = url.fragment {
            let pairs = fragment.components(separatedBy: "&")
            for pair in pairs {
                let parts = pair.components(separatedBy: "=")
                if parts.count == 2 && parts[0] == "access_token" {
                    token = parts[1].removingPercentEncoding
                    break
                }
            }
        }
        
        // Revisar query params (?access_token=...) si no vino en fragment
        if token == nil, let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let items = components.queryItems {
            token = items.first(where: { $0.name == "access_token" })?.value
        }
        
        guard let accessToken = token else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se encontró el token de acceso en la respuesta"])
        }
        
        try await loginWithToken(accessToken: accessToken)
    }
    
    func loginWithToken(accessToken: String) async throws {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/user") else { return }
        var request = URLRequest(url: url)
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Error al validar perfil de usuario"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let uid = json["id"] as? String {
            let email = json["email"] as? String
            let userMeta = json["user_metadata"] as? [String: Any]
            
            let name = userMeta?["full_name"] as? String
                ?? userMeta?["name"] as? String
                ?? userMeta?["user_name"] as? String
                ?? email?.components(separatedBy: "@").first
                ?? "Usuario"
            let avatar = userMeta?["avatar_url"] as? String
            
            UserDefaults.standard.set(accessToken, forKey: "forkar_access_token")
            UserDefaults.standard.set(uid, forKey: "forkar_user_id")
            if let email = email { UserDefaults.standard.set(email, forKey: "forkar_user_email") }
            UserDefaults.standard.set(name, forKey: "forkar_user_name")
            if let avatar = avatar { UserDefaults.standard.set(avatar, forKey: "forkar_user_avatar") }
            
            self.accessToken = accessToken
            self.currentUser = UserProfile(id: uid, email: email, fullName: name, avatarUrl: avatar, bio: "Comunidad Forkar", followersCount: 1, followingCount: 0)
            self.isAuthenticated = true
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "forkar_access_token")
        UserDefaults.standard.removeObject(forKey: "forkar_user_id")
        UserDefaults.standard.removeObject(forKey: "forkar_user_email")
        UserDefaults.standard.removeObject(forKey: "forkar_user_name")
        UserDefaults.standard.removeObject(forKey: "forkar_user_avatar")
        
        self.accessToken = nil
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    // ─── 3. PUBLICACIONES DE FORKAR ───
    func fetchPosts(categorySlug: String? = nil) async {
        self.isLoadingPosts = true
        defer { self.isLoadingPosts = false }
        
        var endpoint = "\(supabaseURL)/rest/v1/posts?select=*&order=created_at.desc&limit=50"
        if let cat = categorySlug, cat != "all" {
            endpoint += "&category_id=eq.\(cat)"
        }
        
        guard let url = URL(string: endpoint) else { return }
        var request = URLRequest(url: url)
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                let decoder = JSONDecoder()
                let fetched = try decoder.decode([Post].self, from: data)
                self.posts = fetched
            }
        } catch {
            print("Error cargando posts: \(error.localizedDescription)")
        }
    }
    
    func createPost(title: String, content: String, categoryId: String, imageUrl: String? = nil, videoUrl: String? = nil) async throws {
        guard let user = currentUser, let token = accessToken else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para publicar"])
        }
        
        guard let url = URL(string: "\(supabaseURL)/rest/v1/posts") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        var body: [String: Any] = [
            "title": title,
            "content": content,
            "category_id": categoryId,
            "user_id": user.id,
            "author_name": user.fullName ?? "Usuario",
            "author_avatar": user.avatarUrl as Any
        ]
        if let img = imageUrl, !img.isEmpty { body["image_url"] = img }
        if let vid = videoUrl, !vid.isEmpty { body["video_url"] = vid }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            await fetchPosts()
        }
    }
    
    // ─── 4. EXTENSIÓN CSMS NATIVA ───
    func startCSMSPolling() {
        // Inicializar salas públicas canónicas
        self.csmsRooms = [
            CSMSChatRoom(id: "00000000-0000-4000-8000-000000000001", name: "💬 Comunidad Global", isGroup: true, lastMessage: "Bienvenido a CSMS", lastMessageAt: nil, unreadCount: 0),
            CSMSChatRoom(id: "00000000-0000-4000-8000-000000000003", name: "🚗 Forkar Carpooling & Rutas", isGroup: true, lastMessage: "¿Quién viaja hoy a Bogotá?", lastMessageAt: nil, unreadCount: 0),
            CSMSChatRoom(id: "00000000-0000-4000-8000-000000000002", name: "🌿 Eco Hub & Sostenibilidad", isGroup: true, lastMessage: "Nuevas estaciones de reciclaje", lastMessageAt: nil, unreadCount: 0)
        ]
        
        // Polling cada 4 segundos para actualizar mensajes en vivo
        csmsPollTimer = Timer.publish(every: 4.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.fetchCSMSMessages(roomId: self.activeCSMSRoomId)
                }
            }
    }
    
    func fetchCSMSMessages(roomId: String) async {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/chat_messages?room_id=eq.\(roomId)&order=created_at.asc&limit=40") else { return }
        var request = URLRequest(url: url)
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                let decoder = JSONDecoder()
                let msgs = try decoder.decode([CSMSMessage].self, from: data)
                self.csmsMessages = msgs
            }
        } catch {
            // Manejo silencioso de polling
        }
    }
    
    func sendCSMSMessage(content: String, roomId: String) async throws {
        guard let user = currentUser, let token = accessToken else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para enviar mensajes"])
        }
        
        guard let url = URL(string: "\(supabaseURL)/rest/v1/chat_messages") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "room_id": roomId,
            "sender_id": user.id,
            "content": content,
            "author_name": user.fullName ?? "Usuario",
            "author_avatar": user.avatarUrl as Any
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            await fetchCSMSMessages(roomId: roomId)
        }
    }
}

// ─── PROVEEDOR DE ANCLAJE PARA ASWebAuthenticationSession EN MACOS ───
class PresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationAnchorProvider()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? NSApplication.shared.windows.first ?? NSWindow()
    }
}
