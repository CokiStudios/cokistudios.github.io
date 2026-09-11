import Foundation
internal import Combine

public class CSIDManager: ObservableObject {
    public static let shared = CSIDManager()

    private let baseUrl = "https://cmkumxprmmhuinxfppxl.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"

    @Published public var currentUser: CSIDUser? = nil
    @Published public var sessionToken: String? = nil

    public var isLoggedIn: Bool {
        currentUser != nil && sessionToken != nil
    }

    public var deviceHash: String {
        if let existing = UserDefaults.standard.string(forKey: "csid_device_hash") {
            return existing
        }
        let newHash = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        UserDefaults.standard.set(newHash, forKey: "csid_device_hash")
        return newHash
    }

    private init() {
        self.sessionToken = UserDefaults.standard.string(forKey: "csid_session_token")
        if let savedId = UserDefaults.standard.string(forKey: "csid_user_id"),
           let savedEmail = UserDefaults.standard.string(forKey: "csid_user_email") {
            let savedName = UserDefaults.standard.string(forKey: "csid_user_name") ?? savedEmail.components(separatedBy: "@").first ?? "Usuario"
            self.currentUser = CSIDUser(id: savedId, email: savedEmail, name: savedName)
        }
    }

    // MARK: - Login
    public func login(email: String, pass: String) async throws -> CSIDUser {
        let url = URL(string: "\(baseUrl)/auth/v1/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": pass
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                errorMsg = (json["error_description"] as? String) ?? (json["msg"] as? String) ?? "Error al autenticar con CS ID"
            } else {
                errorMsg = "Error al autenticar (\(httpResponse.statusCode))"
            }
            throw NSError(domain: "CSIDManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String,
              let userObj = json["user"] as? [String: Any],
              let userId = userObj["id"] as? String else {
            throw URLError(.cannotParseResponse)
        }

        let userEmail = (userObj["email"] as? String) ?? email
        var userName = userEmail.components(separatedBy: "@").first ?? "Usuario"

        if let metadata = userObj["user_metadata"] as? [String: Any] {
            if let fullName = metadata["full_name"] as? String, !fullName.isEmpty {
                userName = fullName
            } else if let name = metadata["name"] as? String, !name.isEmpty {
                userName = name
            }
        }

        let user = CSIDUser(id: userId, email: userEmail, name: userName)

        await MainActor.run {
            self.sessionToken = token
            self.currentUser = user
            UserDefaults.standard.set(token, forKey: "csid_session_token")
            UserDefaults.standard.set(userId, forKey: "csid_user_id")
            UserDefaults.standard.set(userEmail, forKey: "csid_user_email")
            UserDefaults.standard.set(userName, forKey: "csid_user_name")
        }

        Task.detached {
            await self.bindDeviceHash(userId: userId, email: userEmail)
        }

        return user
    }

    // MARK: - Sign Up
    public func signUp(email: String, pass: String, name: String) async throws -> CSIDUser {
        let url = URL(string: "\(baseUrl)/auth/v1/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = [
            "full_name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "role": "user",
            "company": "Coki Studios"
        ]

        let body: [String: Any] = [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": pass,
            "options": [
                "data": metadata,
                "email_redirect_to": "https://cokistudios.github.io/coki-confirm.html"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                errorMsg = (json["msg"] as? String) ?? (json["message"] as? String) ?? "Error al registrar cuenta CS ID"
            } else {
                errorMsg = "Error al registrar (\(httpResponse.statusCode))"
            }
            throw NSError(domain: "CSIDManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        // Auto login after successful signup
        return try await login(email: email, pass: pass)
    }

    // MARK: - Logout
    public func logout() {
        self.sessionToken = nil
        self.currentUser = nil
        UserDefaults.standard.removeObject(forKey: "csid_session_token")
        UserDefaults.standard.removeObject(forKey: "csid_user_id")
        UserDefaults.standard.removeObject(forKey: "csid_user_email")
        UserDefaults.standard.removeObject(forKey: "csid_user_name")
    }

    // MARK: - Device Hash Sync
    private func bindDeviceHash(userId: String, email: String) async {
        guard let url = URL(string: "\(baseUrl)/rest/v1/user_device_hashes") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "device_hash": deviceHash,
            "user_id": userId.lowercased(),
            "user_email": email
        ]

        if let data = try? JSONSerialization.data(withJSONObject: body) {
            request.httpBody = data
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
