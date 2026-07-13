import Foundation
import SwiftUI

// MARK: - Category Model
struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let slug: String
    let description: String?
    let color: String
    let created_at: String? // Store as string and parse when needed, or decoded directly
    
    // UI Helpers
    var themeColor: Color {
        Color(hex: color) ?? .indigo
    }
}

// MARK: - Post Model
struct Post: Identifiable, Codable, Hashable {
    let id: UUID
    let user_id: UUID
    let author_name: String
    let author_avatar: String?
    let category_id: UUID?
    let title: String
    let content: String
    let likes_count: Int
    let comments_count: Int
    let created_at: String // Decoded from ISO8601
    let updated_at: String?
    
    // Nested category from Supabase join
    let category: Category?
    
    // Formatting helper
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: created_at) ?? ISO8601DateFormatter().date(from: created_at) else {
            return "hace poco"
        }
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    var initials: String {
        author_name.prefix(1).uppercased()
    }
}

// MARK: - Comment Model
struct Comment: Identifiable, Codable, Hashable {
    let id: UUID
    let post_id: UUID
    let user_id: UUID
    let author_name: String
    let author_avatar: String?
    let content: String
    let created_at: String // Decoded from ISO8601
    
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: created_at) ?? ISO8601DateFormatter().date(from: created_at) else {
            return "hace poco"
        }
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    var initials: String {
        author_name.prefix(1).uppercased()
    }
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

// MARK: - Chat Models

struct ChatRoom: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String?
    let is_group: Bool
    let created_at: String
    let created_by: UUID
    
    var displayName: String {
        name ?? "Chat Privado"
    }
}

struct ChatRoomMember: Identifiable, Codable, Hashable {
    let id: UUID
    let room_id: UUID
    let user_id: UUID
    let user_name: String
    let user_avatar: String?
    let joined_at: String
    
    var initials: String {
        user_name.prefix(1).uppercased()
    }
}

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let room_id: UUID
    let user_id: UUID
    let author_name: String
    let author_avatar: String?
    let content: String
    let created_at: String
    
    var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: created_at) ?? ISO8601DateFormatter().date(from: created_at) else {
            return "hace poco"
        }
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: date)
    }
    
    var initials: String {
        author_name.prefix(1).uppercased()
    }
}

struct ChatRoomMemberWithRoom: Identifiable, Codable, Hashable {
    var id: UUID { room_id }
    let room_id: UUID
    let chat_rooms: ChatRoom?
}

struct CommunityUser: Identifiable, Hashable {
    let id: UUID
    let name: String
    let avatar: String?
}
