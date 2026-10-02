import SwiftUI

public struct ShineMapsTheme {
    public static let bgDark = Color(red: 2/255, green: 6/255, blue: 23/255) // #020617
    public static let surfaceDark = Color(red: 11/255, green: 18/255, blue: 32/255) // #0b1220
    public static let cardGlass = Color(red: 15/255, green: 23/255, blue: 42/255).opacity(0.85) // #0f172a
    public static let borderSubtle = Color(red: 30/255, green: 41/255, blue: 59/255) // #1e293b
    public static let cyanPrimary = Color(red: 56/255, green: 189/255, blue: 248/255) // #38bdf8
    public static let cyanAccent = Color(red: 0/255, green: 242/255, blue: 254/255) // #00f2fe
    public static let roseAccent = Color(red: 244/255, green: 63/255, blue: 94/255) // #f43f5e
    public static let textPrimary = Color(red: 248/255, green: 250/255, blue: 252/255) // #f8fafc
    public static let textSub = Color(red: 148/255, green: 163/255, blue: 184/255) // #94a3b8

    public static var cyanGradient: LinearGradient {
        LinearGradient(
            colors: [cyanPrimary, cyanAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 18

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(ShineMapsTheme.cardGlass)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(ShineMapsTheme.borderSubtle, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

public extension View {
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
