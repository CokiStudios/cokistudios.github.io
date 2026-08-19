import Foundation
import Combine
import WatchConnectivity
import AuthenticationServices

// MARK: - Supabase Models
struct SupabaseUser: Codable, Identifiable {
    let id: UUID
    let email: String?
    let user_metadata: UserMetadata?
    
    struct UserMetadata: Codable {
        let full_name: String?
        let name: String?
        let avatar_url: String?
        let picture: String?
        let company: String?
        let role: String?
    }
}

struct SupabaseAuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
    let user: SupabaseUser
}

struct CSMSChatRoom: Codable, Identifiable {
    let id: UUID
    let name: String?
    let is_group: Bool?
    let created_by: UUID?
    let created_at: String?
    
    var displayName: String {
        return name ?? "Chat de Grupo"
    }
}

struct CSMSChatMessage: Codable, Identifiable {
    let id: UUID
    let room_id: UUID
    let sender_id: String
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

// MARK: - Supabase Manager
class SupabaseManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = SupabaseManager()
    
    let baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"
    
    @Published var currentUser: SupabaseUser? = nil {
        didSet {
            if let user = currentUser {
                if let data = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(data, forKey: "supabase_current_user")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "supabase_current_user")
            }
            syncSessionToWatch()
        }
    }
    
    @Published var sessionToken: String? = nil {
        didSet {
            if let token = sessionToken {
                UserDefaults.standard.set(token, forKey: "supabase_session_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "supabase_session_token")
            }
        }
    }
    
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    override init() {
        super.init()
        if let token = UserDefaults.standard.string(forKey: "supabase_session_token") {
            self.sessionToken = token
        }
        if let userData = UserDefaults.standard.data(forKey: "supabase_current_user"),
           let user = try? JSONDecoder().decode(SupabaseUser.self, from: userData) {
            self.currentUser = user
        }
        setupWatchConnectivity()
    }
    
    // MARK: - WatchConnectivity Setup
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func syncSessionToWatch() {
        guard WCSession.isSupported() && WCSession.default.activationState == .activated else { return }
        let context: [String: Any] = [
            "user_email": currentUser?.email ?? "ceosupport@cokistudios.com",
            "user_id": currentUser?.id.uuidString ?? "88888888-4444-4444-4444-121212121212"
        ]
        try? WCSession.default.updateApplicationContext(context)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            syncSessionToWatch()
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    private func makeRequest(path: String, method: String = "GET", body: Data? = nil, queryItems: [URLQueryItem] = []) -> URLRequest {
        var components = URLComponents(string: "\(baseURL)\(path)")!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        
        if let token = sessionToken, token.components(separatedBy: ".").count == 3 {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("return=representation", forHTTPHeaderField: "Prefer")
            request.httpBody = body
        }
        return request
    }
    
    // MARK: - Auth API
    @MainActor
    func login(email: String, password: String) async throws {
        let path = "/auth/v1/token"
        let queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        let bodyJson = ["email": email, "password": password]
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        
        let request = makeRequest(path: path, method: "POST", body: bodyData, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let desc = errorObj["error_description"] as? String ?? errorObj["msg"] as? String {
                throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: desc])
            }
            throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Authentication failed (\(httpResponse.statusCode))"])
        }
        
        let authResponse = try JSONDecoder().decode(SupabaseAuthResponse.self, from: data)
        self.currentUser = authResponse.user
        self.sessionToken = authResponse.access_token
    }
    
    @MainActor
    func signUp(email: String, password: String, name: String) async throws {
        let path = "/auth/v1/signup"
        let metadataJson: [String: Any] = [
            "full_name": name,
            "name": name,
            "company": "Coki Studios",
            "role": "user"
        ]
        let bodyJson: [String: Any] = [
            "email": email,
            "password": password,
            "data": metadataJson
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = errorObj["msg"] as? String ?? errorObj["message"] as? String {
                throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Registration failed"])
        }
        
        try await login(email: email, password: password)
    }
    
    // MARK: - OAuth API
    @MainActor
    func signInWithOAuth(provider: String) async throws {
        let authURL = URL(string: "\(baseURL)/auth/v1/authorize?provider=\(provider)&redirect_to=csms://oauth")!
        let callbackScheme = "csms"
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No callback URL"]))
                    return
                }
                
                Task {
                    do {
                        try await self.handleOAuthCallback(url: callbackURL)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            session.presentationContextProvider = CSMSPresentationAnchorProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
    
    private func handleOAuthCallback(url: URL) async throws {
        guard let fragment = url.fragment else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid callback URL"])
        }
        
        var parameters: [String: String] = [:]
        let pairs = fragment.components(separatedBy: "&")
        for pair in pairs {
            let parts = pair.components(separatedBy: "=")
            if parts.count == 2 {
                parameters[parts[0]] = parts[1].removingPercentEncoding
            }
        }
        
        guard let accessToken = parameters["access_token"] else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing access token in callback"])
        }
        
        try await loginWithToken(accessToken: accessToken)
    }
    
    func loginWithToken(accessToken: String) async throws {
        let path = "/auth/v1/user"
        var request = makeRequest(path: path, method: "GET")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al obtener perfil de usuario"])
        }
        
        let user = try JSONDecoder().decode(SupabaseUser.self, from: data)
        await MainActor.run {
            self.currentUser = user
            self.sessionToken = accessToken
        }
    }
    
    @MainActor
    func logout() {
        self.currentUser = nil
        self.sessionToken = nil
        UserDefaults.standard.removeObject(forKey: "supabase_session_token")
        UserDefaults.standard.removeObject(forKey: "supabase_current_user")
    }
    
    // MARK: - Chat API
    @MainActor
    func fetchChatRooms() async throws -> [CSMSChatRoom] {
        let path = "/rest/v1/chat_rooms"
        let queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, res) = try await URLSession.shared.data(for: request)
        if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            return (try? JSONDecoder().decode([CSMSChatRoom].self, from: data)) ?? []
        }
        return []
    }
    
    @MainActor
    func createGroupChat(name: String) async throws -> Bool {
        guard let user = currentUser else { return false }
        let path = "/rest/v1/chat_rooms"
        let dict: [String: Any] = [
            "name": name,
            "is_group": true,
            "created_by": user.id.uuidString
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: dict)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (_, res) = try await URLSession.shared.data(for: request)
        if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            return true
        }
        return false
    }
    
    @MainActor
    func fetchChatMessages(roomId: UUID) async throws -> [CSMSChatMessage] {
        let path = "/rest/v1/chat_messages"
        let queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "room_id", value: "eq.\(roomId.uuidString)"),
            URLQueryItem(name: "order", value: "created_at.asc")
        ]
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, res) = try await URLSession.shared.data(for: request)
        if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            return (try? JSONDecoder().decode([CSMSChatMessage].self, from: data)) ?? []
        }
        return []
    }
    
    @MainActor
    func sendMessage(roomId: UUID, content: String) async throws -> Bool {
        guard let user = currentUser else { return false }
        let path = "/rest/v1/chat_messages"
        let dict: [String: Any] = [
            "room_id": roomId.uuidString,
            "sender_id": user.id.uuidString,
            "content": content
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: dict)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (_, res) = try await URLSession.shared.data(for: request)
        if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            return true
        }
        return false
    }
}

// MARK: - Presentation Anchor Provider
class CSMSPresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = CSMSPresentationAnchorProvider()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(macOS)
        return NSApplication.shared.windows.first { $0.isKeyWindow } ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #else
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow } ?? windowScene?.windows.first
        return window ?? ASPresentationAnchor()
        #endif
    }
}
