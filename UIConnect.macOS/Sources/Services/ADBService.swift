import Foundation

// MARK: - Native ADB Process Manager
public final class ADBService: @unchecked Sendable {
    public static let shared = ADBService()

    private let remoteModuleDir = "/sdcard/ShineUI/modules"
    private let installAction = "com.cokistudios.shine.INSTALL_C2"

    private init() {}

    /// Locates the active adb binary on the system
    public func resolveAdbPath() -> String {
        let fileManager = FileManager.default
        let candidates = [
            "/opt/homebrew/bin/adb",
            "/usr/local/bin/adb",
            "/usr/bin/adb",
            NSString(string: "~/Library/Android/sdk/platform-tools/adb").expandingTildeInPath
        ]
        for path in candidates {
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }

        // Fallback: search in PATH using /usr/bin/which
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        proc.arguments = ["adb"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let out = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !out.isEmpty {
            return out
        }
        return "adb"
    }

    /// Executes an ADB command asynchronously with timeout
    public func runAdb(args: [String], device: String? = nil, timeoutSeconds: Double = 15.0) async -> (exitCode: Int32, stdout: String, stderr: String) {
        let adbPath = resolveAdbPath()
        var fullArgs: [String] = []
        if let device = device, !device.isEmpty {
            fullArgs.append(contentsOf: ["-s", device])
        }
        fullArgs.append(contentsOf: args)

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: adbPath)
                process.arguments = fullArgs

                let outPipe = Pipe()
                let errPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError = errPipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

                    let stdoutStr = String(data: outData, encoding: .utf8) ?? ""
                    let stderrStr = String(data: errData, encoding: .utf8) ?? ""

                    continuation.resume(returning: (process.terminationStatus, stdoutStr, stderrStr))
                } catch {
                    continuation.resume(returning: (-1, "", "No se pudo ejecutar adb (\(adbPath)): \(error.localizedDescription)"))
                }
            }
        }
    }

    /// Scans for connected devices via USB and Wi-Fi
    public func detectDevices() async -> [ADBDevice] {
        let (code, stdout, _) = await runAdb(args: ["devices", "-l"])
        guard code == 0 else { return [] }

        var list: [ADBDevice] = []
        let lines = stdout.components(separatedBy: .newlines)
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard parts.count >= 2 else { continue }

            let serial = parts[0]
            let state = parts[1]

            var model = "Unknown"
            var product = "Unknown"

            for p in parts {
                if p.hasPrefix("model:") {
                    model = String(p.dropFirst("model:".count))
                } else if p.hasPrefix("product:") {
                    product = String(p.dropFirst("product:".count))
                }
            }

            var dev = ADBDevice(serial: serial, state: state, model: model, product: product)
            if state == "device" {
                dev.batteryLevel = await getBatteryLevel(serial: serial)
            }
            list.append(dev)
        }
        return list
    }

    /// Queries battery percentage
    public func getBatteryLevel(serial: String) async -> String {
        let (code, stdout, _) = await runAdb(args: ["shell", "dumpsys", "battery"], device: serial)
        guard code == 0 else { return "N/A" }
        for line in stdout.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("level:") {
                let lvl = t.replacingOccurrences(of: "level:", with: "").trimmingCharacters(in: .whitespaces)
                return "\(lvl)%"
            }
        }
        return "N/A"
    }

    /// Pushes a .c2 file to the Shine device and fires installation broadcast
    public func installModule(filePath: String, serial: String?) async -> Result<String, Error> {
        let fileName = (filePath as NSString).lastPathComponent

        // 1. Ensure remote directory exists
        _ = await runAdb(args: ["shell", "mkdir", "-p", remoteModuleDir], device: serial)

        // 2. Push file
        let remotePath = "\(remoteModuleDir)/\(fileName)"
        let (pushCode, pushOut, pushErr) = await runAdb(args: ["push", filePath, remotePath], device: serial, timeoutSeconds: 30)
        guard pushCode == 0 else {
            let err = pushErr.isEmpty ? pushOut : pushErr
            return .failure(NSError(domain: "ADBService", code: Int(pushCode), userInfo: [NSLocalizedDescriptionKey: "Error en adb push: \(err)"]))
        }

        // 3. Broadcast intent to Shine Launcher / OS
        let (bCode, bOut, bErr) = await runAdb(args: [
            "shell", "am", "broadcast",
            "-a", installAction,
            "--es", "module_path", remotePath,
            "--es", "module_name", fileName
        ], device: serial)

        let summary = "Módulo \(fileName) transferido a \(remotePath) e instalado con éxito."
        if bCode != 0 {
            return .success("\(summary)\nAdvertencia broadcast: \(bErr.isEmpty ? bOut : bErr)")
        }
        return .success(summary)
    }

    /// Reboots device or initiates wireless pairing
    public func rebootDevice(serial: String?) async -> Bool {
        let (code, _, _) = await runAdb(args: ["reboot"], device: serial)
        return code == 0
    }
}
