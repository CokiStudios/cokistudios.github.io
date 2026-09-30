//
//  SupabaseManager.swift
//  CSIMS.iOS
//
//  Dedicated Supabase client for CSIMS (Coki Studios Internal Messaging Service).
//  Enforces Zero Trust @cokistudios.com domain requirement for internal channels.
//

import Foundation
import Combine

public struct CSIMSUser: Codable, Identifiable {
    public let id: UUID
    public let email: String?
    public let user_metadata: CSIMSUserMetadata?
    
    public var isCokiStudiosStaff: Bool {
        CSIMSEncryption.isAuthorizedInternalEmail(email)
    }
}

public struct CSIMSUserMetadata: Codable {
    public let full_name: String?
    public let name: String?
    public let avatar_url: String?
}

public struct CSIMSChatRoom: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let is_group: Bool?
    public let created_by: String?
    public let created_at: String?
}

public struct CSIMSMessage: Codable, Identifiable {
    public let id: String
    public let room_id: String
    public let user_id: String
    public let author_name: String
    public let author_avatar: String?
    public var content: String
    public let created_at: String?
    public var isEncrypted: Bool = false
}

public final class SupabaseManager: ObservableObject {
    public static let shared = SupabaseManager()
    
    private let supabaseUrl = "https://wveoxmsqvylyeuvtmnuk.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2ZW94bXNxdnlseWV1dnRtbnVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMwMzE1MjcsImV4cCI6MjA1ODYwNzUyN30.K9vD0H-y8aE_1uP8uE0j_pG2mC9yK6oR-xY6xR4vP7w"
    
    @Published public var currentUser: CSIMSUser? = nil
    @Published public var sessionToken: String? = nil
    @Published public var isLoggedIn: Bool = false
    
    private init() {
        loadSession()
    }
    
    private func saveSession(token: String, user: CSIMSUser) {
        self.sessionToken = token
        self.currentUser = user
        self.isLoggedIn = true
        UserDefaults.standard.set(token, forKey: "csims_session_token")
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "csims_user_data")
        }
    }
    
    private func loadSession() {
        if let token = UserDefaults.standard.string(forKey: "csims_session_token"),
           let data = UserDefaults.standard.data(forKey: "csims_user_data"),
           let user = try? JSONDecoder().decode(CSIMSUser.self, from: data) {
            self.sessionToken = token
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
    
    public func logout() {
        self.sessionToken = nil
        self.currentUser = nil
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: "csims_session_token")
        UserDefaults.standard.removeObject(forKey: "csims_user_data")
    }
    
    public func login(email: String, pass: String) async throws {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Zero Trust Validation
        guard CSIMSEncryption.isAuthorizedInternalEmail(cleanEmail) else {
            throw NSError(
                domain: "CSIMSZeroTrust",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Acceso Denegado: Solo el personal con correo @cokistudios.com puede acceder a CSIMS."]
            )
        }
        
        let url = URL(string: "\(supabaseUrl)/auth/v1/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        let body = ["email": cleanEmail, "password": pass]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            throw NSError(domain: "CSIMSAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Credenciales de Coki Studios incorrectas"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let token = json?["access_token"] as? String,
              let userDict = json?["user"] as? [String: Any],
              let userData = try? JSONSerialization.data(withJSONObject: userDict),
              let user = try? JSONDecoder().decode(CSIMSUser.self, from: userData) else {
            throw NSError(domain: "CSIMSAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta de autenticación inválida"])
        }
        
        await MainActor.run {
            self.saveSession(token: token, user: user)
        }
    }
    
    public func fetchInternalChannels() async throws -> [CSIMSChatRoom] {
        // Retornar salas canónicas internas de CSIMS
        return [
            CSIMSChatRoom(id: "10000000-0000-0000-0000-000000000001", name: "general-coki", is_group: true, created_by: "system", created_at: nil),
            CSIMSChatRoom(id: "10000000-0000-0000-0000-000000000002", name: "eng-forkar", is_group: true, created_by: "system", created_at: nil),
            CSIMSChatRoom(id: "10000000-0000-0000-0000-000000000003", name: "security-ops", is_group: true, created_by: "system", created_at: nil),
            CSIMSChatRoom(id: "10000000-0000-0000-0000-000000000004", name: "design-system", is_group: true, created_by: "system", created_at: nil)
        ]
    }
    
    public func fetchMessages(roomId: String) async throws -> [CSIMSMessage] {
        let cleanId = roomId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let url = URL(string: "\(supabaseUrl)/rest/v1/chat_messages?room_id=eq.\(cleanId)&order=created_at.asc")!
        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let token = sessionToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            return []
        }
        
        var messages = try JSONDecoder().decode([CSIMSMessage].self, from: data)
        for i in 0..<messages.count {
            let decrypted = CSIMSEncryption.shared.decrypt(payload: messages[i].content, roomIdString: cleanId)
            messages[i].content = decrypted.text
            messages[i].isEncrypted = decrypted.isEncrypted
        }
        return messages
    }
    
    public func sendMessage(roomId: String, content: String) async throws -> CSIMSMessage {
        guard let user = currentUser else {
            throw NSError(domain: "CSIMS", code: 401, userInfo: [NSLocalizedDescriptionKey: "Inicia sesión con correo @cokistudios.com"])
        }
        
        let cleanId = roomId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let encryptedPayload = try CSIMSEncryption.shared.encrypt(
            plainText: content,
            roomId: UUID(uuidString: cleanId) ?? UUID(),
            authorEmail: user.email
        )
        
        let url = URL(string: "\(supabaseUrl)/rest/v1/chat_messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        if let token = sessionToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let authorName = user.user_metadata?.full_name ?? user.user_metadata?.name ?? user.email?.components(separatedBy: "@").first ?? "Staff"
        let body: [String: Any] = [
            "room_id": cleanId,
            "user_id": user.id.uuidString.lowercased(),
            "author_name": authorName,
            "content": encryptedPayload
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            throw NSError(domain: "CSIMS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al enviar mensaje"])
        }
        
        let created = try JSONDecoder().decode([CSIMSMessage].self, from: data)
        guard var newMsg = created.first else {
            throw NSError(domain: "CSIMS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mensaje no creado"])
        }
        
        newMsg.content = content
        newMsg.isEncrypted = true
        return newMsg
    }
}
