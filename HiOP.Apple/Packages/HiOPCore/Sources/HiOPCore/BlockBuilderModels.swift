import Foundation

public enum BlockCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case program = "Programa & Lógica"
    case ui = "Ventana & UI"
    case game2d = "Juego 2D"
    case quantum3d = "Quantum 3D"
    case ecosystem = "Ecosistema CS"

    public var id: String { rawValue }

    public var accentHex: String {
        switch self {
        case .program: return "#a855f7"
        case .ui: return "#00f5d4"
        case .game2d: return "#38bdf8"
        case .quantum3d: return "#f43f5e"
        case .ecosystem: return "#fbbf24"
        }
    }

    public var systemIcon: String {
        switch self {
        case .program: return "curlybraces"
        case .ui: return "macwindow"
        case .game2d: return "gamecontroller.fill"
        case .quantum3d: return "cube.transparent.fill"
        case .ecosystem: return "shield.lefthalf.filled"
        }
    }
}

public enum BlockKind: String, CaseIterable, Identifiable, Codable, Sendable {
    // Program & Logic
    case defineApp
    case declareVar
    case sayLog
    case repeatTimes
    case ifCondition
    case pyMathFastPath

    // UI & Audio
    case setUIProfile
    case createWindow
    case drawCard
    case drawButton
    case playTone

    // 2D Game
    case game2DHeader
    case gameWorld2D
    case gameGravity
    case spawnPlayer2D
    case spawnPlatform2D
    case spawnCoin2D
    case spawnEnemy2D
    case spawnPortal2D

    // Quantum 3D
    case game3DHeader
    case scene3DWorld
    case camera3DSet
    case light3DDirectional
    case spawnPlayer3D
    case spawnBox3D
    case spawnCrystal3D
    case spawnPortal3D

    // CS Ecosystem
    case useModule
    case csmsEncrypt

    public var id: String { rawValue }

    public var category: BlockCategory {
        switch self {
        case .defineApp, .declareVar, .sayLog, .repeatTimes, .ifCondition, .pyMathFastPath:
            return .program
        case .setUIProfile, .createWindow, .drawCard, .drawButton, .playTone:
            return .ui
        case .game2DHeader, .gameWorld2D, .gameGravity, .spawnPlayer2D, .spawnPlatform2D, .spawnCoin2D, .spawnEnemy2D, .spawnPortal2D:
            return .game2d
        case .game3DHeader, .scene3DWorld, .camera3DSet, .light3DDirectional, .spawnPlayer3D, .spawnBox3D, .spawnCrystal3D, .spawnPortal3D:
            return .quantum3d
        case .useModule, .csmsEncrypt:
            return .ecosystem
        }
    }

    public var title: String {
        switch self {
        case .defineApp: return "Definir App"
        case .declareVar: return "Variable (val / mut)"
        case .sayLog: return "Imprimir (say)"
        case .repeatTimes: return "Repetir N veces"
        case .ifCondition: return "Si se cumple (if)"
        case .pyMathFastPath: return "Fórmula py!() Nativa"
        case .setUIProfile: return "Perfil UI (Metal 4 / Shine)"
        case .createWindow: return "Crear Ventana"
        case .drawCard: return "Tarjeta UI"
        case .drawButton: return "Botón Interactivo"
        case .playTone: return "Tono de Audio"
        case .game2DHeader: return "Iniciar Juego 2D"
        case .gameWorld2D: return "Mundo 2D"
        case .gameGravity: return "Gravedad 2D"
        case .spawnPlayer2D: return "Jugador 2D"
        case .spawnPlatform2D: return "Plataforma 2D"
        case .spawnCoin2D: return "Moneda 2D"
        case .spawnEnemy2D: return "Enemigo 2D"
        case .spawnPortal2D: return "Portal 2D"
        case .game3DHeader: return "Iniciar Quantum 3D"
        case .scene3DWorld: return "Escena 3D"
        case .camera3DSet: return "Cámara 3D"
        case .light3DDirectional: return "Luz Direccional 3D"
        case .spawnPlayer3D: return "Piloto 3D"
        case .spawnBox3D: return "Bloque / Pista 3D"
        case .spawnCrystal3D: return "Cristal 3D"
        case .spawnPortal3D: return "Portal 3D"
        case .useModule: return "Importar Módulo CS"
        case .csmsEncrypt: return "Cifrar CSMS E2EE"
        }
    }

    public var isContainer: Bool {
        switch self {
        case .repeatTimes, .ifCondition:
            return true
        default:
            return false
        }
    }
}

public struct BlockParam: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var label: String
    public var value: String

    public init(id: String, label: String, value: String) {
        self.id = id
        self.label = label
        self.value = value
    }
}

public struct LoopBlock: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var kind: BlockKind
    public var params: [BlockParam]
    public var children: [LoopBlock]

    public init(id: UUID = UUID(), kind: BlockKind, params: [BlockParam]? = nil, children: [LoopBlock] = []) {
        self.id = id
        self.kind = kind
        self.params = params ?? Self.defaultParams(for: kind)
        self.children = children
    }

    public func param(_ id: String, fallback: String = "") -> String {
        params.first(where: { $0.id == id })?.value ?? fallback
    }

    public static func defaultParams(for kind: BlockKind) -> [BlockParam] {
        switch kind {
        case .defineApp:
            return [BlockParam(id: "name", label: "Nombre", value: "MiAppiPad"),
                    BlockParam(id: "ver", label: "Versión", value: "1.1")]
        case .declareVar:
            return [BlockParam(id: "mut", label: "Mutable (mut/val)", value: "val"),
                    BlockParam(id: "name", label: "Variable", value: "energia"),
                    BlockParam(id: "expr", label: "Valor", value: "100")]
        case .sayLog:
            return [BlockParam(id: "msg", label: "Mensaje", value: "¡Hola desde hiOP Builder!")]
        case .repeatTimes:
            return [BlockParam(id: "count", label: "Veces", value: "3")]
        case .ifCondition:
            return [BlockParam(id: "cond", label: "Condición", value: "energia > 50")]
        case .pyMathFastPath:
            return [BlockParam(id: "var", label: "Guardar en", value: "hipotenusa"),
                    BlockParam(id: "expr", label: "Expresión py!", value: "round(math.hypot(3, 4) * math.pi, 2)")]
        case .setUIProfile:
            return [BlockParam(id: "profile", label: "Perfil", value: "metal4")]
        case .createWindow:
            return [BlockParam(id: "title", label: "Título", value: "iPad Builder Stage"),
                    BlockParam(id: "w", label: "Ancho", value: "840"),
                    BlockParam(id: "h", label: "Alto", value: "520")]
        case .drawCard:
            return [BlockParam(id: "title", label: "Título", value: "Telemetría en Vivo"),
                    BlockParam(id: "text", label: "Texto", value: "Ejecutado sin Python"),
                    BlockParam(id: "x", label: "X", value: "24"),
                    BlockParam(id: "y", label: "Y", value: "24")]
        case .drawButton:
            return [BlockParam(id: "text", label: "Texto", value: "Impulsar"),
                    BlockParam(id: "action", label: "Acción", value: "boost")]
        case .playTone:
            return [BlockParam(id: "freq", label: "Hz", value: "587"),
                    BlockParam(id: "ms", label: "Duración ms", value: "80")]
        case .game2DHeader:
            return [BlockParam(id: "name", label: "Juego 2D", value: "BuilderArcade2D")]
        case .gameWorld2D:
            return [BlockParam(id: "w", label: "Ancho", value: "1100"),
                    BlockParam(id: "h", label: "Alto", value: "420")]
        case .gameGravity:
            return [BlockParam(id: "g", label: "Gravedad", value: "980")]
        case .spawnPlayer2D:
            return [BlockParam(id: "name", label: "Nombre", value: "Hero"),
                    BlockParam(id: "x", label: "X", value: "90"),
                    BlockParam(id: "y", label: "Y", value: "290"),
                    BlockParam(id: "color", label: "Color", value: "#00f5d4")]
        case .spawnPlatform2D:
            return [BlockParam(id: "x", label: "X", value: "60"),
                    BlockParam(id: "y", label: "Y", value: "340"),
                    BlockParam(id: "w", label: "Ancho", value: "220"),
                    BlockParam(id: "color", label: "Color", value: "#6366f1")]
        case .spawnCoin2D:
            return [BlockParam(id: "x", label: "X", value: "260"),
                    BlockParam(id: "y", label: "Y", value: "260"),
                    BlockParam(id: "pts", label: "Puntos", value: "150")]
        case .spawnEnemy2D:
            return [BlockParam(id: "name", label: "Enemigo", value: "Bot"),
                    BlockParam(id: "x", label: "X", value: "520"),
                    BlockParam(id: "y", label: "Y", value: "340"),
                    BlockParam(id: "color", label: "Color", value: "#f43f5e")]
        case .spawnPortal2D:
            return [BlockParam(id: "x", label: "X", value: "920"),
                    BlockParam(id: "y", label: "Y", value: "300"),
                    BlockParam(id: "label", label: "Meta", value: "EXIT")]
        case .game3DHeader:
            return [BlockParam(id: "name", label: "Juego 3D", value: "BuilderQuantum3D")]
        case .scene3DWorld:
            return [BlockParam(id: "name", label: "Mundo", value: "Arena3D"),
                    BlockParam(id: "sky", label: "Cielo", value: "cyber_night")]
        case .camera3DSet:
            return [BlockParam(id: "mode", label: "Modo", value: "chase"),
                    BlockParam(id: "fov", label: "FOV", value: "64")]
        case .light3DDirectional:
            return [BlockParam(id: "color", label: "Color", value: "#ffffff"),
                    BlockParam(id: "intensity", label: "Intensidad", value: "1.1")]
        case .spawnPlayer3D:
            return [BlockParam(id: "name", label: "Piloto", value: "Pilot3D"),
                    BlockParam(id: "color", label: "Color", value: "#38bdf8")]
        case .spawnBox3D:
            return [BlockParam(id: "x", label: "X", value: "0"),
                    BlockParam(id: "y", label: "Y", value: "-0.5"),
                    BlockParam(id: "z", label: "Z", value: "14"),
                    BlockParam(id: "color", label: "Color", value: "#6366f1")]
        case .spawnCrystal3D:
            return [BlockParam(id: "x", label: "X", value: "0"),
                    BlockParam(id: "y", label: "Y", value: "3.0"),
                    BlockParam(id: "z", label: "Z", value: "14"),
                    BlockParam(id: "pts", label: "Puntos", value: "250")]
        case .spawnPortal3D:
            return [BlockParam(id: "z", label: "Z", value: "36"),
                    BlockParam(id: "label", label: "Etiqueta", value: "OMEGA GATE")]
        case .useModule:
            return [BlockParam(id: "mod", label: "Módulo", value: "csms")]
        case .csmsEncrypt:
            return [BlockParam(id: "var", label: "Variable", value: "paquete"),
                    BlockParam(id: "room", label: "Sala", value: "ipad-builder"),
                    BlockParam(id: "msg", label: "Mensaje", value: "Bloques Seguros")]
        }
    }
}

public struct BlockStarterKit: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let blocks: [LoopBlock]
}

public enum BlockLoopCompiler {
    public static func compile(_ blocks: [LoopBlock]) -> String {
        var lines: [String] = [
            "# Generado por hiOP Builder (Programación por Bloques)",
            ""
        ]
        var indentLevel = 0
        for block in blocks {
            emitBlock(block, indentLevel: &indentLevel, lines: &lines)
        }
        return lines.joined(separator: "\n")
    }

    private static func emitBlock(_ block: LoopBlock, indentLevel: inout Int, lines: inout [String]) {
        let pad = String(repeating: "    ", count: indentLevel)
        switch block.kind {
        case .defineApp:
            lines.append("define app \"\(block.param("name"))\" version \(block.param("ver", fallback: "1.1")):")
            indentLevel = 1
        case .game2DHeader:
            lines.append("define game \"\(block.param("name"))\" version 1.1:")
            indentLevel = 1
        case .game3DHeader:
            lines.append("define game3d \"\(block.param("name"))\" version 3.0:")
            indentLevel = 1
        case .declareVar:
            let kw = block.param("mut", fallback: "val") == "mut" ? "mut" : "val"
            lines.append("\(pad)\(kw) \(block.param("name")) = \(block.param("expr"))")
        case .sayLog:
            let msg = block.param("msg")
            if msg.contains("{") || msg.hasPrefix("$") {
                lines.append("\(pad)say($\"\(msg.replacingOccurrences(of: "\"", with: "\\\""))\")")
            } else {
                lines.append("\(pad)say(\"\(msg.replacingOccurrences(of: "\"", with: "\\\""))\")")
            }
        case .repeatTimes:
            let n = Int(block.param("count", fallback: "3")) ?? 3
            lines.append("\(pad)loop \(max(1, n)) {")
            var innerIndent = indentLevel + 1
            for child in block.children {
                emitBlock(child, indentLevel: &innerIndent, lines: &lines)
            }
            lines.append("\(pad)}")
        case .ifCondition:
            lines.append("\(pad)if \(block.param("cond", fallback: "true")) {")
            var innerIndent = indentLevel + 1
            for child in block.children {
                emitBlock(child, indentLevel: &innerIndent, lines: &lines)
            }
            lines.append("\(pad)}")
        case .pyMathFastPath:
            lines.append("\(pad)val \(block.param("var", fallback: "res")) = py!(\(block.param("expr")))")
        case .setUIProfile:
            lines.append("\(pad)set ui_profile to \"\(block.param("profile", fallback: "metal4"))\"")
        case .createWindow:
            lines.append("\(pad)window.create(\"\(block.param("title"))\", \(block.param("w", fallback: "840")), \(block.param("h", fallback: "520")))")
        case .drawCard:
            lines.append("\(pad)draw card at (\(block.param("x", fallback: "24")), \(block.param("y", fallback: "24"))) size (320, 120) title \"\(block.param("title"))\" text \"\(block.param("text"))\"")
        case .drawButton:
            lines.append("\(pad)draw button at (24, 170) text \"\(block.param("text"))\" action \"\(block.param("action"))\"")
        case .playTone:
            lines.append("\(pad)audio.tone(\(block.param("freq", fallback: "587")), \(block.param("ms", fallback: "80")))")
        case .gameWorld2D:
            lines.append("\(pad)game.world(width: \(block.param("w", fallback: "1100")), height: \(block.param("h", fallback: "420")))")
        case .gameGravity:
            lines.append("\(pad)game.gravity(\(block.param("g", fallback: "980")))")
        case .spawnPlayer2D:
            lines.append("\(pad)spawn.player(name: \"\(block.param("name"))\", at: (\(block.param("x")), \(block.param("y"))), speed: 280, jump: 460, health: 100, color: \"\(block.param("color", fallback: "#00f5d4"))\")")
        case .spawnPlatform2D:
            lines.append("\(pad)spawn.platform(at: (\(block.param("x")), \(block.param("y"))), size: (\(block.param("w", fallback: "220")), 18), color: \"\(block.param("color", fallback: "#6366f1"))\")")
        case .spawnCoin2D:
            lines.append("\(pad)spawn.coin(at: (\(block.param("x")), \(block.param("y"))), points: \(block.param("pts", fallback: "150")))")
        case .spawnEnemy2D:
            lines.append("\(pad)spawn.enemy(name: \"\(block.param("name"))\", at: (\(block.param("x")), \(block.param("y"))), range: (420, 760), speed: 85, health: 40, color: \"\(block.param("color", fallback: "#f43f5e"))\")")
        case .spawnPortal2D:
            lines.append("\(pad)spawn.portal(at: (\(block.param("x")), \(block.param("y"))), label: \"\(block.param("label", fallback: "EXIT"))\", color: \"#c084fc\")")
        case .scene3DWorld:
            lines.append("\(pad)scene3d.world(name: \"\(block.param("name"))\", size: (180, 80, 180), sky: \"\(block.param("sky", fallback: "cyber_night"))\", fog: 0.010, grid: true)")
        case .camera3DSet:
            lines.append("\(pad)camera3d.set(mode: \"\(block.param("mode", fallback: "chase"))\", pos: (0, 8, -16), target: (0, 2, 10), fov: \(block.param("fov", fallback: "64")), smooth: 0.14)")
        case .light3DDirectional:
            lines.append("\(pad)light3d.directional(dir: (-0.4, -1.0, -0.35), color: \"\(block.param("color", fallback: "#ffffff"))\", intensity: \(block.param("intensity", fallback: "1.1")))")
        case .spawnPlayer3D:
            lines.append("\(pad)spawn3d.player(\"\(block.param("name"))\", at: (0, 2, 0), mesh: \"hovercraft\", speed: 24, jump: 16, color: \"\(block.param("color", fallback: "#38bdf8"))\")")
        case .spawnBox3D:
            lines.append("\(pad)spawn3d.box(at: (\(block.param("x")), \(block.param("y")), \(block.param("z"))), size: (14, 1.2, 26), color: \"\(block.param("color", fallback: "#6366f1"))\")")
        case .spawnCrystal3D:
            lines.append("\(pad)spawn3d.crystal(at: (\(block.param("x")), \(block.param("y")), \(block.param("z"))), points: \(block.param("pts", fallback: "250")), color: \"#fbbf24\")")
        case .spawnPortal3D:
            lines.append("\(pad)spawn3d.portal(at: (0, 3.5, \(block.param("z", fallback: "36"))), radius: 3.8, label: \"\(block.param("label", fallback: "OMEGA GATE"))\", color: \"#c084fc\")")
        case .useModule:
            lines.append("\(pad)use \"\(block.param("mod", fallback: "csms"))\"")
        case .csmsEncrypt:
            lines.append("\(pad)val \(block.param("var", fallback: "paquete")) = crypto.csms_payload(\"\(block.param("room"))\", \"\(block.param("msg"))\")")
        }
    }

    public static let starterKits: [BlockStarterKit] = [
        BlockStarterKit(
            id: "arcade2d",
            title: "Plataformas 2D",
            subtitle: "Jugador, plataformas, moneda, enemigo y portal",
            blocks: [
                LoopBlock(kind: .game2DHeader),
                LoopBlock(kind: .gameWorld2D),
                LoopBlock(kind: .gameGravity),
                LoopBlock(kind: .spawnPlayer2D),
                LoopBlock(kind: .spawnPlatform2D),
                LoopBlock(kind: .spawnCoin2D),
                LoopBlock(kind: .spawnEnemy2D),
                LoopBlock(kind: .spawnPortal2D),
                LoopBlock(kind: .sayLog, params: [BlockParam(id: "msg", label: "Mensaje", value: "Nivel 2D armado con bloques!")])
            ]
        ),
        BlockStarterKit(
            id: "quantum3d",
            title: "Mundo Quantum 3D",
            subtitle: "Escena Z-Buffer 3D con piloto, cristal y portal",
            blocks: [
                LoopBlock(kind: .game3DHeader),
                LoopBlock(kind: .scene3DWorld),
                LoopBlock(kind: .camera3DSet),
                LoopBlock(kind: .light3DDirectional),
                LoopBlock(kind: .spawnPlayer3D),
                LoopBlock(kind: .spawnBox3D),
                LoopBlock(kind: .spawnCrystal3D),
                LoopBlock(kind: .spawnPortal3D),
                LoopBlock(kind: .sayLog, params: [BlockParam(id: "msg", label: "Mensaje", value: "Quantum 3D activo en iPad!")])
            ]
        ),
        BlockStarterKit(
            id: "ui_csms",
            title: "App UI + py!() + CSMS",
            subtitle: "Ventana interactiva, fórmula py! sin Python y cifrado E2EE",
            blocks: [
                LoopBlock(kind: .defineApp),
                LoopBlock(kind: .setUIProfile),
                LoopBlock(kind: .createWindow),
                LoopBlock(kind: .declareVar),
                LoopBlock(kind: .pyMathFastPath),
                LoopBlock(kind: .csmsEncrypt),
                LoopBlock(kind: .drawCard),
                LoopBlock(kind: .drawButton),
                LoopBlock(kind: .playTone),
                LoopBlock(kind: .ifCondition, children: [
                    LoopBlock(kind: .sayLog, params: [BlockParam(id: "msg", label: "Mensaje", value: "Energía óptima en bloques!")])
                ])
            ]
        )
    ]
}
