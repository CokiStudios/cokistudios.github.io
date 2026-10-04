import SwiftUI

// MARK: - Launch Action Types
public enum LaunchTarget: Equatable {
    case loopScript(relativeOrAbsolutePath: String)
    case nativeApp(appBundleOrPath: String, fallbackUrl: String?)
    case webCore(localPathOrUrl: String)
    case systemSettings
}

// MARK: - App Item Definition
public struct AppItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let category: String
    public let iconSymbol: String
    public let primaryColorHex: String
    public let secondaryColorHex: String
    public let badgeText: String
    public let summary: String
    public let releaseDate: String
    public let author: String
    public let techSpecs: [(key: String, value: String)]
    public let target: LaunchTarget
    public let isInstalled: Bool
    public let sizeMb: Double

    public init(
        id: String,
        title: String,
        subtitle: String,
        category: String,
        iconSymbol: String,
        primaryColorHex: String,
        secondaryColorHex: String,
        badgeText: String,
        summary: String,
        releaseDate: String = "2026",
        author: String = "Holo Entertainment / Coki Studios",
        techSpecs: [(key: String, value: String)],
        target: LaunchTarget,
        isInstalled: Bool = true,
        sizeMb: Double = 12.4
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.iconSymbol = iconSymbol
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.badgeText = badgeText
        self.summary = summary
        self.releaseDate = releaseDate
        self.author = author
        self.techSpecs = techSpecs
        self.target = target
        self.isInstalled = isInstalled
        self.sizeMb = sizeMb
    }

    public static func == (lhs: AppItem, rhs: AppItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - System Categories
public enum AppCategory: String, CaseIterable {
    case all = "Todos"
    case games = "Juegos"
    case dev = "Desarrollo"
    case system = "Sistema"
    case community = "Comunidad"
}

// MARK: - Target UI Architecture Profiles (Shine UI / XUI / flUI)
public enum TargetUIProfile: String, CaseIterable, Identifiable {
    case shineUI = "shine_ui"
    case xui = "xui"
    case flUI = "flui"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .shineUI: return "Shine UI"
        case .xui: return "XUI"
        case .flUI: return "flUI"
        }
    }

    public var subtitle: String {
        switch self {
        case .shineUI: return "Handheld Console Grid & Carousel (60Hz APU V-Sync)"
        case .xui: return "Pro Gamer Esports HUD (240Hz Vulkan Ultra-Low Latency)"
        case .flUI: return "Foldable Dual-Screen & Floating Cards (120Hz)"
        }
    }

    public var themeName: String {
        switch self {
        case .shineUI: return "frosted_aqua_a17"
        case .xui: return "cyber_neon_xui"
        case .flUI: return "aurora_indigo_fold"
        }
    }

    public var primaryColor: Color {
        switch self {
        case .shineUI: return Color(hex: "00f5d4")
        case .xui: return Color(hex: "38bdf8")
        case .flUI: return Color(hex: "c084fc")
        }
    }

    public var accentColor: Color {
        switch self {
        case .shineUI: return Color(hex: "0284c7")
        case .xui: return Color(hex: "082f49")
        case .flUI: return Color(hex: "ec4899")
        }
    }

    public var targetFps: Int {
        switch self {
        case .shineUI: return 60
        case .xui: return 240
        case .flUI: return 120
        }
    }

    public var iconSymbol: String {
        switch self {
        case .shineUI: return "gamecontroller.fill"
        case .xui: return "bolt.shield.fill"
        case .flUI: return "macbook.and.iphone"
        }
    }
}

// MARK: - Performance Profiles
public enum PerformanceProfile: String, CaseIterable {
    case eco = "Eco Saver (30 FPS)"
    case balanced = "Equilibrado (60 FPS)"
    case turbo = "Turbo Overclock (120 FPS)"

    public var targetFps: Int {
        switch self {
        case .eco: return 30
        case .balanced: return 60
        case .turbo: return 120
        }
    }

    public var badgeColor: Color {
        switch self {
        case .eco: return Color.green
        case .balanced: return Color.cyan
        case .turbo: return Color.purple
        }
    }
}

// MARK: - Color Extension Helper
extension Color {
    public init(hex: String) {
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
