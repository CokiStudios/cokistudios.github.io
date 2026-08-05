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
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if #available(iOS 15.0, macOS 12.0, *) {
                        Rectangle().fill(.thinMaterial)
                    } else {
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.indigo.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.indigo.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(ForkarTheme.primaryGradient)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .shadow(color: ForkarTheme.accent.opacity(configuration.isPressed ? 0.2 : 0.4), radius: 10, y: 4)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(ForkarTheme.text)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(ForkarTheme.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ForkarTheme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassmorphicCard())
    }
    
    func liquidGlass() -> some View {
        modifier(LiquidGlassModifier())
    }
}
