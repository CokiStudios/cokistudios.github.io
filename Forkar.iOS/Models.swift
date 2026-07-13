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
        #if canImport(UIKit)
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return UIColor(light)
            } else {
                return UIColor(dark)
            }
        })
        #elseif canImport(AppKit)
        return Color(NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua {
                return NSColor(light)
            } else {
                return NSColor(dark)
            }
        })
        #else
        return light
        #endif
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

// MARK: - Localization Support

enum AppLanguage: String, CaseIterable, Identifiable {
    case spanish = "es"
    case english = "en"
    
    var id: String { self.rawValue }
    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    // Store in standard UserDefaults to persist language choice
    @AppStorage("app_language") var currentLanguage: AppLanguage = .spanish
    
    func translate(_ key: String) -> String {
        let translations: [AppLanguage: [String: String]] = [
            .spanish: [
                "chat_title": "Chats",
                "create_group": "Crear Grupo",
                "create_group_title": "Nuevo Grupo",
                "group_name": "Nombre del Grupo",
                "cancel": "Cancelar",
                "close": "Cerrar",
                "invite": "Invitar",
                "invited": "Invitado",
                "invite_title": "Invitar al Grupo",
                "no_users_to_invite": "No hay usuarios para invitar",
                "no_users_invite_desc": "Todos los usuarios activos ya son miembros de este grupo.",
                "send_message_placeholder": "Escribe un mensaje...",
                "no_messages": "No hay mensajes",
                "start_chat_desc": "¡Escribe el primer mensaje para iniciar la conversación!",
                "report_title": "Reportar contenido",
                "report_success": "Reporte Enviado",
                "report_success_desc": "Gracias por reportar. Revisaremos el contenido lo antes posible.",
                "dm_button": "Mensaje Privado",
                "welcome_title": "Bienvenido a Forkar",
                "welcome_subtitle": "Completa tu información para empezar a conectar con otros desarrolladores.",
                "full_name_label": "Nombre Completo",
                "full_name_placeholder": "Tu nombre visible",
                "avatar_url_label": "URL del Avatar (Opcional)",
                "avatar_url_placeholder": "https://enlace.a/tu/avatar.png",
                "role_title": "Rol Profesional",
                "role_subtitle": "Cuéntanos qué especialidad tienes para personalizar tu feed.",
                "role_label": "Tu Rol / Especialidad",
                "company_label": "Compañía / Escuela",
                "company_placeholder": "Dónde estudias o trabajas",
                "finish_title": "¡Todo Listo!",
                "finish_subtitle": "Tu perfil se configuró correctamente. Ya puedes usar Forkar.",
                "next_btn": "Siguiente",
                "back_btn": "Atrás",
                "finish_btn": "Terminar",
                "select_role": "Selecciona tu Rol"
            ],
            .english: [
                "chat_title": "Chats",
                "create_group": "Create Group",
                "create_group_title": "New Group",
                "group_name": "Group Name",
                "cancel": "Cancel",
                "close": "Close",
                "invite": "Invite",
                "invited": "Invited",
                "invite_title": "Invite to Group",
                "no_users_to_invite": "No users to invite",
                "no_users_invite_desc": "All active users are already members of this group.",
                "send_message_placeholder": "Type a message...",
                "no_messages": "No messages",
                "start_chat_desc": "Type the first message to start the conversation!",
                "report_title": "Report content",
                "report_success": "Report Sent",
                "report_success_desc": "Thank you for reporting. We will review the content as soon as possible.",
                "dm_button": "Direct Message",
                "welcome_title": "Welcome to Forkar",
                "welcome_subtitle": "Complete your profile info to start connecting with other developers.",
                "full_name_label": "Full Name",
                "full_name_placeholder": "Your visible name",
                "avatar_url_label": "Avatar URL (Optional)",
                "avatar_url_placeholder": "https://link.to/your/avatar.png",
                "role_title": "Professional Role",
                "role_subtitle": "Tell us about your specialty to personalize your feed.",
                "role_label": "Your Role / Specialty",
                "company_label": "Company / School",
                "company_placeholder": "Where you work or study",
                "finish_title": "All Set!",
                "finish_subtitle": "Your profile is set up successfully. Welcome to Forkar.",
                "next_btn": "Next",
                "back_btn": "Back",
                "finish_btn": "Finish",
                "select_role": "Select your Role"
            ]
        ]
        return translations[currentLanguage]?[key] ?? key
    }
}

extension String {
    var localized: String {
        LocalizationManager.shared.translate(self)
    }
}

// MARK: - Multiplatform Navigation Stack Helper
struct MultiplatformNavigationStack<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        #if os(macOS)
        if #available(macOS 13.0, *) {
            NavigationStack(root: content)
        } else {
            NavigationView(content: content)
        }
        #else
        NavigationView(content: content)
            .navigationViewStyle(StackNavigationViewStyle())
        #endif
    }
}
