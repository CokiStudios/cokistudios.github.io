import SwiftUI

// MARK: - Game & App Card Component
public struct GameCardView: View {
    public let app: AppItem
    public let isSelected: Bool
    public let isHero: Bool
    public var onSelect: () -> Void
    public var onLaunch: () -> Void

    @State private var isHovering: Bool = false

    public init(
        app: AppItem,
        isSelected: Bool,
        isHero: Bool = false,
        onSelect: @escaping () -> Void,
        onLaunch: @escaping () -> Void
    ) {
        self.app = app
        self.isSelected = isSelected
        self.isHero = isHero
        self.onSelect = onSelect
        self.onLaunch = onLaunch
    }

    private var primaryColor: Color {
        Color(hex: app.primaryColorHex)
    }

    private var secondaryColor: Color {
        Color(hex: app.secondaryColorHex)
    }

    public var body: some View {
        Button {
            if isSelected {
                onLaunch()
            } else {
                onSelect()
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Background Glass & Mesh Gradient
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "0f172a").opacity(0.92),
                                Color(hex: "020617").opacity(0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Colored Ambient Glow from Top Right
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                primaryColor.opacity(isSelected ? 0.35 : 0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .frame(width: 240, height: 240)
                    .offset(x: 100, y: -60)
                    .blur(radius: 20)

                // Card Interior Content
                VStack(alignment: .leading, spacing: 12) {
                    // Top Bar inside Card: Category Pill & Tech Badge
                    HStack {
                        // Category Pill
                        Text(app.category.uppercased())
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(primaryColor.opacity(0.16))
                            .clipShape(Capsule())

                        Spacer()

                        // Performance / Engine Badge
                        Text(app.badgeText)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Center Hero Graphic / Symbol
                    HStack {
                        Spacer()
                        ZStack {
                            // Ambient icon aura
                            Circle()
                                .fill(primaryColor.opacity(isSelected ? 0.3 : 0.08))
                                .frame(width: isHero ? 90 : 64, height: isHero ? 90 : 64)
                                .blur(radius: 12)

                            Image(systemName: app.iconSymbol)
                                .font(.system(size: isHero ? 44 : 32, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [primaryColor, secondaryColor, .white],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: primaryColor.opacity(0.6), radius: 8)
                        }
                        Spacer()
                    }

                    Spacer()

                    // Bottom Details (Title, Subtitle, File Size)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.title)
                            .font(.system(size: isHero ? 19 : 15, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(app.subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)

                        if isSelected {
                            // Launch CTA Pill
                            HStack(spacing: 6) {
                                Text("A")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(.black)
                                    .frame(width: 16, height: 16)
                                    .background(Color(hex: "00f5d4"))
                                    .clipShape(Circle())

                                Text("INICIAR / EJECUTAR")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(Color(hex: "00f5d4"))

                                Spacer()

                                Text(String(format: "%.1f MB", app.sizeMb))
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .padding(16)
            }
            .frame(
                width: isHero ? 320 : 250,
                height: isHero ? 220 : 180
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: isSelected
                                ? [Color(hex: "00f5d4"), primaryColor, secondaryColor]
                                : [Color.white.opacity(isHovering ? 0.3 : 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2.5 : 1
                    )
            )
            .shadow(
                color: isSelected
                    ? Color(hex: "00f5d4").opacity(0.4)
                    : Color.black.opacity(0.4),
                radius: isSelected ? 18 : 8,
                x: 0,
                y: isSelected ? 8 : 4
            )
            .scaleEffect(isSelected ? 1.04 : (isHovering ? 1.01 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
