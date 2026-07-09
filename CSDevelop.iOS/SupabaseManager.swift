import Foundation
import SwiftUI
internal import Combine

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"
    
    @Published var currentUser: CokiUser? = nil {
        didSet {
            if let user = currentUser {
                if let data = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(data, forKey: "csdev_current_user")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "csdev_current_user")
            }
        }
    }
    
    @Published var sessionToken: String? = nil {
        didSet {
            if let token = sessionToken {
                UserDefaults.standard.set(token, forKey: "csdev_session_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "csdev_session_token")
            }
        }
    }
    
    var isLoggedIn: Bool {
        sessionToken != nil
    }
    
    private init() {
        self.sessionToken = UserDefaults.standard.string(forKey: "csdev_session_token")
        if let data = UserDefaults.standard.data(forKey: "csdev_current_user") {
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
        try verifyResponse(data: data, response: response)
        
        let authResponse = try JSONDecoder().decode(SupabaseAuthResponse.self, from: data)
        
        await MainActor.run {
            self.sessionToken = authResponse.access_token
            self.currentUser = authResponse.user
        }
    }
    
    func register(email: String, password: String, metadata: [String: String] = [:]) async throws {
        let path = "/auth/v1/signup"
        let bodyJson = [
            "email": email,
            "password": password,
            "data": metadata
        ] as [String : Any]
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
            UserDefaults.standard.removeObject(forKey: "csdev_session_token")
            UserDefaults.standard.removeObject(forKey: "csdev_current_user")
        }
    }
    
    // MARK: - Developer Apps CRUD API
    func fetchApps() async throws -> [DeveloperApp] {
        guard let user = currentUser else { return [] }
        
        let path = "/rest/v1/oauth_clients"
        let queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "developer_id", value: "eq.\(user.id.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        
        let request = makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
        
        return try JSONDecoder().decode([DeveloperApp].self, from: data)
    }
    
    func createApp(name: String, website: String?, redirectUris: [String], logoUrl: String?) async throws {
        guard let user = currentUser else { throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session lost"]) }
        
        let clientId = "coki_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(24)
        
        let path = "/rest/v1/oauth_clients"
        let bodyJson: [String: Any] = [
            "client_id": clientId,
            "client_name": name,
            "redirect_uris": redirectUris,
            "allowed_scopes": ["openid", "profile", "email"],
            "website_url": website ?? NSNull(),
            "logo_url": logoUrl ?? NSNull(),
            "is_active": true,
            "developer_id": user.id.uuidString.lowercased()
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
    }
    
    func updateApp(clientId: String, name: String, website: String?, redirectUris: [String], logoUrl: String?) async throws {
        guard let user = currentUser else { throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session lost"]) }
        
        let path = "/rest/v1/oauth_clients"
        let queryItems = [
            URLQueryItem(name: "client_id", value: "eq.\(clientId)"),
            URLQueryItem(name: "developer_id", value: "eq.\(user.id.uuidString.lowercased())")
        ]
        
        let bodyJson: [String: Any] = [
            "client_name": name,
            "redirect_uris": redirectUris,
            "website_url": website ?? NSNull(),
            "logo_url": logoUrl ?? NSNull(),
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        let request = makeRequest(path: path, method: "PATCH", body: bodyData, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
    }
    
    func toggleActive(clientId: String, isActive: Bool) async throws {
        guard let user = currentUser else { throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session lost"]) }
        
        let path = "/rest/v1/oauth_clients"
        let queryItems = [
            URLQueryItem(name: "client_id", value: "eq.\(clientId)"),
            URLQueryItem(name: "developer_id", value: "eq.\(user.id.uuidString.lowercased())")
        ]
        
        let bodyJson = ["is_active": !isActive]
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        let request = makeRequest(path: path, method: "PATCH", body: bodyData, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
    }
    
    func deleteApp(clientId: String) async throws {
        guard let user = currentUser else { throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session lost"]) }
        
        let path = "/rest/v1/oauth_clients"
        let queryItems = [
            URLQueryItem(name: "client_id", value: "eq.\(clientId)"),
            URLQueryItem(name: "developer_id", value: "eq.\(user.id.uuidString.lowercased())")
        ]
        
        let request = makeRequest(path: path, method: "DELETE", queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(data: data, response: response)
    }
}
