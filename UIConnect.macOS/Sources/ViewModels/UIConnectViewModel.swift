import Foundation
import SwiftUI
import Combine

// MARK: - Main UI Connect ViewModel (Native macOS)
@MainActor
public final class UIConnectViewModel: ObservableObject {
    // Navigation
    public enum Tab: String, CaseIterable, Identifiable {
        case devices = "Dispositivos"
        case modules = "Módulos C2"
        case controls = "Controles APU"
        case looping = "Looping REPL"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .devices: return "iphone.gen3"
            case .modules: return "shippingbox.fill"
            case .controls: return "slider.horizontal.3"
            case .looping: return "bolt.fill"
            }
        }
    }

    @Published public var selectedTab: Tab = .devices

    // Devices & Modules State
    @Published public var devices: [ADBDevice] = []
    @Published public var selectedDevice: ADBDevice?
    @Published public var modules: [C2Module] = []
    @Published public var selectedModule: C2Module?
    @Published public var isScanning: Bool = false
    @Published public var isBusy: Bool = false

    // Reactive Controls
    @Published public var transferBufferKb: Double = 1024.0
    @Published public var hotReloadMs: Double = 150.0
    @Published public var autoSyncOnSave: Bool = true
    @Published public var vulkanApuMode: Bool = true
    @Published public var transmissionProgress: Double = 100.0

    // Looping Custom Code
    @Published public var customLoopCode: String = """
    val all_mods = ["cyber_neon_xui.c2", "aqua_nomad_ui.c2", "aurora_fold_flui.c2", "vintage_amber.c2", "feather_lite_hiui.c2", "custom_launcher.c2"]
    fn is_c2(x) => contains(x, ".c2")
    val verified = all_mods |> filter(is_c2)
    print $"[C2 AUDIT] Módulos validados con pipeline (|>) [{len(verified)}/6]:\\n{verified}"
    """

    private let adb = ADBService.shared
    private let c2Manager = C2ManagerService.shared
    private let looping = LoopingEngineService.shared
    private let ota = OTAService.shared
    private let audio = SoundSynthesizer.shared
    private let logger = LogManager.shared

    public init() {
        refreshAll()
    }

    public func refreshAll() {
        refreshDevices()
        refreshModules()
    }

    public func refreshDevices() {
        isScanning = true
        logger.log(.adb, "Iniciando escaneo de dispositivos Shine OS (USB y Wi-Fi)...")

        Task {
            let found = await adb.detectDevices()
            self.devices = found
            if self.selectedDevice == nil || !found.contains(where: { $0.serial == self.selectedDevice?.serial }) {
                self.selectedDevice = found.first
            }
            self.isScanning = false

            if found.isEmpty {
                self.logger.log(.adb, "No se detectaron celulares conectados. Verifica el cable USB o depuración ADB.")
            } else {
                let models = found.map { "\($0.displayName) [\($0.serial)]" }.joined(separator: ", ")
                self.logger.log(.adb, "Detectados \(found.count) dispositivo(s): \(models)")
                self.audio.playSuccess()
            }
        }
    }

    public func refreshModules() {
        let list = c2Manager.scanModules()
        self.modules = list
        if self.selectedModule == nil || !list.contains(where: { $0.fileName == self.selectedModule?.fileName }) {
            self.selectedModule = list.first
        }
        self.logger.log(.c2, "Escaneados \(list.count) módulos Component 2 en c2-modules/.")
    }

    // MARK: - Actions

    public func installSelectedModule() {
        guard let mod = selectedModule else {
            logger.log(.c2, "Selecciona un módulo .c2 primero.")
            audio.playWarning()
            return
        }

        isBusy = true
        transmissionProgress = 20.0
        audio.playApuChime()
        logger.log(.adb, "Iniciando transferencia de \(mod.fileName) (Buffer: \(Int(transferBufferKb)) KB/s)...")

        Task {
            transmissionProgress = 60.0
            let result = await adb.installModule(filePath: mod.filePath, serial: selectedDevice?.serial)
            transmissionProgress = 100.0
            isBusy = false

            switch result {
            case .success(let msg):
                self.logger.log(.adb, "✔ [INSTALACIÓN COMPONENT 2] \(msg)")
                self.audio.playSuccess()
            case .failure(let err):
                self.logger.log(.adb, "❌ [ERROR INSTALACIÓN] \(err.localizedDescription)")
                self.audio.playWarning()
            }
        }
    }

    public func publishSelectedModuleOTA() {
        guard let mod = selectedModule else {
            logger.log(.ota, "Selecciona un módulo .c2 primero.")
            audio.playWarning()
            return
        }

        isBusy = true
        transmissionProgress = 35.0
        audio.playApuChime()
        logger.log(.ota, "Subiendo \(mod.fileName) a Cloudflare Edge (\(ota.serverURL))...")

        Task {
            transmissionProgress = 80.0
            let res = await ota.publishModuleOTA(filePath: mod.filePath, deviceTarget: mod.targetDevice)
            transmissionProgress = 100.0
            isBusy = false

            switch res {
            case .success(let msg):
                self.logger.log(.ota, "✔ [CS WEBS OTA] \(msg)")
                self.audio.playSuccess()
            case .failure(let err):
                self.logger.log(.ota, "❌ [ERROR OTA] \(err.localizedDescription)")
                self.audio.playWarning()
            }
        }
    }

    public func runPipelineAudit() {
        isBusy = true
        audio.playApuChime()
        logger.log(.loop, "⚡ Ejecutando auditoría con operador pipeline Looping (|>) en tiempo real...")

        Task {
            let names = self.modules.map { $0.fileName }
            let output = await self.looping.auditC2ModulesViaPipeline(fileNames: names)
            self.logger.log(.c2, output)
            self.audio.playSuccess()
            self.isBusy = false
        }
    }

    public func runCustomLoopCode() {
        isBusy = true
        audio.playApuChime()
        logger.log(.loop, "⚡ Evaluando código en Looping Engine v2.5...")

        Task {
            let (code, stdout, stderr) = await self.looping.eval(code: self.customLoopCode)
            if code == 0 {
                let trimmed = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                self.logger.log(.loop, "[SALIDA LOOPING]:\n\(trimmed)")
                self.audio.playSuccess()
            } else {
                self.logger.log(.loop, "[ERROR LOOPING]:\n\(stderr)")
                self.audio.playWarning()
            }
            self.isBusy = false
        }
    }

    public func playApuAudioFeedback() {
        audio.playApuChime()
        logger.log(.audio, "Feedback acústico sintetizado en APU (880Hz / 1174Hz Tone Chime).")
    }

    public func rebootCurrentDevice() {
        guard let dev = selectedDevice else { return }
        logger.log(.adb, "Reiniciando dispositivo \(dev.displayName)...")
        audio.playApuChime()
        Task {
            let ok = await adb.rebootDevice(serial: dev.serial)
            if ok {
                self.logger.log(.adb, "Comando reboot enviado con éxito.")
                self.refreshDevices()
            }
        }
    }
}
