import SwiftUI
import Combine

// MARK: - View Mode
public enum ViewMode: String, CaseIterable {
    case carousel = "Carrusel 3D"
    case grid = "Cuadrícula"
}

// MARK: - Main Launcher State ViewModel (100% .loop Driven)
public final class LauncherViewModel: ObservableObject, @unchecked Sendable {
    // Looping Language Parser & Runtime
    @Published public var loopEngine = LoopingScriptEngine()
    @Published public var activeScriptFile: String = "sample_loop_projects/shine_launcher.loop"
    @Published public var isSourceEditorOpen: Bool = false

    // Apps Catalog (Generated 100% dynamically from .loop script)
    @Published public var allApps: [AppItem] = []
    @Published public var selectedCategory: AppCategory = .all
    @Published public var selectedIndex: Int = 0
    @Published public var viewMode: ViewMode = .carousel

    // Active Running Process & Execution Sheet
    @Published public var isRunningSheetPresented: Bool = false
    @Published public var activeLaunchedApp: AppItem? = nil
    @Published public var processRunner = LoopingProcessRunner()

    // Bubbly Dot Dynamic Island / Notch
    @Published public var isBubblyDotExpanded: Bool = false
    @Published public var bubblyDotTitle: String = "Holo Loop OS 1.0 • Shine Loop SL-101"
    @Published public var bubblyDotSubtext: String = "APU Zen Cuádruple • Vulkan Metal 120Hz"
    @Published public var bubblyDotIcon: String = "sparkles"
    @Published public var bubblyDotPulse: Bool = false

    // Hardware Telemetry & Overclock
    @Published public var batteryLevel: Int = 98
    @Published public var isCharging: Bool = true
    @Published public var wifiSsid: String = "Coki-Fiber-5G"
    @Published public var wifiPingMs: Int = 8
    @Published public var cpuLoadPercent: Int = 24
    @Published public var ramUsedGb: Double = 1.4
    @Published public var totalRamGb: Double = 4.0
    @Published public var storageUsedGb: Double = 64.2
    @Published public var totalStorageGb: Double = 512.0
    @Published public var currentTimeString: String = "18:55"
    @Published public var performanceProfile: PerformanceProfile = .turbo

    // Settings Drawer & Customization
    @Published public var isSettingsDrawerOpen: Bool = false
    @Published public var isHandheldBezelEnabled: Bool = false
    @Published public var isCrtScanlinesEnabled: Bool = false
    @Published public var soundVolume: Float = 0.85 {
        didSet {
            SoundSynthesizer.shared.volume = soundVolume
        }
    }
    @Published public var isSoundMuted: Bool = false {
        didSet {
            SoundSynthesizer.shared.isMuted = isSoundMuted
        }
    }

    private var telemetryTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    public var filteredApps: [AppItem] {
        if selectedCategory == .all {
            return allApps
        }
        return allApps.filter { $0.category == selectedCategory.rawValue }
    }

    public var selectedApp: AppItem? {
        let list = filteredApps
        guard !list.isEmpty else { return nil }
        let validIndex = min(max(selectedIndex, 0), list.count - 1)
        return list[validIndex]
    }

    public init() {
        loadCatalogFromLoopScript()
        setupControllerListener()
        startTelemetryLoop()
        updateTimeString()

        // Play initial boot chime after small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            SoundSynthesizer.shared.playBootChime()
        }
    }

    // MARK: - 100% .loop Driven UI Loader
    public func loadCatalogFromLoopScript() {
        loopEngine.loadScript(from: activeScriptFile)

        // Read variables declared in .loop code
        self.batteryLevel = loopEngine.batteryLevel
        self.bubblyDotTitle = "\(loopEngine.appName) // \(loopEngine.systemName)"
        self.bubblyDotSubtext = "Kernel: \(loopEngine.kernelVersion) • \(loopEngine.runtimeEngine)"

        // Map parsed cards from .loop into interactive app items
        var apps: [AppItem] = []
        for card in loopEngine.cards {
            let target = resolveActionTarget(action: card.action)

            // Extract specs from text
            var specs: [(key: String, value: String)] = []
            let lines = card.text.components(separatedBy: "\n")
            for line in lines {
                if line.contains(":") {
                    let parts = line.components(separatedBy: ":")
                    if parts.count >= 2 {
                        let k = parts[0].trimmingCharacters(in: .whitespaces)
                        let v = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                        specs.append((key: k, value: v))
                    }
                }
            }

            if specs.isEmpty {
                specs = [
                    ("Motor", "Looping C++ Native"),
                    ("Lenguaje", "100% .loop Script"),
                    ("Consola", "Shine Loop Handheld")
                ]
            }

            let subtitle = lines.first ?? "Aplicación Holo Loop OS"

            apps.append(
                AppItem(
                    id: card.id,
                    title: card.title,
                    subtitle: subtitle,
                    category: card.category,
                    iconSymbol: card.iconSymbol,
                    primaryColorHex: card.primaryColorHex,
                    secondaryColorHex: card.secondaryColorHex,
                    badgeText: card.badgeText,
                    summary: card.text,
                    releaseDate: "2026",
                    techSpecs: specs,
                    target: target,
                    sizeMb: Double(card.width) / 10.0
                )
            )
        }

        self.allApps = apps
    }

    private func resolveActionTarget(action: String?) -> LaunchTarget {
        guard let action = action else { return .systemSettings }
        switch action {
        case "launch_arcade":
            return .loopScript(relativeOrAbsolutePath: "sample_loop_projects/arcade.loop")
        case "launch_hiop":
            return .nativeApp(appBundleOrPath: "hiOP.macOS/build/Build/Products/Release/hiOP.app", fallbackUrl: nil)
        case "launch_python":
            return .loopScript(relativeOrAbsolutePath: "sample_loop_projects/python_interop_demo.loop")
        case "launch_forkar":
            return .loopScript(relativeOrAbsolutePath: "sample_loop_projects/signature_demo.loop")
        case "launch_ruuping":
            return .loopScript(relativeOrAbsolutePath: "sample_loop_projects/ruuping_demo.ruup")
        case "launch_settings":
            return .systemSettings
        default:
            return .loopScript(relativeOrAbsolutePath: "sample_loop_projects/\(action).loop")
        }
    }

    public func saveAndReloadScript(editedCode: String) {
        let resolved = LoopingProcessRunner.resolveScriptPath(activeScriptFile)
        try? editedCode.write(toFile: resolved, atomically: true, encoding: .utf8)
        loadCatalogFromLoopScript()
        SoundSynthesizer.shared.playActionBlip()
    }

    // MARK: - Controller Integration
    private func setupControllerListener() {
        GameControllerManager.shared.onAction = { [weak self] action in
            guard let self = self else { return }

            if self.isRunningSheetPresented {
                if action == .buttonB { self.closeRunningApp() }
                return
            }

            if self.isSettingsDrawerOpen {
                if action == .buttonB || action == .menuButton { self.toggleSettings() }
                return
            }

            if self.isSourceEditorOpen {
                if action == .buttonB { self.isSourceEditorOpen = false }
                return
            }

            switch action {
            case .dpadLeft: self.selectPrevious()
            case .dpadRight: self.selectNext()
            case .dpadUp: self.selectUp()
            case .dpadDown: self.selectDown()
            case .buttonA:
                if let selected = self.selectedApp {
                    self.launchApp(selected)
                }
            case .buttonB:
                SoundSynthesizer.shared.playBackTick()
                if self.isBubblyDotExpanded { self.isBubblyDotExpanded = false }
            case .buttonX: self.toggleViewMode()
            case .buttonY: self.toggleBubblyDot()
            case .shoulderLeft: self.previousCategory()
            case .shoulderRight: self.nextCategory()
            case .menuButton: self.toggleSettings()
            }
        }
    }

    // MARK: - Telemetry & Clock Simulation
    private func startTelemetryLoop() {
        telemetryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateTimeString()

            let variation = Int.random(in: -4...5)
            self.cpuLoadPercent = min(max(self.cpuLoadPercent + variation, 14), 68)
            self.wifiPingMs = Int.random(in: 6...12)
        }
    }

    private func updateTimeString() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        self.currentTimeString = formatter.string(from: Date())
    }

    // MARK: - Navigation Actions
    public func selectNext() {
        let count = filteredApps.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + 1) % count
        SoundSynthesizer.shared.playNavTick()
        updateBubblyDotPreview()
    }

    public func selectPrevious() {
        let count = filteredApps.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex - 1 + count) % count
        SoundSynthesizer.shared.playNavTick()
        updateBubblyDotPreview()
    }

    public func selectUp() {
        let count = filteredApps.count
        guard count > 0 else { return }
        if viewMode == .grid {
            let cols = 3
            if selectedIndex - cols >= 0 {
                selectedIndex -= cols
                SoundSynthesizer.shared.playNavTick()
                updateBubblyDotPreview()
            }
        }
    }

    public func selectDown() {
        let count = filteredApps.count
        guard count > 0 else { return }
        if viewMode == .grid {
            let cols = 3
            if selectedIndex + cols < count {
                selectedIndex += cols
                SoundSynthesizer.shared.playNavTick()
                updateBubblyDotPreview()
            }
        }
    }

    public func selectApp(at index: Int) {
        guard index >= 0 && index < filteredApps.count else { return }
        selectedIndex = index
        SoundSynthesizer.shared.playNavTick()
        updateBubblyDotPreview()
    }

    public func nextCategory() {
        let allCases = AppCategory.allCases
        if let currentIdx = allCases.firstIndex(of: selectedCategory) {
            let nextIdx = (currentIdx + 1) % allCases.count
            selectedCategory = allCases[nextIdx]
            selectedIndex = 0
            SoundSynthesizer.shared.playActionBlip()
        }
    }

    public func previousCategory() {
        let allCases = AppCategory.allCases
        if let currentIdx = allCases.firstIndex(of: selectedCategory) {
            let prevIdx = (currentIdx - 1 + allCases.count) % allCases.count
            selectedCategory = allCases[prevIdx]
            selectedIndex = 0
            SoundSynthesizer.shared.playActionBlip()
        }
    }

    public func toggleViewMode() {
        viewMode = (viewMode == .carousel) ? .grid : .carousel
        SoundSynthesizer.shared.playActionBlip()
    }

    public func toggleSettings() {
        isSettingsDrawerOpen.toggle()
        SoundSynthesizer.shared.playNavTick()
    }

    public func toggleBubblyDot() {
        isBubblyDotExpanded.toggle()
        SoundSynthesizer.shared.playActionBlip()
    }

    private func updateBubblyDotPreview() {
        guard let app = selectedApp else { return }
        bubblyDotTitle = app.title
        bubblyDotSubtext = "\(app.badgeText) • \(app.subtitle)"
        bubblyDotIcon = app.iconSymbol
    }

    // MARK: - Launching Apps & Execution
    public func launchApp(_ item: AppItem) {
        SoundSynthesizer.shared.playLaunchChime()

        switch item.target {
        case .loopScript(let scriptPath):
            self.activeLaunchedApp = item
            self.isRunningSheetPresented = true
            self.processRunner.execute(scriptPath: scriptPath, appName: item.title)

        case .systemSettings:
            self.isSettingsDrawerOpen = true

        case .nativeApp(let appPath, _):
            let fileManager = FileManager.default
            let resolved = LoopingProcessRunner.resolveScriptPath(appPath)
            if fileManager.fileExists(atPath: resolved) {
                NSWorkspace.shared.open(URL(fileURLWithPath: resolved))
            } else {
                self.activeLaunchedApp = item
                self.isRunningSheetPresented = true
                self.processRunner.outputLines = [
                    "⚡ [LAUNCHING NATIVE APP] '\(item.title)'",
                    "Target path: \(resolved)",
                    "⚠️ Native app bundle not found at path."
                ]
            }

        case .webCore(let webPath):
            let resolved = LoopingProcessRunner.resolveScriptPath(webPath)
            if FileManager.default.fileExists(atPath: resolved) {
                NSWorkspace.shared.open(URL(fileURLWithPath: resolved))
            }
        }
    }

    public func closeRunningApp() {
        SoundSynthesizer.shared.playBackTick()
        processRunner.stop()
        isRunningSheetPresented = false
        activeLaunchedApp = nil
    }

    deinit {
        telemetryTimer?.invalidate()
        telemetryTimer = nil
    }
}
