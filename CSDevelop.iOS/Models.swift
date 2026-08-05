import Foundation
import SwiftUI

// MARK: - Developer App Model
struct DeveloperApp: Codable, Identifiable, Hashable {
    var id: String { client_id }
    let client_id: String
    var client_name: String
    var website_url: String?
    var logo_url: String?
    var redirect_uris: [String]
    var is_active: Bool
    let developer_id: UUID
    var allowed_scopes: [String]?
    
    var appIconLetter: String {
        client_name.prefix(1).uppercased()
    }
    
    var urisString: String {
        redirect_uris.joined(separator: ", ")
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
        user_metadata?.full_name ?? user_metadata?.name ?? email?.components(separatedBy: "@").first ?? "Desarrollador"
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

// MARK: - Color Hex & Dynamic Support
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
