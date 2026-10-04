import SwiftUI
import Combine

// MARK: - View Mode
public enum ViewMode: String, CaseIterable {
    case carousel = "Carrusel 3D"
    case grid = "Cuadrícula"
}

// MARK: - Main Launcher State ViewModel
public final class LauncherViewModel: ObservableObject, @unchecked Sendable {
    // Apps Catalog
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
        loadCatalog()
        setupControllerListener()
        startTelemetryLoop()
        updateTimeString()

        // Play initial boot chime after small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            SoundSynthesizer.shared.playBootChime()
        }
    }

    // MARK: - System Apps Catalog Definition
    private func loadCatalog() {
        self.allApps = [
            AppItem(
                id: "holo_arcade_2d",
                title: "Holo Arcade 2D",
                subtitle: "Cyberpunk 2D Retro Platformer",
                category: "Juegos",
                iconSymbol: "gamecontroller.fill",
                primaryColorHex: "00f5d4",
                secondaryColorHex: "0284c7",
                badgeText: "60 FPS NATIVE",
                summary: "Plataformero 2D retro optimizado con física cuántica a 60Hz. Corre y esquiva obstáculos mientras recolectas estrellas cuánticas y destruyes a los Corrupted Forkbots.",
                releaseDate: "2026.1",
                techSpecs: [
                    ("Motor", "Looping 2D Sprite Core"),
                    ("Física", "Sub-ms 60Hz Collider"),
                    ("Resolución", "1280x800 @ 60 FPS"),
                    ("Audio", "Hardware Square Tone DSP")
                ],
                target: .loopScript(relativeOrAbsolutePath: "sample_loop_projects/arcade.loop"),
                sizeMb: 14.8
            ),
            AppItem(
                id: "forkar_racing_3d",
                title: "Forkar Racing 3D",
                subtitle: "Cyberpunk High-Speed Karting",
                category: "Juegos",
                iconSymbol: "car.side.fill",
                primaryColorHex: "f43f5e",
                secondaryColorHex: "ea580c",
                badgeText: "HOLO 3D MESH",
                summary: "Carreras futuristas de karts en autopistas de Neo-Coki. Física aerodinámica 3D, pistas de gravedad cero, multijugador local por red y efectos de partículas de plasma.",
                releaseDate: "2026.2",
                techSpecs: [
                    ("Física", "Holo 3D Aerodynamics"),
                    ("Pistas", "Neo-Coki Skyline Zero-G"),
                    ("Multijugador", "P2P Local Mesh 4P"),
                    ("Hápticos", "Direct Gamepad Rumble")
                ],
                target: .webCore(localPathOrUrl: "forkar.html"),
                sizeMb: 86.4
            ),
            AppItem(
                id: "hiop_studio_ide",
                title: "hiOP Studio IDE",
                subtitle: "Entorno de Desarrollo Looping",
                category: "Desarrollo",
                iconSymbol: "chevron.left.forwardslash.chevron.right",
                primaryColorHex: "6366f1",
                secondaryColorHex: "8b5cf6",
                badgeText: "MONACO CORE",
                summary: "El entorno de desarrollo oficial para crear aplicaciones y videojuegos en Looping v2.5. Incluye resaltado de sintaxis, autocompletado y compilador instantáneo C++.",
                releaseDate: "2026.3",
                techSpecs: [
                    ("Editor", "Embedded Monaco Engine"),
                    ("Compilador", "Looping C++ Native v2.5"),
                    ("Targets", "Shine Loop / macOS / APK"),
                    ("Preview", "Live 60Hz Interactive HUD")
                ],
                target: .nativeApp(appBundleOrPath: "hiOP.macOS/build/Build/Products/Release/hiOP.app", fallbackUrl: "hiop-ide.html"),
                sizeMb: 42.1
            ),
            AppItem(
                id: "cybershine_core_v25",
                title: "CyberShine Core v2.5",
                subtitle: "Demostración de Sintaxis Looping 2.5",
                category: "Desarrollo",
                iconSymbol: "infinity",
                primaryColorHex: "14b8a6",
                secondaryColorHex: "10b981",
                badgeText: "SUB-MS C++",
                summary: "Demostración integral de la nueva sintaxis: pipelines `|>`, arrow functions `->`, bucles `loop (N)`, tipado `val/mut`, macro `py!` y directivas de hardware en tiempo real.",
                releaseDate: "2026.4",
                techSpecs: [
                    ("Compilador", "C++17 Standalone Engine"),
                    ("Latencia", "< 0.45 ms por ciclo"),
                    ("Pipelines", "math.sqrt |> scale"),
                    ("Notch", "Bubbly Dot Dynamic Island")
                ],
                target: .loopScript(relativeOrAbsolutePath: "sample_loop_projects/signature_demo.loop"),
                sizeMb: 5.2
            ),
            AppItem(
                id: "python_interop_bridge",
                title: "Python Interop Bridge",
                subtitle: "PySync 3.12+ Zero-Copy Shared Memory",
                category: "Desarrollo",
                iconSymbol: "cube.transparent.fill",
                primaryColorHex: "f59e0b",
                secondaryColorHex: "eab308",
                badgeText: "PYTORCH SYNC",
                summary: "Puente bidireccional entre Looping y Python. Ejecuta librerías como NumPy, SciPy y modelos de Machine Learning compartiendo buffers de memoria sin serialización lenta.",
                releaseDate: "2026.1",
                techSpecs: [
                    ("Puente", "PySync C-API 3.12+"),
                    ("Memoria", "Zero-Copy Direct IPC"),
                    ("Librerías", "NumPy, SciPy, Torch"),
                    ("Hilos", "Multi-Core Asíncrono")
                ],
                target: .loopScript(relativeOrAbsolutePath: "sample_loop_projects/python_interop_demo.loop"),
                sizeMb: 8.9
            ),
            AppItem(
                id: "ruuping_rust_core",
                title: "Ruuping Rust Core",
                subtitle: "Motor Nativo Ultra-Rápido 100% Rust",
                category: "Sistema",
                iconSymbol: "bolt.badge.automatic.fill",
                primaryColorHex: "ff6b6b",
                secondaryColorHex: "ee5253",
                badgeText: "1.4M OPS/S",
                summary: "Núcleo de sistema en Rust diseñado para tareas críticas de renderizado y audio. Alcanza más de 1.4 millones de instrucciones por segundo con seguridad de memoria garantizada.",
                releaseDate: "2026.2",
                techSpecs: [
                    ("Lenguaje", "Rust 2024 Edition"),
                    ("Throughput", "1,420,000 Ops/sec"),
                    ("Latencia", "0.12 ms"),
                    ("Seguridad", "100% Safe Memory / Zero GC")
                ],
                target: .loopScript(relativeOrAbsolutePath: "sample_loop_projects/ruuping_demo.ruup"),
                sizeMb: 18.3
            ),
            AppItem(
                id: "csms_encrypted_chat",
                title: "CSMS Encrypted Chat",
                subtitle: "Hardware-Backed Party Voice & Chat",
                category: "Comunidad",
                iconSymbol: "bubble.left.and.bubble.right.fill",
                primaryColorHex: "06b6d4",
                secondaryColorHex: "0ea5e9",
                badgeText: "E2EE SECURE",
                summary: "Servicio de mensajería y chat de voz cifrado para partidas multijugador. Protegido por el Secure Enclave del hardware con claves AES-256-GCM derivadas de sala.",
                releaseDate: "2026.3",
                techSpecs: [
                    ("Cifrado", "AES-256-GCM Hardware-Backed"),
                    ("Enclave", "Apple T2 / Secure Enclave"),
                    ("Formato", "🔒 enc:v1:<iv>:<ciphertext>"),
                    ("Voz", "Opus Low-Latency Spatial")
                ],
                target: .webCore(localPathOrUrl: "messenger.html"),
                sizeMb: 24.5
            ),
            AppItem(
                id: "system_hardware_settings",
                title: "Ajustes y Hardware",
                subtitle: "Panel de Configuración de la Consola",
                category: "Sistema",
                iconSymbol: "slider.horizontal.3",
                primaryColorHex: "64748b",
                secondaryColorHex: "475569",
                badgeText: "120HZ DISPLAY",
                summary: "Gestiona los perfiles de energía (Eco, Normal, Turbo Overclock), resolución de pantalla, calibración de sticks del mando, audio DSP y almacenamiento NVMe LoopFS.",
                releaseDate: "2026.1",
                techSpecs: [
                    ("Pantalla", "1280x800 OLED HDR 120Hz"),
                    ("APU", "Quad-Core Zen Low-Latency"),
                    ("NVMe", "512GB Fast LoopFS v2.0"),
                    ("Audio", "DSP 48kHz Stereo Surround")
                ],
                target: .systemSettings,
                sizeMb: 4.1
            )
        ]
    }

    // MARK: - Controller Integration
    private func setupControllerListener() {
        GameControllerManager.shared.onAction = { [weak self] action in
            guard let self = self else { return }

            if self.isRunningSheetPresented {
                // If game execution sheet is active, button B closes it
                if action == .buttonB {
                    self.closeRunningApp()
                }
                return
            }

            if self.isSettingsDrawerOpen {
                if action == .buttonB || action == .menuButton {
                    self.toggleSettings()
                }
                return
            }

            switch action {
            case .dpadLeft:
                self.selectPrevious()
            case .dpadRight:
                self.selectNext()
            case .dpadUp:
                self.selectUp()
            case .dpadDown:
                self.selectDown()
            case .buttonA:
                if let selected = self.selectedApp {
                    self.launchApp(selected)
                }
            case .buttonB:
                SoundSynthesizer.shared.playBackTick()
                if self.isBubblyDotExpanded {
                    self.isBubblyDotExpanded = false
                }
            case .buttonX:
                self.toggleViewMode()
            case .buttonY:
                self.toggleBubblyDot()
            case .shoulderLeft:
                self.previousCategory()
            case .shoulderRight:
                self.nextCategory()
            case .menuButton:
                self.toggleSettings()
            }
        }
    }

    // MARK: - Telemetry & Clock Simulation
    private func startTelemetryLoop() {
        telemetryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateTimeString()

            // Simulate slight APU load fluctuations
            let variation = Int.random(in: -4...5)
            self.cpuLoadPercent = min(max(self.cpuLoadPercent + variation, 14), 68)

            // Random ping jitter (6ms - 12ms)
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

        case .nativeApp(let appPath, let fallbackUrl):
            let fileManager = FileManager.default
            let resolved = LoopingProcessRunner.resolveScriptPath(appPath)
            if fileManager.fileExists(atPath: resolved) {
                NSWorkspace.shared.open(URL(fileURLWithPath: resolved))
            } else if let fallback = fallbackUrl {
                openFallbackWebPage(fallback)
            } else {
                self.activeLaunchedApp = item
                self.isRunningSheetPresented = true
                self.processRunner.outputLines = [
                    "⚡ [LAUNCHING NATIVE TARGET] '\(item.title)'",
                    "Target path: \(resolved)",
                    "⚠️ Native app bundle not found. Building with Xcode or run_hiop.sh recommended."
                ]
            }

        case .webCore(let webPath):
            openFallbackWebPage(webPath)
        }
    }

    private func openFallbackWebPage(_ path: String) {
        let fileManager = FileManager.default
        let resolved = LoopingProcessRunner.resolveScriptPath(path)
        if fileManager.fileExists(atPath: resolved) {
            NSWorkspace.shared.open(URL(fileURLWithPath: resolved))
        } else if let remote = URL(string: "https://cokistudios.com/" + path) {
            NSWorkspace.shared.open(remote)
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
