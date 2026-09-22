import Foundation
import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 📦 DATA MODELS — FORKAR FOR PC & CSMS EXTENSION
// Mapeo 1:1 con las tablas reales de Supabase:
// social_posts, social_categories, social_comments, social_likes,
// chat_rooms, chat_messages, forkman_user_eco
// ══════════════════════════════════════════════════════════════════

// ─── 1. CATEGORÍAS (social_categories) ───
struct Category: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let slug: String
    let color: String
    let description: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, color, description
        case createdAt = "created_at"
    }
}

// ─── 2. PUBLICACIONES (social_posts) ───
struct Post: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let authorName: String
    let authorAvatar: String?
    let categoryId: String?
    let title: String
    let content: String
    let likesCount: Int
    let commentsCount: Int
    let imageUrl: String?
    let videoUrl: String?
    let createdAt: String
    let updatedAt: String?
    let category: Category?
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, category
        case userId = "user_id"
        case authorName = "author_name"
        case authorAvatar = "author_avatar"
        case categoryId = "category_id"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case imageUrl = "image_url"
        case videoUrl = "video_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) ?? ISO8601DateFormatter().date(from: createdAt) else {
            return "reciente"
        }
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .short
        return relative.localizedString(for: date, relativeTo: Date())
    }
}

// ─── 3. COMENTARIOS (social_comments) ───
struct PostComment: Identifiable, Codable, Hashable {
    let id: String
    let postId: String
    let userId: String
    let authorName: String
    let authorAvatar: String?
    let content: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case postId = "post_id"
        case userId = "user_id"
        case authorName = "author_name"
        case authorAvatar = "author_avatar"
        case createdAt = "created_at"
    }
    
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) ?? ISO8601DateFormatter().date(from: createdAt) else {
            return "reciente"
        }
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .short
        return relative.localizedString(for: date, relativeTo: Date())
    }
}

// ─── 4. EXTENSIÓN CSMS — SALAS DE CHAT (chat_rooms) ───
struct CSMSChatRoom: Identifiable, Codable, Hashable {
    let id: String
    let name: String?
    let isGroup: Bool
    let createdBy: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case isGroup = "is_group"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    var displayName: String {
        name ?? "Chat Privado"
    }
}

// ─── 5. EXTENSIÓN CSMS — MENSAJES (chat_messages) ───
struct CSMSMessage: Identifiable, Codable, Hashable {
    let id: String
    let roomId: String
    let userId: String
    let authorName: String
    let authorAvatar: String?
    let content: String
    let mediaUrl: String?
    let mediaType: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case roomId = "room_id"
        case userId = "user_id"
        case authorName = "author_name"
        case authorAvatar = "author_avatar"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case createdAt = "created_at"
    }
    
    var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) ?? ISO8601DateFormatter().date(from: createdAt) else {
            return "reciente"
        }
        let tf = DateFormatter()
        tf.dateStyle = .none
        tf.timeStyle = .short
        return tf.string(from: date)
    }
}

// ─── 6. ECO HUB (forkman_user_eco) ───
struct UserEcoRecord: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let co2Saved: Double
    let pointsEarned: Int
    let actionId: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case co2Saved = "co2_saved"
        case pointsEarned = "points_earned"
        case actionId = "action_id"
        case createdAt = "created_at"
    }
}

// ─── 7. ESTACIONES ECO REALES (Cota • Chía • Bogotá) ───
struct EcoStation: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let type: String
    let municipality: String
    let status: String
    let distance: String
    let iconName: String
}

// ─── 8. PERFIL DE USUARIO ───
struct UserProfile: Codable, Hashable {
    let id: String
    let email: String?
    let fullName: String?
    let avatarUrl: String?
    let bio: String?
    let followersCount: Int?
    let followingCount: Int?
}
