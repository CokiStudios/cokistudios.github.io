import SwiftUI

struct ForkarTheme {
    static let bg = Color.dynamic(light: Color(hex: "#f8fafc") ?? .white, dark: Color(hex: "#06090f") ?? .black)
    static let card = Color.dynamic(light: Color.black.opacity(0.02), dark: Color.white.opacity(0.04))
    static let cardHover = Color.dynamic(light: Color.black.opacity(0.04), dark: Color.white.opacity(0.07))
    static let border = Color.dynamic(light: Color.black.opacity(0.06), dark: Color.white.opacity(0.07))
    static let accent = Color.dynamic(light: Color(hex: "#4f46e5") ?? .indigo, dark: Color(hex: "#6366f1") ?? .indigo)
    static let accent2 = Color.dynamic(light: Color(hex: "#7c3aed") ?? .purple, dark: Color(hex: "#8b5cf6") ?? .purple)
    static let green = Color.dynamic(light: Color(hex: "#10b981") ?? .green, dark: Color(hex: "#10b981") ?? .green)
    static let text = Color.dynamic(light: Color(hex: "#0f172a") ?? .black, dark: Color(hex: "#f1f5f9") ?? .white)
    static let textSub = Color.dynamic(light: Color(hex: "#475569") ?? .gray, dark: Color(hex: "#94a3b8") ?? .gray)
    static let textMuted = Color.dynamic(light: Color(hex: "#64748b") ?? .gray, dark: Color(hex: "#475569") ?? .gray)
    
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accent2],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Modifiers for Glassmorphism & Liquid Glass
struct GlassmorphicCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                Group {
                    if #available(iOS 15.0, macOS 12.0, *) {
                        Rectangle().fill(.ultraThinMaterial)
                    } else {
                        ForkarTheme.card
                    }
                }
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 10)
    }
}

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var glowColor: Color = ForkarTheme.accent
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if #available(iOS 15.0, macOS 12.0, *) {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.black.opacity(0.4))
                    }
                    
                    // Capa de reflexión líquida translúcida
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    glowColor.opacity(0.06),
                                    Color.black.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Borde de cristal con degradado brillante
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    glowColor.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: glowColor.opacity(0.25), radius: 18, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, glowColor: Color = ForkarTheme.accent) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, glowColor: glowColor))
    }
    
    func glassCard() -> some View {
        self.modifier(GlassmorphicCard())
    }
}

// MARK: - Circle Avatar Placeholder
struct CircleAvatarPlaceholder: View {
    let initials: String
    
    var body: some View {
        Text(initials)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(ForkarTheme.accent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ForkarTheme.accent.opacity(0.15))
            .clipShape(Circle())
            .overlay(Circle().stroke(ForkarTheme.accent.opacity(0.3), lineWidth: 1))
    }
}
