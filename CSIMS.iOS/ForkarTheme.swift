import SwiftUI

struct ForkarTheme {
    static let bg = Color(hex: "#06090f") ?? Color.black
    static let card = Color.white.opacity(0.06)
    static let cardHover = Color.white.opacity(0.1)
    static let border = Color.white.opacity(0.12)
    static let accent = Color(hex: "#6366f1") ?? Color.indigo
    static let accent2 = Color(hex: "#8b5cf6") ?? Color.purple
    static let green = Color(hex: "#10b981") ?? Color.green
    static let text = Color(hex: "#f1f5f9") ?? Color.white
    static let textSub = Color(hex: "#94a3b8") ?? Color.gray
    static let textMuted = Color(hex: "#475569") ?? Color.gray
    
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accent2],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

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
}

// MARK: - Liquid Glass Modifier
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var glowColor: Color = ForkarTheme.accent
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    glowColor.opacity(0.08),
                                    Color.black.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    glowColor.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
            )
            .shadow(color: glowColor.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 16, glowColor: Color = ForkarTheme.accent) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, glowColor: glowColor))
    }
}
