import Foundation
import Combine

// MARK: - Process Execution State
public enum ProcessState: Equatable {
    case idle
    case launching(scriptName: String)
    case running(scriptName: String, pid: Int32)
    case completed(exitCode: Int32, durationMs: Double)
    case failed(error: String)
}

// MARK: - Looping Process Runner
public final class LoopingProcessRunner: ObservableObject, @unchecked Sendable {
    @Published public var state: ProcessState = .idle
    @Published public var outputLines: [String] = []
    @Published public var currentDurationMs: Double = 0.0

    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var timer: Timer?
    private var startTime: Date?

    public init() {}

    /// Searches for the compiled native C++ Looping engine binary
    public static func resolveLoopingBinary() -> String? {
        let fileManager = FileManager.default

        // 1. Current working directory
        let cwdPath = fileManager.currentDirectoryPath + "/bin/looping"
        if fileManager.isExecutableFile(atPath: cwdPath) {
            return cwdPath
        }

        // 2. Relative to main bundle
        let bundleURL = Bundle.main.bundleURL
        let candidates = [
            bundleURL.deletingLastPathComponent().appendingPathComponent("bin/looping").path,
            bundleURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("bin/looping").path,
            bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("bin/looping").path,
            "/Users/jerix/cokistudios.github.io/bin/looping"
        ]

        for path in candidates {
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }

        // 3. Fallback to which looping
        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["looping"]
        let pipe = Pipe()
        whichProcess.standardOutput = pipe
        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty, fileManager.isExecutableFile(atPath: output) {
                return output
            }
        } catch {}

        return nil
    }

    /// Resolves project script file path
    public static func resolveScriptPath(_ relativePath: String) -> String {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: relativePath) {
            return relativePath
        }

        let candidates = [
            fileManager.currentDirectoryPath + "/" + relativePath,
            "/Users/jerix/cokistudios.github.io/" + relativePath,
            Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent(relativePath).path
        ]

        for cand in candidates {
            if fileManager.fileExists(atPath: cand) {
                return cand
            }
        }
        return relativePath
    }

    /// Executes a .loop or .ruup script asynchronously with live output streaming
    public func execute(scriptPath: String, appName: String) {
        stop()

        guard let binaryPath = Self.resolveLoopingBinary() else {
            DispatchQueue.main.async {
                self.outputLines = [
                    "❌ [ERROR] Could not locate native Looping engine binary (bin/looping).",
                    "   Make sure to compile the C++ engine via `make -C LoopingEngine/cpp`."
                ]
                self.state = .failed(error: "Binary 'bin/looping' not found.")
            }
            return
        }

        let resolvedScript = Self.resolveScriptPath(scriptPath)
        let scriptName = URL(fileURLWithPath: resolvedScript).lastPathComponent

        DispatchQueue.main.async {
            self.state = .launching(scriptName: scriptName)
            self.outputLines = [
                "⚡ [HOLO LOOP OS] Initializing subsystem for '\(appName)'...",
                "▶ Binary: \(binaryPath)",
                "▶ Target: \(resolvedScript)",
                "────────────────────────────────────────────────────────────"
            ]
            self.currentDurationMs = 0.0
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binaryPath)
        proc.arguments = [resolvedScript]

        // Inherit environment and current working directory
        let repoRoot = URL(fileURLWithPath: binaryPath).deletingLastPathComponent().deletingLastPathComponent().path
        proc.currentDirectoryURL = URL(fileURLWithPath: repoRoot)

        let stdout = Pipe()
        let stderr = Pipe()
        proc.standardOutput = stdout
        proc.standardError = stderr

        self.process = proc
        self.stdoutPipe = stdout
        self.stderrPipe = stderr

        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
            DispatchQueue.main.async {
                self?.outputLines.append(contentsOf: lines)
            }
        }

        stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
            DispatchQueue.main.async {
                self?.outputLines.append(contentsOf: lines.map { "⚠️ " + $0 })
            }
        }

        do {
            let start = Date()
            self.startTime = start
            try proc.run()

            DispatchQueue.main.async {
                self.state = .running(scriptName: scriptName, pid: proc.processIdentifier)
                self.startTimer()
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                proc.waitUntilExit()
                let elapsed = Date().timeIntervalSince(start) * 1000.0
                let exitCode = proc.terminationStatus

                DispatchQueue.main.async {
                    self?.stopTimer()
                    self?.currentDurationMs = elapsed
                    self?.state = .completed(exitCode: exitCode, durationMs: elapsed)
                    self?.outputLines.append(
                        "────────────────────────────────────────────────────────────"
                    )
                    self?.outputLines.append(
                        exitCode == 0
                            ? "✅ [PROCESS COMPLETE] Finished with code 0 in \(String(format: "%.2f", elapsed))ms"
                            : "❌ [PROCESS EXITED] Exit code \(exitCode) after \(String(format: "%.2f", elapsed))ms"
                    )
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.state = .failed(error: error.localizedDescription)
                self.outputLines.append("❌ [FATAL EXECUTION ERROR] \(error.localizedDescription)")
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.currentDurationMs = Date().timeIntervalSince(start) * 1000.0
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    public func stop() {
        stopTimer()
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil

        if let proc = process, proc.isRunning {
            proc.terminate()
        }
        process = nil
        stdoutPipe = nil
        stderrPipe = nil
    }

    deinit {
        stop()
    }
}
