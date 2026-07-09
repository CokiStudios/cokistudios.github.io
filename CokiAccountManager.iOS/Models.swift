import Foundation
import SwiftUI

// MARK: - OAuth Client Info
struct OAuthClient: Codable, Identifiable, Hashable {
    var id: String { client_id }
    let client_id: String
    let client_name: String?
    let logo_url: String?
    let website_url: String?
}

// MARK: - Connected App
struct ConnectedApp: Codable, Identifiable, Hashable {
    let id: UUID
    let client_id: String
    let scopes: [String]?
    let granted_at: String
    let last_used_at: String?
    
    // Nested relationship mapped in Swift
    let oauth_clients: OAuthClient?
    
    // Formatting Helpers
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: granted_at) ?? ISO8601DateFormatter().date(from: granted_at) else {
            return "hace poco"
        }
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "es-ES")
        outputFormatter.dateStyle = .medium
        return outputFormatter.string(from: date)
    }
    
    var appName: String {
        oauth_clients?.client_name ?? "App Externa"
    }
    
    var appIconLetter: String {
        appName.prefix(1).uppercased()
    }
    
    var scopesString: String {
        scopes?.joined(separator: ", ") ?? "Perfil"
    }
}

// MARK: - User Info
struct CokiUser: Codable, Identifiable, Hashable {
    let id: UUID
    let email: String?
    let user_metadata: UserMetadata?
    
    struct UserMetadata: Codable, Hashable {
        let full_name: String?
        let name: String?
        let company: String?
        let role: String?
        let avatar_url: String?
        let picture: String?
    }
    
    var displayName: String {
        user_metadata?.full_name ?? user_metadata?.name ?? email?.components(separatedBy: "@").first ?? "Usuario"
    }
    
    var initials: String {
        displayName.prefix(1).uppercased()
    }
}

// MARK: - Auth Response Structs
struct SupabaseAuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String
    let user: CokiUser
}

// MARK: - Color Hex Extension
extension Color {
    init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHex = cleanHex.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: cleanHex).scanHexInt64(&rgb) else { return nil }
        
        let r, g, b: Double
        if cleanHex.count == 6 {
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
            self.init(red: r, green: g, blue: b)
        } else if cleanHex.count == 8 {
            r = Double((rgb >> 24) & 0xFF) / 255.0
            g = Double((rgb >> 16) & 0xFF) / 255.0
            b = Double((rgb >> 8) & 0xFF) / 255.0
            let a = Double(rgb & 0xFF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
        } else {
            return nil
        }
    }
    
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return UIColor(light)
            } else {
                return UIColor(dark)
            }
        })
    }
}
