import SwiftUI
import Foundation

// MARK: - Forkar iOS Localization Manager
enum ForkarAppLanguage: String, CaseIterable, Identifiable {
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

class ForkarI18nIOS: ObservableObject {
    static let shared = ForkarI18nIOS()
    
    @Published var currentLang: ForkarAppLanguage {
        didSet {
            UserDefaults.standard.set(currentLang.rawValue, forKey: "coki-lang")
        }
    }
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "coki-lang") ?? "es"
        self.currentLang = ForkarAppLanguage(rawValue: saved) ?? .es
    }
    
    func t(_ key: String) -> String {
        switch currentLang {
        case .es:
            switch key {
            case "feed": return "Comunidad"
            case "new_post": return "Nueva Publicación"
            case "eco_hub": return "Forkar Eco Hub"
            case "co2_saved": return "CO₂ Ahorrado"
            case "eco_points": return "Puntos Eco"
            case "scan_qr": return "Escanear QR"
            case "my_qr": return "Mi Código QR"
            case "rewards": return "Tienda Eco Rewards"
            case "stations": return "Red de Estaciones"
            default: return key
            }
        case .en:
            switch key {
            case "feed": return "Community"
            case "new_post": return "New Post"
            case "eco_hub": return "Forkar Eco Hub"
            case "co2_saved": return "CO₂ Saved"
            case "eco_points": return "Eco Points"
            case "scan_qr": return "Scan QR"
            case "my_qr": return "My QR Code"
            case "rewards": return "Eco Rewards Store"
            case "stations": return "Stations Network"
            default: return key
            }
        case .fr:
            switch key {
            case "feed": return "Communauté"
            case "new_post": return "Nouveau Post"
            case "eco_hub": return "Forkar Eco Hub"
            case "co2_saved": return "CO₂ Économisé"
            case "eco_points": return "Points Éco"
            case "scan_qr": return "Scanner QR"
            case "my_qr": return "Mon Code QR"
            case "rewards": return "Boutique Récompenses"
            case "stations": return "Réseau de Stations"
            default: return key
            }
        case .pt:
            switch key {
            case "feed": return "Comunidade"
            case "new_post": return "Nova Publicação"
            case "eco_hub": return "Forkar Eco Hub"
            case "co2_saved": return "CO₂ Economizado"
            case "eco_points": return "Pontos Eco"
            case "scan_qr": return "Escanear QR"
            case "my_qr": return "Meu Código QR"
            case "rewards": return "Loja de Recompensas"
            case "stations": return "Rede de Estações"
            default: return key
            }
        }
    }
}
