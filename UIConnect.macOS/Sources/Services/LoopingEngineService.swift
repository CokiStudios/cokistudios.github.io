import Foundation

// MARK: - Native Looping Engine v2.5 Interop Service
public final class LoopingEngineService: @unchecked Sendable {
    public static let shared = LoopingEngineService()

    private init() {}

    /// Resolves path to the Looping C++ native compiler
    public func resolveLoopingBinPath() -> String {
        let cwd = FileManager.default.currentDirectoryPath
        let candidates = [
            (cwd as NSString).appendingPathComponent("bin/looping"),
            (cwd as NSString).appendingPathComponent("LoopingEngine/cpp/looping"),
            NSString(string: "~/cokistudios.github.io/bin/looping").expandingTildeInPath,
            "/usr/local/bin/looping"
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return "looping"
    }

    /// Evaluates Looping code dynamically using `./bin/looping eval "<code>"`
    public func eval(code: String) async -> (exitCode: Int32, stdout: String, stderr: String) {
        let binPath = resolveLoopingBinPath()

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: binPath)
                proc.arguments = ["eval", code]

                let outPipe = Pipe()
                let errPipe = Pipe()
                proc.standardOutput = outPipe
                proc.standardError = errPipe

                do {
                    try proc.run()
                    proc.waitUntilExit()

                    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

                    let stdoutStr = String(data: outData, encoding: .utf8) ?? ""
                    let stderrStr = String(data: errData, encoding: .utf8) ?? ""

                    continuation.resume(returning: (proc.terminationStatus, stdoutStr, stderrStr))
                } catch {
                    continuation.resume(returning: (-1, "", "No se pudo ejecutar el motor Looping: \(error.localizedDescription)"))
                }
            }
        }
    }

    /// Audits all .c2 modules using the pipeline operator (|>) in Looping
    public func auditC2ModulesViaPipeline(fileNames: [String]) async -> String {
        let quotedList = fileNames.map { "\"\($0)\"" }.joined(separator: ", ")
        let snippet = """
        fn is_c2(f) => contains(f, ".c2")
        val all = [\(quotedList)]
        val verified = all |> filter(is_c2)
        print $"[C2 AUDIT] Módulos validados con pipeline (|>) [{len(verified)}/6]: {verified}"
        """
        let (code, stdout, stderr) = await eval(code: snippet)
        if code == 0 {
            return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Error en pipeline: \(stderr)"
    }
}
