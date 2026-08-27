import SpriteKit
import Foundation

// MARK: - Level Entities & Layout
struct PlatformDef {
    let rect: CGRect
    let isMoving: BooleanLiteralType
    let moveRange: CGFloat
    let isDisappearing: Bool
}

struct ClueDef {
    let id: String
    let position: CGPoint
    let clueName: String
}

struct LevelData {
    let levelNumber: Int
    let title: String
    let subtitle: String
    let playerSpawn: CGPoint
    let exitPortal: CGPoint
    let forkbotSpawn: CGPoint
    let forkbotPatrolRange: ClosedRange<CGFloat>
    let platforms: [PlatformDef]
    let clues: [ClueDef]
    let bgThemeHex: UInt32
}

struct GameLevels {
    static let allLevels: [LevelData] = [
        // ── LEVEL 1: The Neon Outskirts ──
        LevelData(
            levelNumber: 1,
            title: "Level 1: The Neon Outskirts",
            subtitle: "Find 3 Holo Clues to power the extraction beacon.",
            playerSpawn: CGPoint(x: 80, y: 120),
            exitPortal: CGPoint(x: 900, y: 380),
            forkbotSpawn: CGPoint(x: 520, y: 120),
            forkbotPatrolRange: 420...680,
            platforms: [
                // Ground
                PlatformDef(rect: CGRect(x: 0, y: 0, width: 1000, height: 60), isMoving: false, moveRange: 0, isDisappearing: false),
                // Mid Platforms
                PlatformDef(rect: CGRect(x: 180, y: 140, width: 140, height: 20), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 360, y: 220, width: 130, height: 20), isMoving: true, moveRange: 80, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 560, y: 180, width: 150, height: 20), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 760, y: 280, width: 160, height: 20), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 860, y: 360, width: 120, height: 20), isMoving: false, moveRange: 0, isDisappearing: false)
            ],
            clues: [
                ClueDef(id: "c1_1", position: CGPoint(x: 240, y: 180), clueName: "Corrupted Memory Fragment Alpha"),
                ClueDef(id: "c1_2", position: CGPoint(x: 420, y: 270), clueName: "Quantum Encryption Key"),
                ClueDef(id: "c1_3", position: CGPoint(x: 800, y: 330), clueName: "Holo Beacon Power Core")
            ],
            bgThemeHex: 0x070B14
        ),

        // ── LEVEL 2: Cyber Fork Factory ──
        LevelData(
            levelNumber: 2,
            title: "Level 2: Cyber Fork Factory",
            subtitle: "Conveyor platforms & high-voltage patrol sector.",
            playerSpawn: CGPoint(x: 60, y: 100),
            exitPortal: CGPoint(x: 920, y: 480),
            forkbotSpawn: CGPoint(x: 600, y: 240),
            forkbotPatrolRange: 450...800,
            platforms: [
                PlatformDef(rect: CGRect(x: 0, y: 0, width: 400, height: 50), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 500, y: 0, width: 500, height: 50), isMoving: false, moveRange: 0, isDisappearing: false),
                // Factory floors
                PlatformDef(rect: CGRect(x: 120, y: 160, width: 160, height: 20), isMoving: true, moveRange: 60, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 320, y: 240, width: 140, height: 20), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 480, y: 220, width: 340, height: 20), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 200, y: 360, width: 180, height: 20), isMoving: true, moveRange: 100, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 450, y: 420, width: 150, height: 20), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 680, y: 440, width: 160, height: 20), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 880, y: 460, width: 120, height: 20), isMoving: false, moveRange: 0, isDisappearing: false)
            ],
            clues: [
                ClueDef(id: "c2_1", position: CGPoint(x: 180, y: 210), clueName: "SENA Mannequin Blueprint"),
                ClueDef(id: "c2_2", position: CGPoint(x: 620, y: 270), clueName: "Xtraps Bone Schematic"),
                ClueDef(id: "c2_3", position: CGPoint(x: 260, y: 410), clueName: "Sub-zero Helium Capsule"),
                ClueDef(id: "c2_4", position: CGPoint(x: 740, y: 490), clueName: "Factory Overdrive Override")
            ],
            bgThemeHex: 0x090514
        ),

        // ── LEVEL 3: The Corrupted Core ──
        LevelData(
            levelNumber: 3,
            title: "Level 3: The Corrupted Core",
            subtitle: "Disappearing holo-bridges & enraged Forkbot hunt!",
            playerSpawn: CGPoint(x: 60, y: 120),
            exitPortal: CGPoint(x: 920, y: 520),
            forkbotSpawn: CGPoint(x: 500, y: 320),
            forkbotPatrolRange: 200...850,
            platforms: [
                PlatformDef(rect: CGRect(x: 0, y: 0, width: 220, height: 50), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 800, y: 0, width: 200, height: 50), isMoving: false, moveRange: 0, isDisappearing: false),
                // Core maze
                PlatformDef(rect: CGRect(x: 160, y: 150, width: 120, height: 18), isMoving: false, moveRange: 0, isDisappearing: true),
                PlatformDef(rect: CGRect(x: 320, y: 220, width: 120, height: 18), isMoving: false, moveRange: 0, isDisappearing: true),
                PlatformDef(rect: CGRect(x: 480, y: 200, width: 180, height: 20), isMoving: true, moveRange: 70, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 220, y: 320, width: 150, height: 20), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 440, y: 360, width: 260, height: 20), isMoving: false, moveRange: 0, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 740, y: 340, width: 130, height: 18), isMoving: false, moveRange: 0, isDisappearing: true),
                PlatformDef(rect: CGRect(x: 580, y: 460, width: 160, height: 20), isMoving: true, moveRange: 80, isDisappearing: false),
                PlatformDef(rect: CGRect(x: 840, y: 500, width: 160, height: 20), isMoving: false, moveRange: 0, isDisappearing: false)
            ],
            clues: [
                ClueDef(id: "c3_1", position: CGPoint(x: 200, y: 200), clueName: "Origin of Xtraps Core"),
                ClueDef(id: "c3_2", position: CGPoint(x: 540, y: 250), clueName: "Angel Helium's Aura Sigil"),
                ClueDef(id: "c3_3", position: CGPoint(x: 280, y: 370), clueName: "Impostor Jaw Mechanism"),
                ClueDef(id: "c3_4", position: CGPoint(x: 640, y: 510), clueName: "Holo Entertainment Master Key")
            ],
            bgThemeHex: 0x140509
        )
    ]
}
