import Foundation

public enum LoopingChannel: String, CaseIterable, Identifiable, Codable, Sendable {
    case prod
    case omega
    case alpha

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .prod: return "Looping"
        case .omega: return "Omega Looping"
        case .alpha: return "Alpha! 1.1.2A"
        }
    }

    public var tierLabel: String {
        switch self {
        case .prod: return "Production Release"
        case .omega: return "Release Candidate (RC)"
        case .alpha: return "Super Experimental"
        }
    }
}

public struct EditorTab: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var fileURL: URL?
    public var content: String
    public var isDirty: Bool

    public init(id: UUID = UUID(), title: String, fileURL: URL? = nil, content: String, isDirty: Bool = false) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.content = content
        self.isDirty = isDirty
    }
}

public struct WorkspaceItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public var children: [WorkspaceItem]?

    public init(url: URL, isDirectory: Bool, children: [WorkspaceItem]? = nil) {
        self.id = url.path
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
    }
}

public struct AstNodeItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let lineNumber: Int
    public let kind: String
    public let name: String
    public let detail: String
    public var children: [AstNodeItem]

    public init(id: UUID = UUID(), lineNumber: Int, kind: String, name: String, detail: String, children: [AstNodeItem] = []) {
        self.id = id
        self.lineNumber = lineNumber
        self.kind = kind
        self.name = name
        self.detail = detail
        self.children = children
    }
}

public struct DiagnosticItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let severity: String
    public let line: Int
    public let message: String

    public init(id: UUID = UUID(), severity: String, line: Int, message: String) {
        self.id = id
        self.severity = severity
        self.line = line
        self.message = message
    }
}

public struct TemplatePreset: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let fileName: String
    public let summary: String
    public let code: String

    public init(title: String, fileName: String, summary: String, code: String) {
        self.id = fileName
        self.title = title
        self.fileName = fileName
        self.summary = summary
        self.code = code
    }
}

public struct StageScenario: Codable, Sendable {
    public var name: String = "Holo Cyber Stage"
    public var weather: String = "clear"
    public var bg: String = "#070b14"
    public var accent: String = "#38bdf8"
    public init() {}
}

public struct StageWorld: Codable, Sendable {
    public var width: Double = 1200
    public var height: Double = 480
    public init() {}
}

public struct StageCamera: Codable, Sendable {
    public var x: Double = 0
    public var y: Double = 0
    public var shake: Double = 0
    public init() {}
}

public struct Stage2DEntitySnapshot: Codable, Identifiable, Sendable {
    public var id: String { "\(type):\(name):\(Int(x)):\(Int(y))" }
    public var type: String
    public var name: String
    public var x: Double
    public var y: Double
    public var w: Double
    public var h: Double
    public var r: Double
    public var color: String
    public var label: String
    public var collected: Bool
    public var broken: Bool
    public var alive: Bool
}

public struct StageSnapshot: Codable, Sendable {
    public var is3DMode: Bool = false
    public var score: Int = 0
    public var lives: Int = 3
    public var maxLives: Int = 3
    public var combo: Int = 0
    public var fps: Int = 60
    public var gravity: Double = 980
    public var gameOver: Bool = false
    public var gameWon: Bool = false
    public var scenario: StageScenario = StageScenario()
    public var world: StageWorld = StageWorld()
    public var camera: StageCamera = StageCamera()
    public var entities: [Stage2DEntitySnapshot] = []
    public init() {}
}

public struct StageCardSpec: Codable, Identifiable, Sendable {
    public var id: String { "\(title):\(Int(x)):\(Int(y))" }
    public var title: String
    public var text: String
    public var badge: String
    public var x: Double
    public var y: Double
    public var w: Double
    public var h: Double
}

public struct StageButtonSpec: Codable, Identifiable, Sendable {
    public var id: String { "\(text):\(action)" }
    public var text: String
    public var action: String
    public var x: Double
    public var y: Double
}

public struct StageUiSnapshot: Codable, Sendable {
    public var title: String = "Looping Stage"
    public var target: String = "shine_ui"
    public var theme: String = "frosted_aqua_a17"
    public var width: Double = 850
    public var height: Double = 540
    public var cards: [StageCardSpec] = []
    public var buttons: [StageButtonSpec] = []
    public var swiftuiComponents: [String] = []
    public init() {}
}

public struct ExecutionResponse: Codable, Sendable {
    public var ok: Bool = false
    public var is3DMode: Bool = false
    public var elapsedMs: Double = 0
    public var logs: [String] = []
    public init(ok: Bool = false, is3DMode: Bool = false, elapsedMs: Double = 0, logs: [String] = []) {
        self.ok = ok
        self.is3DMode = is3DMode
        self.elapsedMs = elapsedMs
        self.logs = logs
    }
}

public struct SelfTestEntry: Codable, Identifiable, Sendable {
    public var id: String { name }
    public var name: String
    public var passed: Bool
}

public struct SelfTestResponse: Codable, Sendable {
    public var passed: Int = 0
    public var total: Int = 0
    public var elapsedMs: Double = 0
    public var tests: [SelfTestEntry] = []

    public var ok: Bool { total > 0 && passed == total }
    public init() {}
}

public struct BenchResponse: Codable, Sendable {
    public var iterations: Int = 0
    public var ms: Double = 0
    public var acc: Int = 0
    public var sha256: String = ""

    public var ok: Bool { iterations > 0 }
    public init() {}
}

public struct InvisEncodeResponse: Codable, Sendable {
    public var valid: Bool = false
    public var byteLength: Int = 0
    public var hex: String = ""
    public init() {}
}

public struct SmileModuleItem: Codable, Identifiable, Hashable, Sendable {
    public var id: String { name }
    public var name: String
    public var version: String?
    public var language: String?
    public var description: String?
    public var author_name: String?
    public var entry_point: String?
    public var code_payload: String?
    public var license: String?
}

public struct EngineChannelInfo: Codable, Sendable {
    public var name: String?
    public var tier: String?
    public var version: String?
    public var arch_version: String?
    public var tarball_url: String?
    public var tarball_sha256: String?
    public var windows_zip_url: String?
    public var windows_zip_sha256: String?
}

public struct EngineLatestManifest: Codable, Sendable {
    public var version: String?
    public var semver: String?
    public var alpha_version: String?
    public var arch_version: String?
    public var release_name: String?
    public var release_date: String?
    public var release_notes: String?
    public var channels: [String: EngineChannelInfo]?
}

public struct DoctorCheckItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let component: String
    public let status: String
    public let detail: String
    public let hint: String

    public init(component: String, status: String, detail: String, hint: String = "") {
        self.id = component
        self.component = component
        self.status = status
        self.detail = detail
        self.hint = hint
    }
}
