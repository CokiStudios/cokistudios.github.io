import SpriteKit

// MARK: - Corrupted Forkbot Node
// Aesthetic: SENA-style geometric mannequin silhouette with floating detached head,
// hide-and-seek splitting jaw, and hidden Xtraps glowing bone structure revealed at close proximity.
class ForkbotNode: SKNode {
    private let torsoNode: SKShapeNode
    private let floatingHeadNode: SKNode
    private let topJaw: SKShapeNode
    private let bottomJaw: SKShapeNode
    private let xtrapsRibcageNode: SKNode
    private let glitchConeNode: SKShapeNode
    
    var patrolRange: ClosedRange<CGFloat> = 0...100
    private var patrolSpeed: CGFloat = 80
    private var movingRight: Bool = true
    private var isAlerted: Bool = false
    private var isJawOpen: Bool = false
    
    override init() {
        // 1. Mannequin Torso
        let torsoPath = CGPath(roundedRect: CGRect(x: -16, y: -26, width: 32, height: 44), cornerWidth: 8, cornerHeight: 8, transform: nil)
        self.torsoNode = SKShapeNode(path: torsoPath)
        self.torsoNode.fillColor = SKColor(red: 0.1, green: 0.12, blue: 0.18, alpha: 0.95)
        self.torsoNode.strokeColor = SKColor(red: 0.3, green: 0.35, blue: 0.45, alpha: 1.0)
        self.torsoNode.lineWidth = 2.0
        
        // 2. Hidden Xtraps Bone Structure (Internal Ribcage & Core - initially hidden)
        self.xtrapsRibcageNode = SKNode()
        self.xtrapsRibcageNode.alpha = 0.0 // Completely hidden in normal state
        
        // Xtraps diagonal cross energy bones
        for i in 0..<3 {
            let yOffset = CGFloat(i * 10 - 10)
            let boneL = SKShapeNode(rectOf: CGSize(width: 18, height: 3))
            boneL.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.3, alpha: 0.9)
            boneL.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 1.0)
            boneL.glowWidth = 4.0
            boneL.position = CGPoint(x: 0, y: yOffset)
            boneL.zRotation = 0.2
            xtrapsRibcageNode.addChild(boneL)
            
            let boneR = SKShapeNode(rectOf: CGSize(width: 18, height: 3))
            boneR.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.3, alpha: 0.9)
            boneR.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 1.0)
            boneR.glowWidth = 4.0
            boneR.position = CGPoint(x: 0, y: yOffset)
            boneR.zRotation = -0.2
            xtrapsRibcageNode.addChild(boneR)
        }
        
        // 3. Floating Detached Head
        self.floatingHeadNode = SKNode()
        self.floatingHeadNode.position = CGPoint(x: 0, y: 32) // Floating detached above torso
        
        // Split Jaws (Hide & Seek style)
        let topPath = CGMutablePath()
        topPath.move(to: CGPoint(x: -14, y: 0))
        topPath.addLine(to: CGPoint(x: 14, y: 0))
        topPath.addLine(to: CGPoint(x: 10, y: 14))
        topPath.addLine(to: CGPoint(x: -10, y: 14))
        topPath.closeSubpath()
        self.topJaw = SKShapeNode(path: topPath)
        self.topJaw.fillColor = SKColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1.0)
        self.topJaw.strokeColor = SKColor(red: 0.4, green: 0.45, blue: 0.55, alpha: 1.0)
        
        let bottomPath = CGMutablePath()
        bottomPath.move(to: CGPoint(x: -14, y: 0))
        bottomPath.addLine(to: CGPoint(x: 14, y: 0))
        bottomPath.addLine(to: CGPoint(x: 8, y: -10))
        bottomPath.addLine(to: CGPoint(x: -8, y: -10))
        bottomPath.closeSubpath()
        self.bottomJaw = SKShapeNode(path: bottomPath)
        self.bottomJaw.fillColor = SKColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1.0)
        self.bottomJaw.strokeColor = SKColor(red: 0.4, green: 0.45, blue: 0.55, alpha: 1.0)
        
        // Red Eye Visor
        let eyeVisor = SKShapeNode(rectOf: CGSize(width: 16, height: 4), cornerRadius: 2)
        eyeVisor.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.2, alpha: 1.0)
        eyeVisor.strokeColor = .clear
        eyeVisor.glowWidth = 3.0
        eyeVisor.position = CGPoint(x: 2, y: 4)
        topJaw.addChild(eyeVisor)
        
        floatingHeadNode.addChild(topJaw)
        floatingHeadNode.addChild(bottomJaw)
        
        // 4. Glitch Detection Cone
        let conePath = CGMutablePath()
        conePath.move(to: CGPoint(x: 0, y: 0))
        conePath.addLine(to: CGPoint(x: 140, y: -35))
        conePath.addLine(to: CGPoint(x: 140, y: 35))
        conePath.closeSubpath()
        self.glitchConeNode = SKShapeNode(path: conePath)
        self.glitchConeNode.fillColor = SKColor(red: 1.0, green: 0.0, blue: 0.2, alpha: 0.08)
        self.glitchConeNode.strokeColor = SKColor(red: 1.0, green: 0.0, blue: 0.2, alpha: 0.25)
        self.glitchConeNode.lineWidth = 1.0
        self.glitchConeNode.position = CGPoint(x: 10, y: 20)
        
        super.init()
        
        self.name = "CorruptedForkbot"
        self.addChild(torsoNode)
        self.addChild(xtrapsRibcageNode)
        self.addChild(floatingHeadNode)
        self.addChild(glitchConeNode)
        
        // Floating head bobbing
        let headHoverUp = SKAction.moveBy(x: 0, y: 4, duration: 0.5)
        let headHoverDown = SKAction.moveBy(x: 0, y: -4, duration: 0.5)
        floatingHeadNode.run(SKAction.repeatForever(SKAction.sequence([headHoverUp, headHoverDown])))
        
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPhysics() {
        let pBody = SKPhysicsBody(rectangleOf: CGSize(width: 32, height: 56))
        pBody.isDynamic = true
        pBody.allowsRotation = false
        pBody.affectedByGravity = true
        pBody.mass = 0.5
        pBody.categoryBitMask = PhysicsCategory.forkbot
        pBody.collisionBitMask = PhysicsCategory.platform
        pBody.contactTestBitMask = PhysicsCategory.player
        self.physicsBody = pBody
    }
    
    func update(targetPos: CGPoint, deltaTime: TimeInterval) {
        let distanceToPlayer = hypot(targetPos.x - self.position.x, targetPos.y - self.position.y)
        
        // Close Proximity Threat Level (< 160 px) -> Jaw Splits & Xtraps Bones Ignite
        if distanceToPlayer < 160 {
            setAggressiveHunt(true)
            
            // Overdrive pursuit
            let dir: CGFloat = targetPos.x > self.position.x ? 1.0 : -1.0
            self.physicsBody?.velocity.dx = dir * 160
            self.xScale = dir > 0 ? 1.0 : -1.0
        } else {
            setAggressiveHunt(false)
            
            // Standard Patrol
            if movingRight {
                self.physicsBody?.velocity.dx = patrolSpeed
                self.xScale = 1.0
                if self.position.x >= patrolRange.upperBound {
                    movingRight = false
                }
            } else {
                self.physicsBody?.velocity.dx = -patrolSpeed
                self.xScale = -1.0
                if self.position.x <= patrolRange.lowerBound {
                    movingRight = true
                }
            }
        }
    }
    
    private func setAggressiveHunt(_ active: Bool) {
        guard active != isJawOpen else { return }
        isJawOpen = active
        
        if active {
            // Split the jaw wide open (Hide & Seek Impostor style)
            topJaw.run(SKAction.moveTo(y: 8, duration: 0.15))
            bottomJaw.run(SKAction.moveTo(y: -12, duration: 0.15))
            
            // Reveal pulsing Xtraps neon skeleton
            torsoNode.run(SKAction.fadeAlpha(to: 0.4, duration: 0.15))
            xtrapsRibcageNode.run(SKAction.fadeIn(withDuration: 0.15))
            
            glitchConeNode.fillColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.25)
        } else {
            // Close jaw back to sleek mannequin
            topJaw.run(SKAction.moveTo(y: 0, duration: 0.2))
            bottomJaw.run(SKAction.moveTo(y: 0, duration: 0.2))
            
            // Hide Xtraps skeleton
            torsoNode.run(SKAction.fadeAlpha(to: 0.95, duration: 0.2))
            xtrapsRibcageNode.run(SKAction.fadeOut(withDuration: 0.2))
            
            glitchConeNode.fillColor = SKColor(red: 1.0, green: 0.0, blue: 0.2, alpha: 0.08)
        }
    }
}
