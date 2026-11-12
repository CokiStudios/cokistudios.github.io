import SwiftUI

// MARK: - Live Log Console Entry
public struct LogEntry: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let category: Category
    public let message: String

    public enum Category: String, Sendable, CaseIterable {
        case system = "SYSTEM"
        case adb = "ADB"
        case c2 = "C2 AUDIT"
        case ota = "CS WEBS OTA"
        case loop = "LOOPING"
        case audio = "AUDIO"

        public var color: Color {
            switch self {
            case .system: return UITheme.textSecondary
            case .adb: return UITheme.primary
            case .c2: return UITheme.purple
            case .ota: return UITheme.accent
            case .loop: return UITheme.yellow
            case .audio: return Color(hex: "#ec4899")
            }
        }

        public var icon: String {
            switch self {
            case .system: return "terminal"
            case .adb: return "cable.connector"
            case .c2: return "shippingbox.fill"
            case .ota: return "cloud.bolt.fill"
            case .loop: return "sparkles"
            case .audio: return "speaker.wave.3.fill"
            }
        }
    }

    public var timestampFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    public init(category: Category, message: String) {
        self.timestamp = Date()
        self.category = category
        self.message = message
    }
}
