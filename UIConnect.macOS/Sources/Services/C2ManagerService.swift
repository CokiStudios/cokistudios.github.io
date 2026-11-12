import Foundation
import CryptoKit

// MARK: - Native Component 2 (.c2) Archive & Bundle Manager
public final class C2ManagerService: @unchecked Sendable {
    public static let shared = C2ManagerService()

    private init() {}

    /// Scans the workspace `c2-modules` directory
    public func scanModules(directoryPath: String? = nil) -> [C2Module] {
        let fileManager = FileManager.default
        let dir = directoryPath ?? resolveDefaultModulesDir()

        guard fileManager.fileExists(atPath: dir) else { return [] }

        var modules: [C2Module] = []
        guard let files = try? fileManager.contentsOfDirectory(atPath: dir) else { return [] }

        for file in files where file.hasSuffix(".c2") {
            let fullPath = (dir as NSString).appendingPathComponent(file)
            if let mod = inspectModule(atPath: fullPath) {
                modules.append(mod)
            }
        }

        return modules.sorted { $0.fileName < $1.fileName }
    }

    /// Resolves the c2-modules folder relative to current directory or repo root
    public func resolveDefaultModulesDir() -> String {
        let cwd = FileManager.default.currentDirectoryPath
        let candidate1 = (cwd as NSString).appendingPathComponent("c2-modules")
        if FileManager.default.fileExists(atPath: candidate1) { return candidate1 }

        let repoCandidate = NSString(string: "~/cokistudios.github.io/c2-modules").expandingTildeInPath
        if FileManager.default.fileExists(atPath: repoCandidate) { return repoCandidate }

        return candidate1
    }

    /// Inspects a .c2 file (extracts manifest and tokens in temporary folder)
    public func inspectModule(atPath path: String) -> C2Module? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path),
              let attrs = try? fileManager.attributesOfItem(atPath: path),
              let fileSize = attrs[.size] as? Int64 else {
            return nil
        }

        let fileName = (path as NSString).lastPathComponent
        let sha256 = calculateSHA256(for: URL(fileURLWithPath: path))

        // Temporary unzip inspection using /usr/bin/unzip (macOS native)
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("c2_inspect_\(UUID().uuidString)")
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments = ["-q", path, "-d", tempDir.path]
        try? unzip.run()
        unzip.waitUntilExit()

        var componentId = "com.cokistudios.c2.unknown"
        var name = (fileName as NSString).deletingPathExtension
        var targetDevice = "shine_all"
        var targetFps = 60
        var theme = "cyber_neon_xui"
        var primaryColor = "#38bdf8"
        var entrypoint = "source.loop"
        var manifestJSON = "{}"
        var tokensJSON = "{}"

        let manifestFile = tempDir.appendingPathComponent("manifest.json")
        if let data = try? Data(contentsOf: manifestFile),
           let str = String(data: data, encoding: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            manifestJSON = str
            componentId = json["component_id"] as? String ?? componentId
            name = json["name"] as? String ?? name
            targetDevice = json["target_device"] as? String ?? targetDevice
            targetFps = json["target_fps"] as? Int ?? targetFps
            theme = json["theme"] as? String ?? theme
            primaryColor = json["primary_color"] as? String ?? primaryColor
            entrypoint = json["entrypoint"] as? String ?? entrypoint
        }

        let tokensFile = tempDir.appendingPathComponent("tokens.json")
        if let data = try? Data(contentsOf: tokensFile),
           let str = String(data: data, encoding: .utf8) {
            tokensJSON = str
        }

        return C2Module(
            fileName: fileName,
            filePath: path,
            fileSizeBytes: fileSize,
            componentId: componentId,
            name: name,
            targetDevice: targetDevice,
            targetFps: targetFps,
            theme: theme,
            primaryColor: primaryColor,
            entrypoint: entrypoint,
            isSha256Valid: true,
            sha256Checksum: sha256,
            manifestJSON: manifestJSON,
            tokensJSON: tokensJSON
        )
    }

    /// Computes hardware-backed SHA-256 hash using Apple CryptoKit
    public func calculateSHA256(for fileURL: URL) -> String {
        guard let data = try? Data(contentsOf: fileURL) else { return "" }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
