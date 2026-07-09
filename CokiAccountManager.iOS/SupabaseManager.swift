import Foundation
import Combine
import AuthenticationServices
import UIKit

// MARK: - Supabase Manager
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"
    
    @Published var currentUser: CokiUser? = nil {
        didSet {
            if let user = currentUser {
                if let data = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(data, forKey: "coki_current_user")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "coki_current_user")
            }
        }
    }
    @Published var sessionToken: String? = nil {
        didSet {
            if let token = sessionToken {
                UserDefaults.standard.set(token, forKey: "coki_session_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "coki_session_token")
            }
        }
    }
    
    var isLoggedIn: Bool {
        sessionToken != nil
    }
    
    private init() {
        // Restore session
        self.sessionToken = UserDefaults.standard.string(forKey: "coki_session_token")
        if let data = UserDefaults.standard.data(forKey: "coki_current_user") {
            self.currentUser = try? JSONDecoder().decode(CokiUser.self, from: data)
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
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Response invalid"])
        }
        
        if httpResponse.statusCode != 200 {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let desc = errorObj["error_description"] as? String {
                throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: desc])
            }
            throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Login failed"])
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
            throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Registration failed"])
        }
        
        try await login(email: email, password: password)
    }
    
    func logout() {
        DispatchQueue.main.async {
            self.currentUser = nil
            self.sessionToken = nil
            UserDefaults.standard.removeObject(forKey: "coki_session_token")
            UserDefaults.standard.removeObject(forKey: "coki_current_user")
        }
    }
    
    // MARK: - Profile Update API
    func updateProfile(name: String, company: String) async throws {
        guard sessionToken != nil else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión primero"])
        }
        
        let path = "/auth/v1/user"
        let bodyJson: [String: Any] = [
            "data": [
                "full_name": name,
                "name": name,
                "company": company
            ]
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        
        let request = makeRequest(path: path, method: "PUT", body: bodyData)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al actualizar perfil"])
        }
        
        let user = try JSONDecoder().decode(CokiUser.self, from: data)
        await MainActor.run {
            self.currentUser = user
            if let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: "coki_current_user")
            }
        }
    }
    
    // MARK: - Connected Apps API
    func fetchConnectedApps() async throws -> [ConnectedApp] {
        guard let user = currentUser else { return [] }
        
        let appsPath = "/rest/v1/user_apps"
        let appsQuery = [
            URLQueryItem(name: "select", value: "id,scopes,granted_at,last_used_at,client_id"),
            URLQueryItem(name: "user_id", value: "eq.\(user.id.uuidString.lowercased())"),
            URLQueryItem(name: "is_active", value: "eq.true")
        ]
        
        let appsRequest = makeRequest(path: appsPath, queryItems: appsQuery)
        let (appsData, response) = try await URLSession.shared.data(for: appsRequest)
        try verifyResponse(data: appsData, response: response)
        
        // Decode temp client representations
        struct TempApp: Codable {
            let id: UUID
            let client_id: String
            let scopes: [String]?
            let granted_at: String
            let last_used_at: String?
        }
        
        let tempApps = try JSONDecoder().decode([TempApp].self, from: appsData)
        if tempApps.isEmpty { return [] }
        
        // Fetch clients details
        let clientIds = tempApps.map { $0.client_id }
        let clientIdsJoined = clientIds.map { "\"\($0)\"" }.joined(separator: ",")
        
        let clientsPath = "/rest/v1/oauth_clients"
        let clientsQuery = [
            URLQueryItem(name: "select", value: "client_name,logo_url,website_url,client_id"),
            URLQueryItem(name: "client_id", value: "in.(\(clientIdsJoined))")
        ]
        
        let clientsRequest = makeRequest(path: clientsPath, queryItems: clientsQuery)
        let (clientsData, clientsResponse) = try await URLSession.shared.data(for: clientsRequest)
        try verifyResponse(data: clientsData, response: clientsResponse)
        let clients = try JSONDecoder().decode([OAuthClient].self, from: clientsData)
        
        return tempApps.map { app in
            let clientInfo = clients.first(where: { $0.client_id == app.client_id })
            return ConnectedApp(
                id: app.id,
                client_id: app.client_id,
                scopes: app.scopes,
                granted_at: app.granted_at,
                last_used_at: app.last_used_at,
                oauth_clients: clientInfo
            )
        }
    }
    
    func revokeConnectedApp(clientId: String) async throws {
        let path = "/rest/v1/rpc/revoke_app"
        let bodyJson = ["p_client_id": clientId]
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
    }
    
    // MARK: - OAuth Authentication API
    @MainActor
    func signInWithOAuth(provider: String) async throws {
        // Redirect to a Whitelisted custom scheme target. Make sure coki://oauth is whitelisted in Supabase Dashboard.
        let authURL = URL(string: "\(baseURL)/auth/v1/authorize?provider=\(provider)&redirect_to=coki://oauth")!
        let callbackScheme = "coki"
        
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
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Callback URL format invalid"])
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
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Access token missing"])
        }
        
        try await loginWithToken(accessToken: accessToken)
    }
    
    func loginWithToken(accessToken: String) async throws {
        let path = "/auth/v1/user"
        var request = makeRequest(path: path, method: "GET")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al obtener perfil"])
        }
        
        let user = try JSONDecoder().decode(CokiUser.self, from: data)
        await MainActor.run {
            self.currentUser = user
            self.sessionToken = accessToken
        }
    }
}

// MARK: - Presentation Anchor Provider Helper
class PresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationAnchorProvider()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return ASPresentationAnchor()
        }
        return window
    }
}
