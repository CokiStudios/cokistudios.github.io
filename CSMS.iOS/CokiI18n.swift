import SwiftUI
import Foundation

// MARK: - Global Language Enum
enum CokiLanguage: String, CaseIterable, Identifiable {
    case es = "es"
    case en = "en"
    case fr = "fr"
    case pt = "pt"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .es: return "🇪🇸 Español"
        case .en: return "🇺🇸 English"
        case .fr: return "🇫🇷 Français"
        case .pt: return "🇧🇷 Português"
        }
    }
}

// MARK: - Native Localization Manager
class CokiI18n: ObservableObject {
    static let shared = CokiI18n()
    
    @Published var currentLang: CokiLanguage {
        didSet {
            UserDefaults.standard.set(currentLang.rawValue, forKey: "coki-lang")
        }
    }
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "coki-lang") ?? "es"
        self.currentLang = CokiLanguage(rawValue: saved) ?? .es
    }
    
    func t(_ key: String) -> String {
        switch currentLang {
        case .es:
            switch key {
            case "nav_chats": return "Conversaciones"
            case "nav_friends": return "Amigos"
            case "welcome_title": return "Bienvenido a CSMS"
            case "welcome_sub": return "Mensajería privada y sincronizada en tiempo real"
            case "login_btn": return "Iniciar Sesión"
            case "logout_btn": return "Cerrar Sesión"
            case "new_group": return "Nuevo Grupo"
            case "create": return "Crear"
            case "cancel": return "Cancelar"
            case "type_message": return "Escribe un mensaje..."
            case "select_chat": return "Selecciona un chat para comenzar"
            default: return key
            }
        case .en:
            switch key {
            case "nav_chats": return "Chats"
            case "nav_friends": return "Friends"
            case "welcome_title": return "Welcome to CSMS"
            case "welcome_sub": return "Private real-time synchronized messaging"
            case "login_btn": return "Sign In"
            case "logout_btn": return "Log Out"
            case "new_group": return "New Group"
            case "create": return "Create"
            case "cancel": return "Cancel"
            case "type_message": return "Type a message..."
            case "select_chat": return "Select a conversation to start"
            default: return key
            }
        case .fr:
            switch key {
            case "nav_chats": return "Discussions"
            case "nav_friends": return "Amis"
            case "welcome_title": return "Bienvenue sur CSMS"
            case "welcome_sub": return "Messagerie privée synchronisée en temps réel"
            case "login_btn": return "Connexion"
            case "logout_btn": return "Déconnexion"
            case "new_group": return "Nouveau Groupe"
            case "create": return "Créer"
            case "cancel": return "Annuler"
            case "type_message": return "Écrivez un message..."
            case "select_chat": return "Sélectionnez une discussion"
            default: return key
            }
        case .pt:
            switch key {
            case "nav_chats": return "Conversas"
            case "nav_friends": return "Amigos"
            case "welcome_title": return "Bem-vindo ao CSMS"
            case "welcome_sub": return "Mensagens privadas e sincronizadas em tempo real"
            case "login_btn": return "Entrar"
            case "logout_btn": return "Sair"
            case "new_group": return "Novo Grupo"
            case "create": return "Criar"
            case "cancel": return "Cancelar"
            case "type_message": return "Digite uma mensagem..."
            case "select_chat": return "Selecione uma conversa para começar"
            default: return key
            }
        }
    }
}
