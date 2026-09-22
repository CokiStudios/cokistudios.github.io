import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 🎨 FORKAR THEME — macOS Desktop & PC Design System
// Liquid Glass, Dark Aesthetics & Neomorphic Accents
// ══════════════════════════════════════════════════════════════════

struct ForkarTheme {
    // Fondos Base
    static let bg = Color(hex: "#06090F")
    static let bgSecondary = Color(hex: "#0D1117")
    static let bgTertiary = Color(hex: "#161B22")
    
    // Tarjetas y Paneles Glassmorphic
    static let card = Color.white.opacity(0.04)
    static let cardHover = Color.white.opacity(0.07)
    static let cardActive = Color.white.opacity(0.10)
    static let border = Color.white.opacity(0.08)
    static let borderHighlight = Color(hex: "#6366F1").opacity(0.4)
    
    // Colores de Acento
    static let accent = Color(hex: "#6366F1")       // Índigo Forkar
    static let accentGradientStart = Color(hex: "#6366F1")
    static let accentGradientEnd = Color(hex: "#8B5CF6")
    static let greenEco = Color(hex: "#10B981")     // Verde Eco Hub
    static let pinkGaming = Color(hex: "#EC4899")
    static let amberWarning = Color(hex: "#F59E0B")
    
    // Textos
    static let text = Color(hex: "#F1F5F9")
    static let textSub = Color(hex: "#94A3B8")
    static let textMuted = Color(hex: "#475569")
    
    // Gradiente Primario de la Marca
    static let brandGradient = LinearGradient(
        colors: [accentGradientStart, accentGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
