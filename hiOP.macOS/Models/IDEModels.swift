import Foundation
import SwiftUI

// MARK: - File Node for Native Explorer
public struct FileNode: Identifiable, Hashable {
    public let id: String
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public var children: [FileNode]?

    public init(url: URL, isDirectory: Bool, children: [FileNode]? = nil) {
        self.id = url.path
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
    }

    public var iconName: String {
        if isDirectory {
            return "folder.fill"
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "loop":
            return "infinity"
        case "ruup":
            return "bolt.badge.automatic.fill"
        case "py":
            return "chevron.left.forwardslash.chevron.right"
        case "swift":
            return "swift"
        case "cpp", "hpp", "h", "c":
            return "c.square.fill"
        case "json", "yml", "yaml":
            return "doc.badge.gearshape.fill"
        case "md", "txt":
            return "doc.text.fill"
        default:
            return "doc.fill"
        }
    }

    public var iconColor: Color {
        if isDirectory {
            return Color(red: 0.35, green: 0.65, blue: 1.0)
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "loop":
            return Color(red: 0.0, green: 0.96, blue: 0.83) // Aqua
        case "ruup":
            return Color(red: 1.0, green: 0.42, blue: 0.42) // Rust coral
        case "py":
            return Color(red: 1.0, green: 0.75, blue: 0.2) // Amber
        case "swift":
            return Color(red: 1.0, green: 0.4, blue: 0.2) // Swift orange
        case "cpp", "hpp":
            return Color(red: 0.4, green: 0.7, blue: 1.0) // C++ blue
        default:
            return Color.white.opacity(0.6)
        }
    }
}

// MARK: - Open Editor Tab
public struct OpenTab: Identifiable, Equatable {
    public let id: String
    public let url: URL
    public var title: String
    public var content: String
    public var isDirty: Bool

    public init(url: URL, content: String, isDirty: Bool = false) {
        self.id = url.path
        self.url = url
        self.title = url.lastPathComponent
        self.content = content
        self.isDirty = isDirty
    }

    public static func == (lhs: OpenTab, rhs: OpenTab) -> Bool {
        lhs.id == rhs.id && lhs.isDirty == rhs.isDirty
    }
}

// MARK: - IDE Execution Status
public enum IDEExecutionState: Equatable {
    case idle
    case compiling(fileName: String)
    case running(fileName: String, pid: Int32)
    case completed(exitCode: Int32, durationMs: Double)
    case failed(error: String)
}
