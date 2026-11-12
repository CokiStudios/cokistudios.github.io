import SwiftUI

// MARK: - Loop OS Color Palette & Glassmorphic Styling
public enum UITheme {
    public static let bg = Color(hex: "#0b0f19")
    public static let cardBg = Color(hex: "#151d30")
    public static let cardBorder = Color(hex: "#22314e")
    public static let primary = Color(hex: "#38bdf8")     // Electric Cyan Blue
    public static let accent = Color(hex: "#00f5d4")      // Neon Mint Aqua
    public static let purple = Color(hex: "#c084fc")      // Aurora Fold Purple
    public static let yellow = Color(hex: "#facc15")      // Amber Tone
    public static let green = Color(hex: "#10b981")       // Terminal Green
    public static let red = Color(hex: "#f43f5e")         // Crimson Alert
    public static let textPrimary = Color(hex: "#f8fafc")
    public static let textSecondary = Color(hex: "#94a3b8")
    public static let logBg = Color(hex: "#070a12")
    public static let btnBg = Color(hex: "#0284c7")

    // Gradients
    public static let neonGradient = LinearGradient(
        colors: [primary, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let purpleGradient = LinearGradient(
        colors: [purple, primary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let cardGradient = LinearGradient(
        colors: [Color(hex: "#151d30").opacity(0.85), Color(hex: "#0f172a").opacity(0.85)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Hex Color Helper
public extension Color {
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

// MARK: - Glassmorphic Card View Modifier
public struct GlassmorphicCard: ViewModifier {
    var cornerRadius: CGFloat = 12
    var borderColor: Color = UITheme.cardBorder

    public func body(content: Content) -> some View {
        content
            .background(UITheme.cardGradient)
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

public extension View {
    func glassCard(cornerRadius: CGFloat = 12, borderColor: Color = UITheme.cardBorder) -> some View {
        self.modifier(GlassmorphicCard(cornerRadius: cornerRadius, borderColor: borderColor))
    }
}
