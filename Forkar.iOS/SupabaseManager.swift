import Foundation
import Combine
import AuthenticationServices
import UIKit

// MARK: - Auth Response Structs
struct SupabaseAuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String
    let user: SupabaseUser
}

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

// MARK: - Supabase Manager
class SupabaseManager: ObservableObject {
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
        sessionToken != nil
    }
    
    private init() {
        // Load session
        self.sessionToken = UserDefaults.standard.string(forKey: "supabase_session_token")
        if let data = UserDefaults.standard.data(forKey: "supabase_current_user") {
            self.currentUser = try? JSONDecoder().decode(SupabaseUser.self, from: data)
        }
    }
    
    // MARK: - Request Builder
    private func makeRequest(path: String, method: String = "GET", body: Data? = nil, queryItems: [URLQueryItem] = []) -> URLRequest {
        var components = URLComponents(string: "\(baseURL)\(path)")!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        if let token = sessionToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
        
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
            request.httpBody = body
        }
        
        return request
    }
    
    private func verifyResponse(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let msg = errorObj["message"] as? String ?? errorObj["msg"] as? String ?? errorObj["error_description"] as? String ?? "HTTP Error \(httpResponse.statusCode)"
                
                if httpResponse.statusCode == 401 || msg.lowercased().contains("jwt") {
                    self.logout()
                }
                
                throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            
            if httpResponse.statusCode == 401 {
                self.logout()
            }
            throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Request failed with status code \(httpResponse.statusCode)"])
        }
    }
    
    // MARK: - Authentication API
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
        
        if httpResponse.statusCode != 200 {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let desc = errorObj["error_description"] as? String {
                throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: desc])
            }
            throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Authentication failed (\(httpResponse.statusCode))"])
        }
        
        let authResponse = try JSONDecoder().decode(SupabaseAuthResponse.self, from: data)
        await MainActor.run {
            self.currentUser = authResponse.user
            self.sessionToken = authResponse.access_token
        }
    }
    
    func signUp(email: String, password: String, name: String, company: String? = nil) async throws {
        let path = "/auth/v1/signup"
        
        var metadataJson: [String: Any] = [
            "full_name": name,
            "name": name,
            "role": "user"
        ]
        
        if let comp = company, !comp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            metadataJson["company"] = comp
        } else {
            metadataJson["company"] = "Coki Studios"
        }
        
        let bodyJson: [String: Any] = [
            "email": email,
            "password": password,
            "options": [
                "data": metadataJson,
                "email_redirect_to": "https://cokistudios.github.io/coki-confirm.html"
            ]
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let desc = errorObj["msg"] as? String {
                throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: desc])
            }
            throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Registration failed (\(httpResponse.statusCode))"])
        }
        
        // Automatical log in if credentials allow, or wait for verification if email verification is enabled.
        // Usually, try logging in immediately.
        try await login(email: email, password: password)
    }
    
    func logout() {
        DispatchQueue.main.async {
            self.currentUser = nil
            self.sessionToken = nil
            UserDefaults.standard.removeObject(forKey: "supabase_session_token")
            UserDefaults.standard.removeObject(forKey: "supabase_current_user")
        }
    }
    
    // MARK: - Categories API
    func fetchCategories() async throws -> [Category] {
        let path = "/rest/v1/social_categories"
        let queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "name.asc")
        ]
        
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        return try JSONDecoder().decode([Category].self, from: data)
    }
    
    // MARK: - Posts API
    func fetchPosts(categoryId: UUID? = nil, query: String? = nil, userId: UUID? = nil) async throws -> [Post] {
        let path = "/rest/v1/social_posts"
        var queryItems = [
            URLQueryItem(name: "select", value: "*,category:social_categories(id,name,slug,color)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        
        if let catId = categoryId {
            queryItems.append(URLQueryItem(name: "category_id", value: "eq.\(catId.uuidString.lowercased())"))
        }
        if let uId = userId {
            queryItems.append(URLQueryItem(name: "user_id", value: "eq.\(uId.uuidString.lowercased())"))
        }
        if let searchQuery = query, !searchQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "or", value: "(title.ilike.*\(searchQuery)*,content.ilike.*\(searchQuery)*)"))
        }
        
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        
        if let jsonStr = String(data: data, encoding: .utf8) {
            print("Posts Response JSON: \(jsonStr)")
        }
        
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    func createPost(title: String, content: String, categoryId: UUID) async throws -> Post {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para publicar"])
        }
        
        let path = "/rest/v1/social_posts"
        let authorName = user.user_metadata?.full_name ?? user.user_metadata?.name ?? user.email?.components(separatedBy: "@").first ?? "Usuario"
        let authorAvatar = user.user_metadata?.avatar_url ?? user.user_metadata?.picture
        
        var bodyJson: [String: Any] = [
            "user_id": user.id.uuidString.lowercased(),
            "author_name": authorName,
            "title": title,
            "content": content,
            "category_id": categoryId.uuidString.lowercased()
        ]
        
        if let avatar = authorAvatar {
            bodyJson["author_avatar"] = avatar
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        
        let posts = try JSONDecoder().decode([Post].self, from: data)
        guard let newPost = posts.first else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al crear la publicación"])
        }
        return newPost
    }
    
    func deletePost(postId: UUID) async throws {
        let path = "/rest/v1/social_posts"
        let queryItems = [URLQueryItem(name: "id", value: "eq.\(postId.uuidString.lowercased())")]
        
        let request = makeRequest(path: path, method: "DELETE", queryItems: queryItems)
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al borrar la publicación"])
        }
    }
    
    // MARK: - Comments API
    func fetchComments(postId: UUID) async throws -> [Comment] {
        let path = "/rest/v1/social_comments"
        let queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "post_id", value: "eq.\(postId.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "created_at.asc")
        ]
        
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        return try JSONDecoder().decode([Comment].self, from: data)
    }
    
    func createComment(postId: UUID, content: String) async throws -> Comment {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para comentar"])
        }
        
        let path = "/rest/v1/social_comments"
        let authorName = user.user_metadata?.full_name ?? user.user_metadata?.name ?? user.email?.components(separatedBy: "@").first ?? "Usuario"
        let authorAvatar = user.user_metadata?.avatar_url ?? user.user_metadata?.picture
        
        var bodyJson: [String: Any] = [
            "post_id": postId.uuidString.lowercased(),
            "user_id": user.id.uuidString.lowercased(),
            "author_name": authorName,
            "content": content
        ]
        
        if let avatar = authorAvatar {
            bodyJson["author_avatar"] = avatar
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        
        let comments = try JSONDecoder().decode([Comment].self, from: data)
        guard let newComment = comments.first else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al publicar comentario"])
        }
        return newComment
    }
    
    // MARK: - Likes API
    func checkIfLiked(postId: UUID) async throws -> Bool {
        guard let user = currentUser else { return false }
        
        let path = "/rest/v1/social_likes"
        let queryItems = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "post_id", value: "eq.\(postId.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(user.id.uuidString.lowercased())")
        ]
        
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        
        if let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return !list.isEmpty
        }
        return false
    }
    
    func toggleLike(postId: UUID) async throws -> Bool {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para dar like"])
        }
        
        let alreadyLiked = try await checkIfLiked(postId: postId)
        let path = "/rest/v1/social_likes"
        
        if alreadyLiked {
            let queryItems = [
                URLQueryItem(name: "post_id", value: "eq.\(postId.uuidString.lowercased())"),
                URLQueryItem(name: "user_id", value: "eq.\(user.id.uuidString.lowercased())")
            ]
            let request = makeRequest(path: path, method: "DELETE", queryItems: queryItems)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al quitar like"])
            }
            return false
        } else {
            let bodyJson = [
                "post_id": postId.uuidString.lowercased(),
                "user_id": user.id.uuidString.lowercased()
            ]
            let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
            let request = makeRequest(path: path, method: "POST", body: bodyData)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al dar like"])
            }
            return true
        }
    }
    
    // MARK: - Follows API
    func checkFollowStatus(targetUserId: UUID) async throws -> Bool {
        guard let user = currentUser else { return false }
        if user.id == targetUserId { return false }
        
        let path = "/rest/v1/social_follows"
        let queryItems = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "follower_id", value: "eq.\(user.id.uuidString.lowercased())"),
            URLQueryItem(name: "following_id", value: "eq.\(targetUserId.uuidString.lowercased())")
        ]
        
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        
        if let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return !list.isEmpty
        }
        return false
    }
    
    func getFollowStats(userId: UUID) async throws -> (followers: Int, following: Int) {
        let path = "/rest/v1/social_follows"
        
        // Followers count
        let followersRequest = makeRequest(path: path, queryItems: [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "following_id", value: "eq.\(userId.uuidString.lowercased())")
        ])
        let (followersData, followersResponse) = try await URLSession.shared.data(for: followersRequest)
        try verifyResponse(data: followersData, response: followersResponse)
        let followersCount = (try? JSONSerialization.jsonObject(with: followersData) as? [[String: Any]])?.count ?? 0
        
        // Following count
        let followingRequest = makeRequest(path: path, queryItems: [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "follower_id", value: "eq.\(userId.uuidString.lowercased())")
        ])
        let (followingData, followingResponse) = try await URLSession.shared.data(for: followingRequest)
        try verifyResponse(data: followingData, response: followingResponse)
        let followingCount = (try? JSONSerialization.jsonObject(with: followingData) as? [[String: Any]])?.count ?? 0
        
        return (followersCount, followingCount)
    }
    
    func toggleFollow(targetUserId: UUID) async throws -> Bool {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para seguir"])
        }
        if user.id == targetUserId {
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No puedes seguirte a ti mismo"])
        }
        
        let following = try await checkFollowStatus(targetUserId: targetUserId)
        let path = "/rest/v1/social_follows"
        
        if following {
            let queryItems = [
                URLQueryItem(name: "follower_id", value: "eq.\(user.id.uuidString.lowercased())"),
                URLQueryItem(name: "following_id", value: "eq.\(targetUserId.uuidString.lowercased())")
            ]
            let request = makeRequest(path: path, method: "DELETE", queryItems: queryItems)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al dejar de seguir"])
            }
            return false
        } else {
            let bodyJson = [
                "follower_id": user.id.uuidString.lowercased(),
                "following_id": targetUserId.uuidString.lowercased()
            ]
            let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
            let request = makeRequest(path: path, method: "POST", body: bodyData)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al seguir"])
            }
            return true
        }
    }
    
    // MARK: - OAuth API
    @MainActor
    func signInWithOAuth(provider: String) async throws {
        let authURL = URL(string: "\(baseURL)/auth/v1/authorize?provider=\(provider)&redirect_to=forkar://oauth")!
        let callbackScheme = "forkar"
        
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
            
            session.presentationContextProvider = PresentationAnchorProvider.shared
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
    
    // MARK: - Moderation API
    func reportPost(postId: UUID, reason: String, details: String? = nil) async throws {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para reportar"])
        }
        
        let path = "/rest/v1/social_reports"
        var bodyJson: [String: Any] = [
            "reporter_id": user.id.uuidString.lowercased(),
            "post_id": postId.uuidString.lowercased(),
            "reason": reason
        ]
        
        if let d = details, !d.isEmpty {
            bodyJson["details"] = d
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
    }
    
    func reportComment(commentId: UUID, reason: String, details: String? = nil) async throws {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para reportar"])
        }
        
        let path = "/rest/v1/social_reports"
        var bodyJson: [String: Any] = [
            "reporter_id": user.id.uuidString.lowercased(),
            "comment_id": commentId.uuidString.lowercased(),
            "reason": reason
        ]
        
        if let d = details, !d.isEmpty {
            bodyJson["details"] = d
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
    }
    
    // MARK: - Chats API
    
    func fetchChatRooms() async throws -> [ChatRoom] {
        guard let user = currentUser else { return [] }
        
        let path = "/rest/v1/chat_room_members"
        let queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(user.id.uuidString.lowercased())"),
            URLQueryItem(name: "select", value: "room_id,chat_rooms(*)")
        ]
        
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        
        let memberships = try JSONDecoder().decode([ChatRoomMemberWithRoom].self, from: data)
        return memberships.compactMap { $0.chat_rooms }
    }
    
    func fetchRoomMembers(roomId: UUID) async throws -> [ChatRoomMember] {
        let path = "/rest/v1/chat_room_members"
        let queryItems = [
            URLQueryItem(name: "room_id", value: "eq.\(roomId.uuidString.lowercased())")
        ]
        
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        
        return try JSONDecoder().decode([ChatRoomMember].self, from: data)
    }
    
    func createGroupChat(name: String) async throws -> ChatRoom {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para crear grupos"])
        }
        
        // 1. Crear sala de chat
        let path = "/rest/v1/chat_rooms"
        let roomBody: [String: Any] = [
            "name": name,
            "is_group": true,
            "created_by": user.id.uuidString.lowercased()
        ]
        let roomBodyData = try JSONSerialization.data(withJSONObject: roomBody)
        let createRoomRequest = makeRequest(path: path, method: "POST", body: roomBodyData)
        let (roomData, roomRes) = try await URLSession.shared.data(for: createRoomRequest)
        try verifyResponse(data: roomData, response: roomRes)
        
        let createdRooms = try JSONDecoder().decode([ChatRoom].self, from: roomData)
        guard let newRoom = createdRooms.first else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al crear grupo"])
        }
        
        // 2. Agregar al creador como miembro
        let myName = user.user_metadata?.full_name ?? user.user_metadata?.name ?? user.email?.components(separatedBy: "@").first ?? "Usuario"
        let myAvatar = user.user_metadata?.avatar_url ?? user.user_metadata?.picture
        
        let membersPath = "/rest/v1/chat_room_members"
        let memberBody: [String: Any] = [
            "room_id": newRoom.id.uuidString.lowercased(),
            "user_id": user.id.uuidString.lowercased(),
            "user_name": myName,
            "user_avatar": myAvatar as Any
        ]
        let memberBodyData = try JSONSerialization.data(withJSONObject: memberBody)
        let addMemberRequest = makeRequest(path: membersPath, method: "POST", body: memberBodyData)
        let (addMemberData, addRes) = try await URLSession.shared.data(for: addMemberRequest)
        try verifyResponse(data: addMemberData, response: addRes)
        
        return newRoom
    }
    
    func fetchMessages(roomId: UUID) async throws -> [ChatMessage] {
        let path = "/rest/v1/chat_messages"
        let queryItems = [
            URLQueryItem(name: "room_id", value: "eq.\(roomId.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "created_at.asc")
        ]
        
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        
        return try JSONDecoder().decode([ChatMessage].self, from: data)
    }
    
    func sendMessage(roomId: UUID, content: String) async throws -> ChatMessage {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para enviar mensajes"])
        }
        
        let path = "/rest/v1/chat_messages"
        let authorName = user.user_metadata?.full_name ?? user.user_metadata?.name ?? user.email?.components(separatedBy: "@").first ?? "Usuario"
        let authorAvatar = user.user_metadata?.avatar_url ?? user.user_metadata?.picture
        
        var bodyJson: [String: Any] = [
            "room_id": roomId.uuidString.lowercased(),
            "user_id": user.id.uuidString.lowercased(),
            "author_name": authorName,
            "content": content
        ]
        
        if let avatar = authorAvatar {
            bodyJson["author_avatar"] = avatar
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        
        let messages = try JSONDecoder().decode([ChatMessage].self, from: data)
        guard let newMessage = messages.first else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al enviar mensaje"])
        }
        return newMessage
    }
    
    func getOrCreateDirectChat(with targetUserId: UUID, targetUserName: String, targetUserAvatar: String?) async throws -> ChatRoom {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión para chatear"])
        }
        
        // 1. Obtener salas directas del usuario actual
        let myRoomsPath = "/rest/v1/chat_room_members"
        let myRoomsQuery = [
            URLQueryItem(name: "user_id", value: "eq.\(user.id.uuidString.lowercased())"),
            URLQueryItem(name: "select", value: "room_id,chat_rooms(*)")
        ]
        let myRequest = makeRequest(path: myRoomsPath, queryItems: myRoomsQuery)
        let (myData, myRes) = try await URLSession.shared.data(for: myRequest)
        try verifyResponse(data: myData, response: myRes)
        
        let myMemberships = try JSONDecoder().decode([ChatRoomMemberWithRoom].self, from: myData)
        // Filtrar solo las salas directas (no grupales)
        let myDirectRoomIds = myMemberships
            .filter { $0.chat_rooms?.is_group == false }
            .map { $0.room_id }
            
        // 2. Si hay salas directas, ver si el destinatario está en alguna de ellas
        if !myDirectRoomIds.isEmpty {
            let matchPath = "/rest/v1/chat_room_members"
            let roomFilter = "in.(\(myDirectRoomIds.map { $0.uuidString.lowercased() }.joined(separator: ",")))"
            let matchQuery = [
                URLQueryItem(name: "room_id", value: roomFilter),
                URLQueryItem(name: "user_id", value: "eq.\(targetUserId.uuidString.lowercased())"),
                URLQueryItem(name: "select", value: "room_id")
            ]
            let matchRequest = makeRequest(path: matchPath, queryItems: matchQuery)
            let (matchData, matchRes) = try await URLSession.shared.data(for: matchRequest)
            try verifyResponse(data: matchData, response: matchRes)
            
            struct SimpleMember: Codable {
                let room_id: UUID
            }
            
            let matchingMemberships = try JSONDecoder().decode([SimpleMember].self, from: matchData)
            if let matchingRoomId = matchingMemberships.first?.room_id {
                // Encontramos una sala existente, obtener sus detalles
                if let matchedRoom = myMemberships.first(where: { $0.room_id == matchingRoomId })?.chat_rooms {
                    return matchedRoom
                }
            }
        }
        
        // 3. Si no existe, crear una nueva sala directa
        let createPath = "/rest/v1/chat_rooms"
        let roomBody: [String: Any] = [
            "is_group": false,
            "created_by": user.id.uuidString.lowercased()
        ]
        let roomBodyData = try JSONSerialization.data(withJSONObject: roomBody)
        let createRoomRequest = makeRequest(path: createPath, method: "POST", body: roomBodyData)
        let (roomData, roomRes) = try await URLSession.shared.data(for: createRoomRequest)
        try verifyResponse(data: roomData, response: roomRes)
        
        let createdRooms = try JSONDecoder().decode([ChatRoom].self, from: roomData)
        guard let newRoom = createdRooms.first else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al crear sala de chat"])
        }
        
        // 4. Agregar a ambos miembros
        let myName = user.user_metadata?.full_name ?? user.user_metadata?.name ?? user.email?.components(separatedBy: "@").first ?? "Usuario"
        let myAvatar = user.user_metadata?.avatar_url ?? user.user_metadata?.picture
        
        let membersPath = "/rest/v1/chat_room_members"
        let membersBody: [[String: Any]] = [
            [
                "room_id": newRoom.id.uuidString.lowercased(),
                "user_id": user.id.uuidString.lowercased(),
                "user_name": myName,
                "user_avatar": myAvatar as Any
            ],
            [
                "room_id": newRoom.id.uuidString.lowercased(),
                "user_id": targetUserId.uuidString.lowercased(),
                "user_name": targetUserName,
                "user_avatar": targetUserAvatar as Any
            ]
        ]
        let membersBodyData = try JSONSerialization.data(withJSONObject: membersBody)
        let addMembersRequest = makeRequest(path: membersPath, method: "POST", body: membersBodyData)
        let (_, addRes) = try await URLSession.shared.data(for: addMembersRequest)
        
        guard let httpAddRes = addRes as? HTTPURLResponse, (200...299).contains(httpAddRes.statusCode) else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al agregar miembros al chat"])
        }
        
        return newRoom
    }
    
    func inviteUserToGroup(roomId: UUID, userId: UUID, userName: String, userAvatar: String?) async throws {
        let membersPath = "/rest/v1/chat_room_members"
        let memberBody: [String: Any] = [
            "room_id": roomId.uuidString.lowercased(),
            "user_id": userId.uuidString.lowercased(),
            "user_name": userName,
            "user_avatar": userAvatar as Any
        ]
        let memberBodyData = try JSONSerialization.data(withJSONObject: memberBody)
        let request = makeRequest(path: membersPath, method: "POST", body: memberBodyData)
        let (data, res) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: res)
    }
    
    func updateProfile(fullName: String, avatarUrl: String?, company: String?, role: String?) async throws {
        let path = "/auth/v1/user"
        var meta: [String: Any] = [
            "full_name": fullName,
            "name": fullName
        ]
        if let avatar = avatarUrl {
            meta["avatar_url"] = avatar
            meta["picture"] = avatar
        }
        if let comp = company {
            meta["company"] = comp
        }
        if let r = role {
            meta["role"] = r
        }
        
        let body: [String: Any] = ["data": meta]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let request = makeRequest(path: path, method: "PUT", body: bodyData)
        let (data, res) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: res)
        
        // Reload user info
        let updatedUser = try JSONDecoder().decode(SupabaseUser.self, from: data)
        await MainActor.run {
            self.currentUser = updatedUser
            if let encoded = try? JSONEncoder().encode(updatedUser) {
                UserDefaults.standard.set(encoded, forKey: "supabase_current_user")
            }
        }
    }
    
    func findUserByName(name: String) async throws -> (id: UUID, avatar: String?)? {
        let path = "/rest/v1/chat_room_members"
        let queryItems = [
            URLQueryItem(name: "user_name", value: "ieq.\(name)"),
            URLQueryItem(name: "select", value: "user_id,user_avatar"),
            URLQueryItem(name: "limit", value: "1")
        ]
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, res) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: res)
        
        struct SimpleUser: Codable {
            let user_id: UUID
            let user_avatar: String?
        }
        let users = try JSONDecoder().decode([SimpleUser].self, from: data)
        if let user = users.first {
            return (user.user_id, user.user_avatar)
        }
        return nil
    }
}

// MARK: - Presentation Anchor Provider Helper
class PresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationAnchorProvider()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(macOS)
        return NSApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? NSWindow()
        #else
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return ASPresentationAnchor()
        }
        return window
        #endif
    }
}
