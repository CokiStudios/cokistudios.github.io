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
            self.badgeText = "LOOPING 2.8"
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
    @Published public var appVersion: String = "2.8"
    @Published public var windowTitle: String = "Shine Loop OS: System Launcher & Dashboard"
    @Published public var windowSize: CGSize = CGSize(width: 800, height: 520)
    @Published public var theme: String = "frosted_aqua_a17"
    @Published public var uiProfile: String = "xui"
    @Published public var systemName: String = "Shine Loop Handheld Console"
    @Published public var kernelVersion: String = "Holo Looping OoS 1.0 (Linux Gaming Edition)"
    @Published public var runtimeEngine: String = "Ruuping & Looping Dual Hybrid Engine v2.8.0"
    @Published public var batteryLevel: Int = 98
    @Published public var activePlayer: String = "Angel Helium"
    @Published public var variables: [String: String] = [:]

    @Published public var headerCard: LoopCardItem? = nil
    @Published public var cards: [LoopCardItem] = []
    @Published public var footerCard: LoopCardItem? = nil
    @Published public var toneCommands: [LoopToneCommand] = []
    @Published public var scriptPrints: [String] = []

    public init() {}

    private func interpolate(_ text: String, vars: [String: String]) -> String {
        var result = text
        for (k, v) in vars {
            result = result.replacingOccurrences(of: "{\(k)}", with: v)
        }
        return result
    }

    private func applyVariable(key: String, val: String, into vars: inout [String: String]) {
        let cleaned = val.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
        vars[key] = cleaned
        switch key {
        case "theme": self.theme = cleaned
        case "ui_profile": self.uiProfile = cleaned
        case "system_name": self.systemName = cleaned
        case "kernel_ver", "kernel_version": self.kernelVersion = cleaned
        case "runtime_engine": self.runtimeEngine = cleaned
        case "battery_level":
            if let b = Int(cleaned.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                self.batteryLevel = b
            }
        case "active_player": self.activePlayer = cleaned
        default: break
        }
    }

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

    /// Evaluates .loop code lines directly (supporting both legacy and modern v2.8 signature syntax)
    public func parseLoopSource(_ code: String) {
        let lines = code.components(separatedBy: .newlines)

        var newCards: [LoopCardItem] = []
        var pendingCard: LoopCardItem? = nil
        var newTones: [LoopToneCommand] = []
        var newPrints: [String] = []
        var localVars: [String: String] = [:]

        var i = 0
        while i < lines.count {
            let rawLine = lines[i]
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            i += 1

            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("//") || line == "}" || line == "end" {
                continue
            }

            // 1. App definition: define app "<name>" version <ver> OR @app("Name", "2.8")
            if line.hasPrefix("define app") || line.hasPrefix("@app(") || line.hasPrefix("app(") {
                var extractedStrings: [String] = []
                let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
                if let regex = try? NSRegularExpression(pattern: "\"([^\"]+)\"") {
                    for m in regex.matches(in: line, range: nsRange) {
                        if let r = Range(m.range(at: 1), in: line) {
                            extractedStrings.append(String(line[r]))
                        }
                    }
                }
                if let first = extractedStrings.first {
                    self.appName = first
                }
                if extractedStrings.count >= 2 {
                    self.appVersion = extractedStrings[1]
                }
                continue
            }

            // 2. Window definition: create window with title "<title>" and size (w, h) OR window("Title", 800, 520) OR window.create(...)
            if line.hasPrefix("create window") || line.hasPrefix("window(") || line.hasPrefix("@window(") || line.hasPrefix("window.create(") {
                if let tMatch = line.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                    self.windowTitle = String(line[tMatch]).replacingOccurrences(of: "\"", with: "")
                }
                if let sMatch = line.range(of: "size\\s*\\((\\d+),\\s*(\\d+)\\)", options: .regularExpression) {
                    let sub = String(line[sMatch])
                    let numbers = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
                    if numbers.count >= 2, let w = Double(numbers[0]), let h = Double(numbers[1]) {
                        self.windowSize = CGSize(width: w, height: h)
                    }
                } else {
                    let numbers = line.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
                    if numbers.count >= 2, let w = Double(numbers[0]), let h = Double(numbers[1]), w >= 200, h >= 150 {
                        self.windowSize = CGSize(width: w, height: h)
                    }
                }
                continue
            }

            // 2b. Target UI & Profile: compile target "shine_ui" / target("xui") / profile("flui")
            if line.hasPrefix("compile target ") || line.hasPrefix("compile for ") ||
               line.hasPrefix("target(") || line.hasPrefix("@target(") ||
               line.hasPrefix("profile(") || line.hasPrefix("@profile(") {
                if let qRange = line.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                    let prof = String(line[qRange]).replacingOccurrences(of: "\"", with: "").lowercased()
                    self.uiProfile = prof
                    if prof.contains("shine") {
                        self.theme = "frosted_aqua_a17"
                    } else if prof.contains("xui") {
                        self.theme = "cyber_neon_xui"
                    } else if prof.contains("flui") {
                        self.theme = "aurora_indigo_fold"
                    }
                }
                continue
            }

            // 3. Variable declarations: set <var> to <val> OR let/mut/val/var x = val OR x := val
            if line.hasPrefix("set ") {
                let stripped = String(line.dropFirst(4))
                let parts = stripped.components(separatedBy: " to ")
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let val = parts[1].trimmingCharacters(in: .whitespaces)
                    applyVariable(key: key, val: val, into: &localVars)
                }
                continue
            }
            if line.hasPrefix("let ") || line.hasPrefix("mut ") || line.hasPrefix("val ") || line.hasPrefix("var ") {
                let stripped = String(line.dropFirst(4))
                if let eqIdx = stripped.firstIndex(of: "=") {
                    let key = String(stripped[..<eqIdx]).trimmingCharacters(in: .whitespaces)
                    let val = String(stripped[stripped.index(after: eqIdx)...]).trimmingCharacters(in: .whitespaces)
                    applyVariable(key: key, val: val, into: &localVars)
                }
                continue
            }
            if let walrusRange = line.range(of: ":=") {
                let key = String(line[..<walrusRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let val = String(line[walrusRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                applyVariable(key: key, val: val, into: &localVars)
                continue
            }

            // 4. Card directives: draw card at (x, y) ... OR ui.card(at: (x, y), size: (w, h), title: "...", text: "...")
            if line.hasPrefix("draw card") || line.hasPrefix("ui.card(") || line.hasPrefix("@ui::card(") || line.hasPrefix("card(") {
                var x = 0, y = 0, w = 240, h = 155
                var title = "Loop Card"
                var text = ""

                if let posMatch = line.range(of: "at:?\\s*\\((\\d+),\\s*(\\d+)\\)", options: .regularExpression) {
                    let sub = String(line[posMatch])
                    let nums = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
                    if nums.count >= 2 { x = Int(nums[0]) ?? 0; y = Int(nums[1]) ?? 0 }
                }

                if let sizeMatch = line.range(of: "size:?\\s*\\((\\d+),\\s*(\\d+)\\)", options: .regularExpression) {
                    let sub = String(line[sizeMatch])
                    let nums = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
                    if nums.count >= 2 { w = Int(nums[0]) ?? 240; h = Int(nums[1]) ?? 155 }
                }

                if let titleMatch = line.range(of: "title:?\\s*\"([^\"]+)\"", options: .regularExpression) {
                    let sub = String(line[titleMatch])
                    if let quote = sub.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                        title = interpolate(String(sub[quote]).replacingOccurrences(of: "\"", with: ""), vars: localVars)
                    }
                }

                if let textMatch = line.range(of: "text:?\\s*\"([^\"]+)\"", options: .regularExpression) {
                    let sub = String(line[textMatch])
                    if let quote = sub.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                        text = interpolate(
                            String(sub[quote]).replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "\\n", with: "\n"),
                            vars: localVars
                        )
                    }
                }

                let cardId = "card_\(newCards.count)_\(x)_\(y)"
                let card = LoopCardItem(id: cardId, x: x, y: y, width: w, height: h, title: title, text: text)

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

            // 5. Button directives: draw button at ... OR ui.btn(...) / ui.button(...) / insert button ...
            if line.hasPrefix("draw button") || line.hasPrefix("ui.btn(") || line.hasPrefix("ui.button(") ||
               line.hasPrefix("@ui::btn(") || line.hasPrefix("insert button") {
                var btnText = "INICIAR"
                var action = ""

                if let textMatch = line.range(of: "text:?\\s*\"([^\"]+)\"", options: .regularExpression) {
                    let sub = String(line[textMatch])
                    if let quote = sub.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                        btnText = String(sub[quote]).replacingOccurrences(of: "\"", with: "")
                    }
                } else if let firstQuote = line.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                    btnText = String(line[firstQuote]).replacingOccurrences(of: "\"", with: "")
                }

                if let actMatch = line.range(of: "action:?\\s*\"([^\"]+)\"", options: .regularExpression) {
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

            // 6. Audio tone directives: play tone at <freq> Hz for <duration> ms OR audio.tone(587, 80)
            if line.hasPrefix("play tone") || line.hasPrefix("audio.tone(") || line.hasPrefix("@audio::tone(") || line.hasPrefix("sound.tone(") {
                var freq: Double = 440.0
                var dur: Double = 80.0

                if line.hasPrefix("play tone") {
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
                } else {
                    let nums = line.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
                    if nums.count >= 1, let f = Double(nums[0]) { freq = f }
                    if nums.count >= 2, let d = Double(nums[1]) { dur = d }
                }

                newTones.append(LoopToneCommand(frequency: freq, durationMs: dur))
                continue
            }

            // 7. Output directives: print "..." / echo "..." / out(...) / print(...)
            if line.hasPrefix("print ") || line.hasPrefix("echo ") || line.hasPrefix("out ") ||
               line.hasPrefix("out(") || line.hasPrefix("print(") {
                var msg = line
                if msg.hasPrefix("out(") && msg.hasSuffix(")") {
                    msg = String(msg.dropFirst(4).dropLast(1))
                } else if msg.hasPrefix("print(") && msg.hasSuffix(")") {
                    msg = String(msg.dropFirst(6).dropLast(1))
                } else if msg.hasPrefix("print ") {
                    msg = String(msg.dropFirst(6))
                } else if msg.hasPrefix("echo ") {
                    msg = String(msg.dropFirst(5))
                } else if msg.hasPrefix("out ") {
                    msg = String(msg.dropFirst(4))
                }
                if msg.hasPrefix("$") {
                    msg = String(msg.dropFirst(1))
                }
                msg = msg.replacingOccurrences(of: "\"", with: "")
                msg = interpolate(msg, vars: localVars)
                newPrints.append(msg)
                continue
            }
        }

        if let pending = pendingCard {
            newCards.append(pending)
        }

        self.variables = localVars
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
