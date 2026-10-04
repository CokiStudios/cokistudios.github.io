import Foundation
import Combine
import AppKit

public final class IDEViewModel: ObservableObject, @unchecked Sendable {
    @Published public var workspaceURL: URL
    @Published public var fileTree: [FileNode] = []
    @Published public var openTabs: [OpenTab] = []
    @Published public var activeTabId: String? = nil

    @Published public var terminalLogs: [String] = []
    @Published public var executionState: IDEExecutionState = .idle
    @Published public var executionDurationMs: Double = 0.0

    @Published public var isSidebarVisible: Bool = true
    @Published public var isTerminalVisible: Bool = true

    @Published public var targetPlatform: String = "Shine Loop Handheld (Holo Loop OS)"
    public let availableTargets = [
        "Shine Loop Handheld (Holo Loop OS)",
        "macOS Native (Metal 120Hz)",
        "Looping C++ Engine (POSIX Standalone)"
    ]

    private var runningProcess: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var execTimer: Timer?
    private var execStartTime: Date?

    public init(workspacePath: String = "/Users/jerix/cokistudios.github.io") {
        let ws = URL(fileURLWithPath: workspacePath)
        self.workspaceURL = ws
        loadWorkspace()
        openDefaultProject()
    }

    public var activeTab: OpenTab? {
        guard let id = activeTabId else { return openTabs.first }
        return openTabs.first { $0.id == id }
    }

    public func loadWorkspace() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let nodes = self.scanDirectory(self.workspaceURL, depth: 0, maxDepth: 2)
            DispatchQueue.main.async {
                self.fileTree = nodes
            }
        }
    }

    private func scanDirectory(_ dirURL: URL, depth: Int, maxDepth: Int) -> [FileNode] {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }

        var results: [FileNode] = []
        let sorted = items.sorted {
            let d1 = (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let d2 = (try? $1.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if d1 == d2 {
                return $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased()
            }
            return d1 && !d2
        }

        for item in sorted {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let name = item.lastPathComponent

            // Skip large build directories in sidebar
            if isDir && (name == ".git" || name == "node_modules" || name == "build" || name == "dist" || name == ".gradle" || name == "DerivedData") {
                continue
            }

            var children: [FileNode]? = nil
            if isDir && depth < maxDepth {
                children = scanDirectory(item, depth: depth + 1, maxDepth: maxDepth)
            }

            results.append(FileNode(url: item, isDirectory: isDir, children: children))
        }

        return results
    }

    private func openDefaultProject() {
        let candidates = [
            workspaceURL.appendingPathComponent("sample_loop_projects/signature_demo.loop"),
            workspaceURL.appendingPathComponent("sample_loop_projects/shine_launcher.loop"),
            workspaceURL.appendingPathComponent("sample_loop_projects/arcade.loop")
        ]

        for cand in candidates {
            if FileManager.default.fileExists(atPath: cand.path) {
                openFile(url: cand)
                break
            }
        }
    }

    public func openFile(url: URL) {
        if let existing = openTabs.first(where: { $0.id == url.path }) {
            self.activeTabId = existing.id
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let tab = OpenTab(url: url, content: content, isDirty: false)
            openTabs.append(tab)
            activeTabId = tab.id
        } catch {
            terminalLogs.append("❌ Could not read file: \(url.path) (\(error.localizedDescription))")
        }
    }

    public func updateActiveTabContent(_ newContent: String) {
        guard let id = activeTabId, let idx = openTabs.firstIndex(where: { $0.id == id }) else { return }
        if openTabs[idx].content != newContent {
            openTabs[idx].content = newContent
            openTabs[idx].isDirty = true
        }
    }

    public func saveActiveFile() {
        guard let id = activeTabId, let idx = openTabs.firstIndex(where: { $0.id == id }) else { return }
        let tab = openTabs[idx]
        do {
            try tab.content.write(to: tab.url, atomically: true, encoding: .utf8)
            openTabs[idx].isDirty = false
            terminalLogs.append("💾 Guardado: \(tab.title) (\(tab.content.count) bytes)")
        } catch {
            terminalLogs.append("❌ Error guardando \(tab.title): \(error.localizedDescription)")
        }
    }

    public func closeTab(id: String) {
        guard let idx = openTabs.firstIndex(where: { $0.id == id }) else { return }
        openTabs.remove(at: idx)
        if activeTabId == id {
            activeTabId = openTabs.last?.id
        }
    }

    public func createNewLoopFile(name: String = "nuevo_proyecto.loop") {
        let defaultCode = """
        # ═══════════════════════════════════════════════════════════════
        # ♾️ NUEVO PROGRAMA LOOPING v2.5 — SHINE LOOP CONSOLE
        # Coki Studios & Holo Entertainment
        # ═══════════════════════════════════════════════════════════════

        import loop.engine as game
        import loop.ui as ui

        define app "\(name.replacingOccurrences(of: ".loop", with: ""))" version 1.0:
            create window with title "\(name)" and size (800, 520)
            set theme to "frosted_aqua_a17"
            
            print "🌟 Ejecutando \(name) en Looping C++ Native!"
            
            # Tono de inicio oficial de la Shine Loop
            play tone at 587 Hz for 80 ms
            play tone at 880 Hz for 100 ms

        """

        let url = workspaceURL.appendingPathComponent("sample_loop_projects/\(name)")
        try? defaultCode.write(to: url, atomically: true, encoding: .utf8)
        loadWorkspace()
        openFile(url: url)
    }

    // MARK: - Native C++ Looping Execution via Subprocess
    public func runActiveFile() {
        guard let tab = activeTab else {
            terminalLogs.append("⚠️ No hay ningún archivo activo para ejecutar.")
            return
        }

        saveActiveFile()
        stopRunningProcess()

        isTerminalVisible = true
        terminalLogs = [
            "==================================================================",
            "⚡ [hiOP IDE STUDIO] Ejecutando: \(tab.title)",
            "▶ Destino: \(targetPlatform)",
            "▶ Motor: Looping C++ Native Engine v2.5.0",
            "=================================================================="
        ]

        let engineBinary = workspaceURL.appendingPathComponent("bin/looping").path
        guard FileManager.default.isExecutableFile(atPath: engineBinary) else {
            terminalLogs.append("❌ No se encontró el binario 'bin/looping'. Ejecuta 'make -C LoopingEngine/cpp'.")
            executionState = .failed(error: "bin/looping no encontrado")
            return
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: engineBinary)
        proc.arguments = [tab.url.path]
        proc.currentDirectoryURL = workspaceURL

        let stdout = Pipe()
        let stderr = Pipe()
        proc.standardOutput = stdout
        proc.standardError = stderr

        self.runningProcess = proc
        self.stdoutPipe = stdout
        self.stderrPipe = stderr

        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
            DispatchQueue.main.async {
                self?.terminalLogs.append(contentsOf: lines)
            }
        }

        stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
            DispatchQueue.main.async {
                self?.terminalLogs.append(contentsOf: lines.map { "⚠️ " + $0 })
            }
        }

        do {
            let start = Date()
            self.execStartTime = start
            try proc.run()

            self.executionState = .running(fileName: tab.title, pid: proc.processIdentifier)
            startTimer()

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                proc.waitUntilExit()
                let elapsed = Date().timeIntervalSince(start) * 1000.0
                let exitCode = proc.terminationStatus

                DispatchQueue.main.async {
                    self?.stopTimer()
                    self?.executionDurationMs = elapsed
                    self?.executionState = .completed(exitCode: exitCode, durationMs: elapsed)
                    self?.terminalLogs.append("──────────────────────────────────────────────────────────────────")
                    self?.terminalLogs.append(
                        exitCode == 0
                            ? "✅ [PROCESO FINALIZADO] Código 0 en \(String(format: "%.2f", elapsed))ms"
                            : "❌ [PROCESO TERMINADO CON ERROR] Código \(exitCode) en \(String(format: "%.2f", elapsed))ms"
                    )
                }
            }
        } catch {
            terminalLogs.append("❌ Error al invocar proceso: \(error.localizedDescription)")
            executionState = .failed(error: error.localizedDescription)
        }
    }

    public func stopRunningProcess() {
        stopTimer()
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil
        if let proc = runningProcess, proc.isRunning {
            proc.terminate()
            terminalLogs.append("⏹️ Proceso detenido por el usuario.")
        }
        runningProcess = nil
        stdoutPipe = nil
        stderrPipe = nil
        executionState = .idle
    }

    private func startTimer() {
        execTimer?.invalidate()
        execTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.execStartTime else { return }
            self.executionDurationMs = Date().timeIntervalSince(start) * 1000.0
        }
    }

    private func stopTimer() {
        execTimer?.invalidate()
        execTimer = nil
    }

    public func clearTerminal() {
        terminalLogs.removeAll()
    }

    deinit {
        stopRunningProcess()
    }
}
