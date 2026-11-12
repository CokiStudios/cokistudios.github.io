import Foundation

// MARK: - Component 2 (.c2) Package Model
public struct C2Module: Identifiable, Hashable, Sendable {
    public var id: String { fileName }
    public let fileName: String
    public let filePath: String
    public let fileSizeFormatted: String
    public let fileSizeBytes: Int64
    
    // Manifest details
    public var componentId: String
    public var name: String
    public var targetDevice: String
    public var targetFps: Int
    public var theme: String
    public var primaryColor: String
    public var entrypoint: String
    
    // Integrity
    public var isSha256Valid: Bool
    public var sha256Checksum: String
    public var manifestJSON: String
    public var tokensJSON: String

    public init(
        fileName: String,
        filePath: String,
        fileSizeBytes: Int64,
        componentId: String = "com.cokistudios.c2.unknown",
        name: String = "Untitled Module",
        targetDevice: String = "shine_all",
        targetFps: Int = 60,
        theme: String = "cyber_neon_xui",
        primaryColor: String = "#38bdf8",
        entrypoint: String = "source.loop",
        isSha256Valid: Bool = true,
        sha256Checksum: String = "",
        manifestJSON: String = "{}",
        tokensJSON: String = "{}"
    ) {
        self.fileName = fileName
        self.filePath = filePath
        self.fileSizeBytes = fileSizeBytes
        self.fileSizeFormatted = ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
        self.componentId = componentId
        self.name = name
        self.targetDevice = targetDevice
        self.targetFps = targetFps
        self.theme = theme
        self.primaryColor = primaryColor
        self.entrypoint = entrypoint
        self.isSha256Valid = isSha256Valid
        self.sha256Checksum = sha256Checksum
        self.manifestJSON = manifestJSON
        self.tokensJSON = tokensJSON
    }

    public var badgeText: String {
        if targetFps >= 240 {
            return "240Hz XUI"
        } else if targetFps >= 120 {
            return "120Hz flUI"
        } else {
            return "60Hz Shine"
        }
    }
}
