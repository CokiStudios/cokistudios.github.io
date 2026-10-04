import Foundation
import SwiftUI
import Combine

// MARK: - Dynamic UI Elements parsed directly from .loop code
public struct LoopCardItem: Identifiable, Equatable {
    public let id: String
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int
    public var title: String
    public var text: String
    public var action: String?
    public var buttonText: String?
    public var category: String
    public var iconSymbol: String
    public var primaryColorHex: String
    public var secondaryColorHex: String
    public var badgeText: String

    public init(
        id: String,
        x: Int = 0,
        y: Int = 0,
        width: Int = 240,
        height: Int = 155,
        title: String,
        text: String,
        action: String? = nil,
        buttonText: String? = nil
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.title = title
        self.text = text
        self.action = action
        self.buttonText = buttonText

        // Dynamic visual metadata derived from .loop title & text
        let lower = title.lowercased()
        if lower.contains("arcade") || lower.contains("game") {
            self.category = "Juegos"
            self.iconSymbol = "gamecontroller.fill"
            self.primaryColorHex = "00f5d4"
            self.secondaryColorHex = "0284c7"
            self.badgeText = "60 FPS NATIVE"
        } else if lower.contains("racing") || lower.contains("forkar") {
            self.category = "Juegos"
            self.iconSymbol = "car.side.fill"
            self.primaryColorHex = "f43f5e"
            self.secondaryColorHex = "ea580c"
            self.badgeText = "HOLO 3D MESH"
        } else if lower.contains("hiop") || lower.contains("ide") {
            self.category = "Desarrollo"
            self.iconSymbol = "chevron.left.forwardslash.chevron.right"
            self.primaryColorHex = "6366f1"
            self.secondaryColorHex = "8b5cf6"
            self.badgeText = "IDE NATIVO"
        } else if lower.contains("python") {
            self.category = "Desarrollo"
            self.iconSymbol = "cube.transparent.fill"
            self.primaryColorHex = "f59e0b"
            self.secondaryColorHex = "eab308"
            self.badgeText = "PYTORCH SYNC"
        } else if lower.contains("ruuping") || lower.contains("rust") {
            self.category = "Sistema"
            self.iconSymbol = "bolt.badge.automatic.fill"
            self.primaryColorHex = "ff6b6b"
            self.secondaryColorHex = "ee5253"
            self.badgeText = "1.4M OPS/S"
        } else if lower.contains("ajustes") || lower.contains("config") || lower.contains("sistema") {
            self.category = "Sistema"
            self.iconSymbol = "slider.horizontal.3"
            self.primaryColorHex = "64748b"
            self.secondaryColorHex = "475569"
            self.badgeText = "OVERCLOCK 120HZ"
        } else {
            self.category = "Holo Apps"
            self.iconSymbol = "sparkles"
            self.primaryColorHex = "38bdf8"
            self.secondaryColorHex = "6366f1"
            self.badgeText = "LOOPING 2.5"
        }
    }
}

// MARK: - Parsed Tone Command
public struct LoopToneCommand: Equatable {
    public let frequency: Double
    public let durationMs: Double
}

// MARK: - Looping Script Engine (Parses & Executes .loop file in Swift)
public final class LoopingScriptEngine: ObservableObject, @unchecked Sendable {
    @Published public var rawScriptSource: String = ""
    @Published public var scriptPath: String = ""

    // State populated dynamically from .loop script
    @Published public var appName: String = "ShineLauncher"
    @Published public var appVersion: String = "2.1"
    @Published public var windowTitle: String = "Shine Loop OS: System Launcher & Dashboard"
    @Published public var windowSize: CGSize = CGSize(width: 800, height: 520)
    @Published public var theme: String = "frosted_aqua_a17"
    @Published public var uiProfile: String = "xui"
    @Published public var systemName: String = "Shine Loop Handheld Console"
    @Published public var kernelVersion: String = "Holo Looping OoS 1.0 (Linux Gaming Edition)"
    @Published public var runtimeEngine: String = "Ruuping & Looping Dual Hybrid Engine v2.1.0"
    @Published public var batteryLevel: Int = 98
    @Published public var activePlayer: String = "Angel Helium"

    @Published public var headerCard: LoopCardItem? = nil
    @Published public var cards: [LoopCardItem] = []
    @Published public var footerCard: LoopCardItem? = nil
    @Published public var toneCommands: [LoopToneCommand] = []
    @Published public var scriptPrints: [String] = []

    public init() {}

    /// Loads and evaluates a .loop script file into live UI elements
    public func loadScript(from filePath: String) {
        let resolved = LoopingProcessRunner.resolveScriptPath(filePath)
        self.scriptPath = resolved

        guard let content = try? String(contentsOfFile: resolved, encoding: .utf8) else {
            self.scriptPrints.append("❌ Could not read script file: \(resolved)")
            return
        }

        self.rawScriptSource = content
        self.parseLoopSource(content)
    }

    /// Evaluates .loop code lines directly
    public func parseLoopSource(_ code: String) {
        let lines = code.components(separatedBy: .newlines)

        var newCards: [LoopCardItem] = []
        var pendingCard: LoopCardItem? = nil
        var newTones: [LoopToneCommand] = []
        var newPrints: [String] = []

        var i = 0
        while i < lines.count {
            let rawLine = lines[i]
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            i += 1

            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("//") {
                continue
            }

            // 1. define app "<name>" version <ver>:
            if line.hasPrefix("define app") {
                if let match = line.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                    self.appName = String(line[match]).replacingOccurrences(of: "\"", with: "")
                }
                continue
            }

            // 2. create window with title "<title>" and size (w, h)
            if line.hasPrefix("create window") {
                if let tMatch = line.range(of: "title\\s+\"([^\"]+)\"", options: .regularExpression) {
                    let sub = String(line[tMatch])
                    if let quoteRange = sub.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                        self.windowTitle = String(sub[quoteRange]).replacingOccurrences(of: "\"", with: "")
                    }
                }
                if let sMatch = line.range(of: "size\\s*\\((\\d+),\\s*(\\d+)\\)", options: .regularExpression) {
                    let sub = String(line[sMatch])
                    let numbers = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
                    if numbers.count >= 2, let w = Double(numbers[0]), let h = Double(numbers[1]) {
                        self.windowSize = CGSize(width: w, height: h)
                    }
                }
                continue
            }

            // 3. set <variable> to <val>
            if line.hasPrefix("set ") {
                let stripped = line.replacingOccurrences(of: "set ", with: "")
                let parts = stripped.components(separatedBy: " to ")
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let val = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")

                    switch key {
                    case "theme": self.theme = val
                    case "ui_profile": self.uiProfile = val
                    case "system_name": self.systemName = val
                    case "kernel_ver", "kernel_version": self.kernelVersion = val
                    case "runtime_engine": self.runtimeEngine = val
                    case "battery_level":
                        if let b = Int(val.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                            self.batteryLevel = b
                        }
                    case "active_player": self.activePlayer = val
                    default: break
                    }
                }
                continue
            }

            // 4. draw card at (x, y) with size (w, h) and title "..." and text "..."
            if line.hasPrefix("draw card at") {
                var x = 0, y = 0, w = 240, h = 155
                var title = "Loop Card"
                var text = ""

                // Extract coordinates
                if let posMatch = line.range(of: "at\\s*\\((\\d+),\\s*(\\d+)\\)", options: .regularExpression) {
                    let sub = String(line[posMatch])
                    let nums = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
                    if nums.count >= 2 { x = Int(nums[0]) ?? 0; y = Int(nums[1]) ?? 0 }
                }

                // Extract size
                if let sizeMatch = line.range(of: "size\\s*\\((\\d+),\\s*(\\d+)\\)", options: .regularExpression) {
                    let sub = String(line[sizeMatch])
                    let nums = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
                    if nums.count >= 2 { w = Int(nums[0]) ?? 240; h = Int(nums[1]) ?? 155 }
                }

                // Extract title
                if let titleMatch = line.range(of: "title\\s+\"([^\"]+)\"", options: .regularExpression) {
                    let sub = String(line[titleMatch])
                    if let quote = sub.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                        title = String(sub[quote]).replacingOccurrences(of: "\"", with: "")
                    }
                }

                // Extract text
                if let textMatch = line.range(of: "text\\s+\"([^\"]+)\"", options: .regularExpression) {
                    let sub = String(line[textMatch])
                    if let quote = sub.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                        text = String(sub[quote]).replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "\\n", with: "\n")
                    }
                }

                let cardId = "card_\(newCards.count)_\(x)_\(y)"
                let card = LoopCardItem(id: cardId, x: x, y: y, width: w, height: h, title: title, text: text)

                // Check if it's the header or footer
                if y < 50 && w > 500 {
                    self.headerCard = card
                } else if y > 400 && w > 500 {
                    self.footerCard = card
                } else {
                    if let pending = pendingCard {
                        newCards.append(pending)
                    }
                    pendingCard = card
                }
                continue
            }

            // 5. draw button at (x, y) with text "..." and action "..."
            if line.hasPrefix("draw button at") {
                var btnText = "INICIAR"
                var action = ""

                if let textMatch = line.range(of: "text\\s+\"([^\"]+)\"", options: .regularExpression) {
                    let sub = String(line[textMatch])
                    if let quote = sub.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                        btnText = String(sub[quote]).replacingOccurrences(of: "\"", with: "")
                    }
                }

                if let actMatch = line.range(of: "action\\s+\"([^\"]+)\"", options: .regularExpression) {
                    let sub = String(line[actMatch])
                    if let quote = sub.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                        action = String(sub[quote]).replacingOccurrences(of: "\"", with: "")
                    }
                }

                if var card = pendingCard {
                    card.buttonText = btnText
                    card.action = action
                    newCards.append(card)
                    pendingCard = nil
                }
                continue
            }

            // 6. play tone at <freq> Hz for <duration> ms
            if line.hasPrefix("play tone") {
                var freq: Double = 440.0
                var dur: Double = 80.0

                if let fMatch = line.range(of: "at\\s+(\\d+)\\s*Hz", options: .regularExpression) {
                    let sub = String(line[fMatch])
                    let nums = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
                    if let f = nums.first, let d = Double(f) { freq = d }
                }

                if let dMatch = line.range(of: "for\\s+(\\d+)\\s*ms", options: .regularExpression) {
                    let sub = String(line[dMatch])
                    let nums = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
                    if let f = nums.first, let d = Double(f) { dur = d }
                }

                newTones.append(LoopToneCommand(frequency: freq, durationMs: dur))
                continue
            }

            // 7. print "..."
            if line.hasPrefix("print ") || line.hasPrefix("echo ") {
                let msg = line.replacingOccurrences(of: "print ", with: "").replacingOccurrences(of: "\"", with: "")
                newPrints.append(msg)
                continue
            }
        }

        if let pending = pendingCard {
            newCards.append(pending)
        }

        self.cards = newCards
        self.toneCommands = newTones
        self.scriptPrints = newPrints

        // Play sound effects parsed directly from .loop script
        playScriptTones()
    }

    private func playScriptTones() {
        for (idx, tone) in toneCommands.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.08) {
                SoundSynthesizer.shared.playTone(
                    frequency: tone.frequency,
                    duration: tone.durationMs / 1000.0,
                    waveform: .sine
                )
            }
        }
    }
}
