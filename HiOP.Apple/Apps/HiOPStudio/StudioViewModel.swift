import Foundation
import HiOPCore
import SwiftUI

#if os(macOS)
import AppKit
#endif

@MainActor
public final class StudioViewModel: ObservableObject {
    @Published public var selectedSection: StudioSection = .ide
    @Published public var tabs: [EditorTab] = []
    @Published public var activeTabID: UUID?
    @Published public var astNodes: [AstNodeItem] = []
    @Published public var diagnostics: [DiagnosticItem] = []
    @Published public var consoleLogs: [String] = []
    @Published public var activeChannel: LoopingChannel = .prod
    @Published public var colorSchemePreference: Int = 0 // 0=System, 1=Dark, 2=Light

    // Live Stage
    @Published public var stageSnapshot = StageSnapshot()
    @Published public var stageUI = StageUiSnapshot()
    @Published public var stageImage: CGImage?
    @Published public var isStageRunning: Bool = false
    @Published public var activeInputMask: StageInputMask = []

    // Smiledev & Updates
    @Published public var liveModules: [SmileModuleItem] = []
    @Published public var modulesLoading = false
    @Published public var modulesError: String?
    @Published public var latestManifest: EngineLatestManifest?
    @Published public var manifestSource: String = ""
    @Published public var updatesLoading = false
    @Published public var updateStatusText = "Pulsa comprobar para consultar engine.cokistudios.com/latest.json"

    // Toolchain
    @Published public var doctorChecks: [DoctorCheckItem] = []
    @Published public var toolchainOutput: String = ""

    public let engineBridge = LoopingCoreBridge()
    private let registryService = SmiledevRegistryService()
    private let updateService = EngineUpdateService()
    private var stageTimer: Timer?

    public enum StudioSection: String, CaseIterable, Identifiable {
        case ide = "IDE Studio"
        case stage = "Quantum Stage"
        case toolchain = "Toolchain 3.1A"
        case smiledev = "Smiledev"
        case updates = "Actualizaciones"
        case settings = "Ajustes"

        public var id: String { rawValue }
        public var icon: String {
            switch self {
            case .ide: return "chevron.left.forwardslash.chevron.right"
            case .stage: return "cube.transparent"
            case .toolchain: return "wrench.and.screwdriver"
            case .smiledev: return "shippingbox"
            case .updates: return "arrow.down.circle"
            case .settings: return "gearshape"
            }
        }
    }

    public init() {
        let initial = WorkspaceTemplates.arch31APresets[0]
        let firstTab = EditorTab(title: initial.fileName, content: initial.code)
        tabs = [firstTab]
        activeTabID = firstTab.id
        reanalyzeActiveTab()
        refreshDoctor()
    }

    public var activeTab: EditorTab? {
        tabs.first(where: { $0.id == activeTabID }) ?? tabs.first
    }

    public func updateActiveCode(_ newCode: String) {
        guard let idx = tabs.firstIndex(where: { $0.id == (activeTabID ?? tabs.first?.id) }) else { return }
        tabs[idx].content = newCode
        tabs[idx].isDirty = true
        reanalyzeActiveTab()
    }

    public func openPreset(_ preset: TemplatePreset) {
        if let existing = tabs.first(where: { $0.title == preset.fileName }) {
            activeTabID = existing.id
        } else {
            let tab = EditorTab(title: preset.fileName, content: preset.code)
            tabs.append(tab)
            activeTabID = tab.id
        }
        reanalyzeActiveTab()
    }

    public func openFile(url: URL, content: String) {
        if let existing = tabs.first(where: { $0.fileURL == url }) {
            activeTabID = existing.id
            reanalyzeActiveTab()
            return
        }
        let tab = EditorTab(title: url.lastPathComponent, fileURL: url, content: content, isDirty: false)
        tabs.append(tab)
        activeTabID = tab.id
        reanalyzeActiveTab()
    }

    public func closeTab(_ id: UUID) {
        tabs.removeAll(where: { $0.id == id })
        if activeTabID == id {
            activeTabID = tabs.first?.id
        }
        reanalyzeActiveTab()
    }

    public func reanalyzeActiveTab() {
        let code = activeTab?.content ?? ""
        astNodes = LoopingBuiltInAnalyzer.buildAst(code)
        diagnostics = LoopingBuiltInAnalyzer.checkCode(code)
    }

    public func runActiveCode(openStageIfVisual: Bool = false) {
        guard let tab = activeTab else { return }
        consoleLogs = ["[hiOP Studio] Ejecutando \(tab.title) en CLoopingStageCore (C++17 + ASM)..."]
        let res = engineBridge.execute(code: tab.content, channel: activeChannel)
        if !res.logs.isEmpty {
            consoleLogs.append(contentsOf: res.logs)
        }
        consoleLogs.append(res.ok
            ? String(format: "[OK] Completado en %.2f ms (3D=%@)", res.elapsedMs, res.is3DMode ? "true" : "false")
            : "[ERROR] Fallo en ejecución")

        stageSnapshot = engineBridge.snapshot(viewWidth: 640, viewHeight: 380)
        stageUI = engineBridge.uiSnapshot()
        stageImage = engineBridge.renderStageCGImage(snapshot: stageSnapshot, width: 640, height: 380)

        if openStageIfVisual || res.is3DMode || !stageSnapshot.entities.isEmpty || !stageUI.cards.isEmpty {
            if openStageIfVisual {
                selectedSection = .stage
            }
            startStageLoop()
        }
    }

    public func formatActiveCode() {
        guard let tab = activeTab else { return }
        let formatted = engineBridge.formatCode(tab.content)
        if !formatted.isEmpty {
            updateActiveCode(formatted)
            consoleLogs.append("[FMT] Código formateado con Looping Engine.")
        }
    }

    public func encodeActiveInvis() {
        guard let tab = activeTab else { return }
        let inv = engineBridge.encodeInvisHex(tab.content, target: "metal4")
        let msg = inv.valid
            ? "[Invis LPBN v3.0A] \(inv.byteLength) bytes | hex: \(inv.hex.prefix(64))..."
            : "[Invis LPBN] Error compilando bytecode"
        consoleLogs.append(msg)
        toolchainOutput = msg
    }

    public func startStageLoop() {
        stageTimer?.invalidate()
        isStageRunning = true
        stageTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickStage()
            }
        }
    }

    public func stopStageLoop() {
        stageTimer?.invalidate()
        stageTimer = nil
        isStageRunning = false
    }

    public func tickStage() {
        engineBridge.setInput(activeInputMask)
        let snap = engineBridge.step(dt: 1.0 / 60.0, viewWidth: 640, viewHeight: 380)
        stageSnapshot = snap
        stageImage = engineBridge.renderStageCGImage(snapshot: snap, width: 640, height: 380)
    }

    public func refreshDoctor() {
        let ver = engineBridge.versionJSON()
        let digest = String(format: "0x%llx", engineBridge.asmDigest(for: ver))
        #if os(macOS)
        let platformName = "macOS Nativo (Universal Apple Silicon / Intel)"
        #else
        let platformName = "iPadOS / iOS Nativo (Sandbox Seguro)"
        #endif
        doctorChecks = [
            DoctorCheckItem(component: "Motor C++17 Embebido", status: "OK", detail: "CLoopingStageCore activo in-process (Zero Python, Zero WebView)", hint: "Arch 3.1A"),
            DoctorCheckItem(component: "Núcleo Assembly", status: "OK", detail: "ARM64/x86_64 framebuffer & FNV-1a activo (\(digest))"),
            DoctorCheckItem(component: "Plataforma Apple", status: "OK", detail: platformName),
            DoctorCheckItem(component: "Canal Activo", status: "OK", detail: "\(activeChannel.displayName) — \(activeChannel.tierLabel)")
        ]
    }

    public func runToolchainSelfTest() {
        let st = engineBridge.runSelfTest()
        let lines = st.tests.map { "\($0.passed ? "✔" : "✘") \($0.name)" }.joined(separator: "\n")
        toolchainOutput = String(format: "SelfTest: %d/%d passed (%.2f ms)\n%@", st.passed, st.total, st.elapsedMs, lines)
    }

    public func runToolchainBench() {
        let b = engineBridge.benchmarkVM()
        toolchainOutput = String(format: "VM Benchmark (%d iters): %.2f ms | acc=%d | sha256=%@", b.iterations, b.ms, b.acc, b.sha256)
    }

    public func loadSmiledevModules() async {
        modulesLoading = true
        modulesError = nil
        do {
            liveModules = try await registryService.fetchLiveModules()
        } catch {
            modulesError = "No se pudo consultar repo.cokistudios.com/modules: \(error.localizedDescription)"
        }
        modulesLoading = false
    }

    public func checkUpdates() async {
        updatesLoading = true
        do {
            let res = try await updateService.fetchLatestManifest()
            latestManifest = res.manifest
            manifestSource = res.sourceURL.absoluteString
            updateStatusText = "Conectado a \(res.sourceURL.host ?? "engine.cokistudios.com") • v\(res.manifest.version ?? "1.1.2") (Arch \(res.manifest.arch_version ?? "3.1A"))"
        } catch {
            updateStatusText = "Error consultando manifiesto: \(error.localizedDescription)"
        }
        updatesLoading = false
    }
}
