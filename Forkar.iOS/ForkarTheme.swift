import SwiftUI

struct ForkarTheme {
    static let bg = Color(hex: "#06090f") ?? Color.black
    static let card = Color.white.opacity(0.04)
    static let cardHover = Color.white.opacity(0.07)
    static let border = Color.white.opacity(0.07)
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

// MARK: - View Modifiers for Glassmorphism
struct GlassmorphicCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(ForkarTheme.card)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ForkarTheme.border, lineWidth: 1)
            )
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
}
