import Foundation
import Combine

struct CSMSChatRoom: Codable, Identifiable {
    let id: UUID
    let name: String?
    let is_group: Bool?
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
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"
    
    private func makeRequest(path: String, method: String = "GET", body: Data? = null, queryItems: [URLQueryItem] = []) -> URLRequest {
        var components = URLComponents(string: "\(baseURL)\(path)")!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }
    
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
        let path = "/rest/v1/chat_rooms"
        let dict: [String: Any] = [
            "name": name,
            "is_group": true
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: dict)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, res) = try await URLSession.shared.data(for: request)
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
        let path = "/rest/v1/chat_messages"
        let dict: [String: Any] = [
            "room_id": roomId.uuidString,
            "sender_id": "my-user",
            "content": content
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: dict)
        let request = makeRequest(path: path, method: "POST", body: bodyData)
        let (data, res) = try await URLSession.shared.data(for: request)
        if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            return true
        }
        return false
    }
}
