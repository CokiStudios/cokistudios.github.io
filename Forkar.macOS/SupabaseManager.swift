import Foundation
import SwiftUI
import AuthenticationServices
internal import Combine

// ══════════════════════════════════════════════════════════════════
// ⚡ SUPABASE MANAGER — FORKAR MACOS & CSMS EXTENSION
// Conexión REST dinámica con datos reales en tiempo real:
// social_posts, social_categories, social_comments, social_likes,
// chat_rooms, chat_messages, forkman_user_eco
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
    
    // Estado del Muro de Forkar
    @Published var posts: [Post] = []
    @Published var categories: [Category] = []
    @Published var isLoadingPosts: Bool = false
    @Published var userLikedPostIds: Set<String> = []
    
    // Estado de la Extensión CSMS
    @Published var csmsRooms: [CSMSChatRoom] = []
    @Published var csmsMessages: [CSMSMessage] = []
    @Published var activeCSMSRoomId: String = "00000000-0000-4000-8000-000000000001"
    @Published var isCSMSConnected: Bool = true
    
    // Estado de Eco Hub
    @Published var userEcoCo2Saved: Double = 0.0
    @Published var userEcoPoints: Int = 0
    @Published var ecoStations: [EcoStation] = []
    
    private var csmsPollTimer: AnyCancellable?
    
    private init() {
        restoreSession()
        loadDefaultStations()
        
        Task {
            await fetchCategories()
            await fetchPosts()
            await fetchCSMSRooms()
            await fetchUserEcoStats()
            startCSMSPolling()
        }
    }
    
    // ─── 1. AUTENTICACIÓN ───
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
            
            await fetchUserEcoStats()
        }
    }
    
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
            await fetchUserEcoStats()
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
    
    // ─── 2. CATEGORÍAS (social_categories) ───
    func fetchCategories() async {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/social_categories?select=*&order=name.asc") else { return }
        var request = URLRequest(url: url)
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                let fetched = try JSONDecoder().decode([Category].self, from: data)
                if !fetched.isEmpty {
                    self.categories = fetched
                }
            }
        } catch {
            print("Error cargando categorías de Supabase: \(error.localizedDescription)")
        }
        
        // Si falló o está vacía, asegurar al menos las predeterminadas
        if self.categories.isEmpty {
            self.categories = [
                Category(id: "all", name: "Todos", slug: "all", color: "#6366F1", description: "Todas las publicaciones", createdAt: nil),
                Category(id: "494f6ad4-8425-440b-a4de-103b0cdf6c41", name: "General", slug: "general", color: "#6366F1", description: "Comunidad global", createdAt: nil),
                Category(id: "6a6a1579-8172-454c-8f40-215e6800a54e", name: "Videojuegos", slug: "gaming", color: "#EC4899", description: "Arcade & gaming", createdAt: nil),
                Category(id: "4456a3a5-4811-4ad5-966b-1e86ff943895", name: "Ideas", slug: "ideas", color: "#F59E0B", description: "Propuestas", createdAt: nil),
                Category(id: "b63feb8e-0e55-4383-ac1d-c48febbab6eb", name: "Productos", slug: "productos", color: "#10B981", description: "Soporte Coki", createdAt: nil)
            ]
        }
    }
    
    // ─── 3. MURO DE PUBLICACIONES (social_posts) ───
    func fetchPosts(categoryId: String? = nil, searchQuery: String? = nil) async {
        self.isLoadingPosts = true
        defer { self.isLoadingPosts = false }
        
        var endpoint = "\(supabaseURL)/rest/v1/social_posts?select=*,category:social_categories(id,name,slug,color)&order=created_at.desc&limit=50"
        if let cat = categoryId, cat != "all" {
            endpoint += "&category_id=eq.\(cat)"
        }
        if let query = searchQuery, !query.isEmpty {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            endpoint += "&or=(title.ilike.*\(encoded)*,content.ilike.*\(encoded)*)"
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
                let fetched = try JSONDecoder().decode([Post].self, from: data)
                self.posts = fetched
            }
        } catch {
            print("Error cargando publicaciones reales: \(error.localizedDescription)")
        }
    }
    
    func createPost(title: String, content: String, categoryId: String, imageUrl: String? = nil, videoUrl: String? = nil) async throws {
        guard let user = currentUser, let token = accessToken else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para publicar en el muro"])
        }
        
        guard let url = URL(string: "\(supabaseURL)/rest/v1/social_posts") else { return }
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
    
    // ─── 4. LIKES Y COMENTARIOS REALES ───
    func toggleLike(postId: String) async {
        guard let user = currentUser, let token = accessToken else { return }
        let isLiked = userLikedPostIds.contains(postId)
        
        if isLiked {
            userLikedPostIds.remove(postId)
            // Borrar de social_likes
            guard let url = URL(string: "\(supabaseURL)/rest/v1/social_likes?post_id=eq.\(postId)&user_id=eq.\(user.id)") else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "DELETE"
            req.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: req)
        } else {
            userLikedPostIds.insert(postId)
            // Insertar en social_likes
            guard let url = URL(string: "\(supabaseURL)/rest/v1/social_likes") else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = ["post_id": postId, "user_id": user.id]
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            _ = try? await URLSession.shared.data(for: req)
        }
    }
    
    func fetchComments(postId: String) async -> [PostComment] {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/social_comments?select=*&post_id=eq.\(postId)&order=created_at.asc") else { return [] }
        var request = URLRequest(url: url)
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                return try JSONDecoder().decode([PostComment].self, from: data)
            }
        } catch {
            print("Error cargando comentarios: \(error.localizedDescription)")
        }
        return []
    }
    
    func addComment(postId: String, content: String) async throws -> PostComment {
        guard let user = currentUser, let token = accessToken else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para comentar"])
        }
        
        guard let url = URL(string: "\(supabaseURL)/rest/v1/social_comments") else {
            throw NSError(domain: "Supabase", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let body: [String: Any] = [
            "post_id": postId,
            "user_id": user.id,
            "author_name": user.fullName ?? "Usuario",
            "author_avatar": user.avatarUrl as Any,
            "content": content
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "Supabase", code: 400, userInfo: [NSLocalizedDescriptionKey: "Error al publicar comentario"])
        }
        let list = try JSONDecoder().decode([PostComment].self, from: data)
        guard let comment = list.first else {
            throw NSError(domain: "Supabase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta vacía"])
        }
        return comment
    }
    
    // ─── 5. EXTENSIÓN CSMS REAL (chat_rooms & chat_messages) ───
    func fetchCSMSRooms() async {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/chat_rooms?select=*&order=created_at.desc&limit=30") else { return }
        var request = URLRequest(url: url)
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                let fetched = try JSONDecoder().decode([CSMSChatRoom].self, from: data)
                if !fetched.isEmpty {
                    self.csmsRooms = fetched
                    if !fetched.contains(where: { $0.id == activeCSMSRoomId }), let first = fetched.first {
                        self.activeCSMSRoomId = first.id
                    }
                }
            }
        } catch {
            print("Error obteniendo salas CSMS: \(error.localizedDescription)")
        }
        
        // Fallback canónico si no hay salas
        if self.csmsRooms.isEmpty {
            self.csmsRooms = [
                CSMSChatRoom(id: "00000000-0000-4000-8000-000000000001", name: "💬 Comunidad Coki Studios Global", isGroup: true, createdBy: nil, createdAt: nil),
                CSMSChatRoom(id: "00000000-0000-4000-8000-000000000003", name: "🚗 Forkar Carpooling & Rutas", isGroup: true, createdBy: nil, createdAt: nil),
                CSMSChatRoom(id: "00000000-0000-4000-8000-000000000002", name: "🌿 Eco Hub & Sostenibilidad", isGroup: true, createdBy: nil, createdAt: nil)
            ]
        }
    }
    
    func startCSMSPolling() {
        csmsPollTimer = Timer.publish(every: 3.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.fetchCSMSMessages(roomId: self.activeCSMSRoomId)
                }
            }
    }
    
    func fetchCSMSMessages(roomId: String) async {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/chat_messages?room_id=eq.\(roomId)&order=created_at.asc&limit=60") else { return }
        var request = URLRequest(url: url)
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                let msgs = try JSONDecoder().decode([CSMSMessage].self, from: data)
                self.csmsMessages = msgs
                self.isCSMSConnected = true
            }
        } catch {
            self.isCSMSConnected = false
        }
    }
    
    func sendCSMSMessage(content: String, roomId: String) async throws {
        guard let user = currentUser, let token = accessToken else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para enviar mensajes en CSMS"])
        }
        
        guard let url = URL(string: "\(supabaseURL)/rest/v1/chat_messages") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        // Mapeo canónico a la tabla real de Supabase (user_id, no sender_id)
        let body: [String: Any] = [
            "room_id": roomId,
            "user_id": user.id,
            "author_name": user.fullName ?? user.email ?? "Usuario",
            "author_avatar": user.avatarUrl as Any,
            "content": content
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            await fetchCSMSMessages(roomId: roomId)
        }
    }
    
    // ─── 6. ECO HUB DINÁMICO (forkman_user_eco) ───
    func fetchUserEcoStats() async {
        var endpoint = "\(supabaseURL)/rest/v1/forkman_user_eco?select=*"
        if let user = currentUser {
            endpoint += "&user_id=eq.\(user.id)"
        }
        endpoint += "&order=created_at.desc&limit=100"
        
        guard let url = URL(string: endpoint) else { return }
        var request = URLRequest(url: url)
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                let records = try JSONDecoder().decode([UserEcoRecord].self, from: data)
                let totalCo2 = records.reduce(0.0) { $0 + $1.co2Saved }
                let totalPoints = records.reduce(0) { $0 + $1.pointsEarned }
                
                if totalPoints > 0 || totalCo2 > 0 {
                    self.userEcoCo2Saved = totalCo2
                    self.userEcoPoints = totalPoints
                } else {
                    // Cargar de almacenamiento local si existe
                    self.userEcoCo2Saved = UserDefaults.standard.double(forKey: "forkar_co2_saved")
                    self.userEcoPoints = UserDefaults.standard.integer(forKey: "forkar_eco_points")
                }
            }
        } catch {
            self.userEcoCo2Saved = UserDefaults.standard.double(forKey: "forkar_co2_saved")
            self.userEcoPoints = UserDefaults.standard.integer(forKey: "forkar_eco_points")
        }
    }
    
    func logEcoAction(title: String, co2Saved: Double, pointsEarned: Int) async throws {
        guard let user = currentUser, let token = accessToken else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para registrar impacto ecológico"])
        }
        
        guard let url = URL(string: "\(supabaseURL)/rest/v1/forkman_user_eco") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user_id": user.id,
            "co2_saved": co2Saved,
            "points_earned": pointsEarned
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            self.userEcoCo2Saved += co2Saved
            self.userEcoPoints += pointsEarned
            UserDefaults.standard.set(self.userEcoCo2Saved, forKey: "forkar_co2_saved")
            UserDefaults.standard.set(self.userEcoPoints, forKey: "forkar_eco_points")
        }
    }
    
    private func loadDefaultStations() {
        self.ecoStations = [
            EcoStation(
                id: "cota-central",
                name: "Punto Verde Parque Principal (Cota)",
                address: "Plaza Central • Cota, Cundinamarca",
                type: "Plásticos, Cartón y Compostaje",
                municipality: "Cota",
                status: "Operativo",
                distance: "0.4 km",
                iconName: "leaf.circle.fill"
            ),
            EcoStation(
                id: "cota-bici",
                name: "Estación Bici Cota Sostenible",
                address: "Vía Siberia - Cota Km 2.5",
                type: "Ruta Ciclista & Préstamo Verde",
                municipality: "Cota",
                status: "Operativo",
                distance: "1.2 km",
                iconName: "bicycle"
            ),
            EcoStation(
                id: "cota-raee",
                name: "Punto RAEE Electrónicos Alcaldía",
                address: "Cra 4 #12-34 • Cota",
                type: "Baterías, Hardware y Cables",
                municipality: "Cota",
                status: "Operativo",
                distance: "0.8 km",
                iconName: "bolt.fill"
            ),
            EcoStation(
                id: "chia-fontanar",
                name: "EcoPunto Fontanar Chía",
                address: "Km 21 Vía Chía - Cajicá",
                type: "Vidrio, Aluminio y Envases",
                municipality: "Chía",
                status: "Operativo",
                distance: "4.5 km",
                iconName: "shippingbox.fill"
            ),
            EcoStation(
                id: "bogota-parque93",
                name: "Estación Verde Parque 93",
                address: "Cra 11A #93A-12 • Bogotá",
                type: "Multirreciclaje Urbano",
                municipality: "Bogotá",
                status: "Operativo",
                distance: "8.2 km",
                iconName: "mappin.and.ellipse"
            )
        ]
    }
}

// ─── PROVEEDOR DE ANCLAJE PARA ASWebAuthenticationSession EN MACOS ───
class PresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationAnchorProvider()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? NSApplication.shared.windows.first ?? NSWindow()
    }
}
