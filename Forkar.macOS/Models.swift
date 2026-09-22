import Foundation
import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 📦 DATA MODELS — FORKAR FOR PC (macOS & Desktop)
// ══════════════════════════════════════════════════════════════════

// ─── 1. PUBLICACIONES (POSTS) ───
struct Post: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let content: String
    let userId: String
    let authorName: String?
    let authorAvatar: String?
    let categoryId: String?
    let likesCount: Int
    let commentsCount: Int
    let imageUrl: String?
    let videoUrl: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, content
        case userId = "user_id"
        case authorName = "author_name"
        case authorAvatar = "author_avatar"
        case categoryId = "category_id"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case imageUrl = "image_url"
        case videoUrl = "video_url"
        case createdAt = "created_at"
    }
}

// ─── 2. CATEGORÍAS ───
struct Category: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let slug: String
    let color: String
    let icon: String
}

// ─── 3. COMENTARIOS ───
struct PostComment: Identifiable, Codable, Hashable {
    let id: String
    let postId: String
    let userId: String
    let content: String
    let authorName: String?
    let authorAvatar: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case postId = "post_id"
        case userId = "user_id"
        case authorName = "author_name"
        case authorAvatar = "author_avatar"
        case createdAt = "created_at"
    }
}

// ─── 4. EXTENSIÓN CSMS — SALAS DE CHAT ───
struct CSMSChatRoom: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let isGroup: Bool
    let lastMessage: String?
    let lastMessageAt: String?
    let unreadCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case isGroup = "is_group"
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case unreadCount = "unread_count"
    }
}

// ─── 5. EXTENSIÓN CSMS — MENSAJES ───
struct CSMSMessage: Identifiable, Codable, Hashable {
    let id: String
    let roomId: String
    let senderId: String
    let authorName: String?
    let authorAvatar: String?
    let content: String
    let mediaUrl: String?
    let mediaType: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case roomId = "room_id"
        case senderId = "sender_id"
        case authorName = "author_name"
        case authorAvatar = "author_avatar"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case createdAt = "created_at"
    }
}

// ─── 6. PERFIL DE USUARIO ───
struct UserProfile: Codable, Hashable {
    let id: String
    let email: String?
    let fullName: String?
    let avatarUrl: String?
    let bio: String?
    let followersCount: Int?
    let followingCount: Int?
}
