import SwiftUI

struct CSDevelopTheme {
    static let bg = Color.dynamic(light: Color(hex: "#f8fafc") ?? .white, dark: Color(hex: "#0a0e1a") ?? .black)
    static let card = Color.dynamic(light: Color.white.opacity(0.6), dark: Color(hex: "#111827")?.opacity(0.5) ?? Color.white.opacity(0.03))
    static let cardHover = Color.dynamic(light: Color.white.opacity(0.8), dark: Color(hex: "#1a2235")?.opacity(0.6) ?? Color.white.opacity(0.06))
    static let border = Color.dynamic(light: Color(hex: "#e2e8f0") ?? .gray.opacity(0.2), dark: Color.white.opacity(0.08))
    static let borderGlow = Color.dynamic(light: (Color(hex: "#4f46e5") ?? .indigo).opacity(0.2), dark: (Color(hex: "#6366f1") ?? .indigo).opacity(0.4))
    static let accent = Color.dynamic(light: Color(hex: "#4f46e5") ?? .indigo, dark: Color(hex: "#6366f1") ?? .indigo)
    static let accent2 = Color.dynamic(light: Color(hex: "#7c3aed") ?? .purple, dark: Color(hex: "#8b5cf6") ?? .purple)
    static let green = Color(hex: "#10b981") ?? Color.green
    static let red = Color(hex: "#ef4444") ?? Color.red
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

// MARK: - View Modifiers for Glassmorphism
struct CSGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(CSDevelopTheme.card)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(CSDevelopTheme.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

struct CSPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(CSDevelopTheme.primaryGradient)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .shadow(color: CSDevelopTheme.accent.opacity(configuration.isPressed ? 0.2 : 0.4), radius: 10, y: 4)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CSSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(CSDevelopTheme.text)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(CSDevelopTheme.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CSDevelopTheme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func csGlassCard() -> some View {
        modifier(CSGlassCard())
    }
}
