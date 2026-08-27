import SpriteKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none: UInt32      = 0
    static let player: UInt32    = 0b1       // 1
    static let platform: UInt32  = 0b10      // 2
    static let clue: UInt32      = 0b100     // 4
    static let forkbot: UInt32   = 0b1000    // 8
    static let portal: UInt32    = 0b10000   // 16
}

// MARK: - Angel Helium Character Node
class AngelHeliumNode: SKNode {
    private let bodyShape: SKShapeNode
    private let haloShape: SKShapeNode
    private let eyesNode: SKNode
    private var jumpsLeft = 2
    
    override init() {
        // Handcrafted geometric retro look (Cyan Neon Helium Being)
        let bodyPath = CGPath(roundedRect: CGRect(x: -14, y: -20, width: 28, height: 40), cornerWidth: 10, cornerHeight: 10, transform: nil)
        self.bodyShape = SKShapeNode(path: bodyPath)
        self.bodyShape.fillColor = SKColor(red: 0.2, green: 0.85, blue: 1.0, alpha: 0.95)
        self.bodyShape.strokeColor = SKColor(red: 0.6, green: 0.95, blue: 1.0, alpha: 1.0)
        self.bodyShape.lineWidth = 2.0
        self.bodyShape.glowWidth = 4.0
        
        // Floating Halo (Angel Helium trait)
        let haloPath = CGPath(ellipseIn: CGRect(x: -16, y: 24, width: 32, height: 8), transform: nil)
        self.haloShape = SKShapeNode(path: haloPath)
        self.haloShape.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 0.95)
        self.haloShape.fillColor = SKColor.clear
        self.haloShape.lineWidth = 2.5
        self.haloShape.glowWidth = 3.0
        
        // Expressive Eyes
        self.eyesNode = SKNode()
        let leftEye = SKShapeNode(circleOfRadius: 3)
        leftEye.fillColor = .white
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: 5, y: 6)
        
        let rightEye = SKShapeNode(circleOfRadius: 3)
        rightEye.fillColor = .white
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: 11, y: 6)
        
        eyesNode.addChild(leftEye)
        eyesNode.addChild(rightEye)
        
        super.init()
        
        self.name = "AngelHelium"
        self.addChild(bodyShape)
        self.addChild(haloShape)
        self.addChild(eyesNode)
        
        // Float Bobbing animation for the Halo
        let floatUp = SKAction.moveBy(x: 0, y: 3, duration: 0.6)
        let floatDown = SKAction.moveBy(x: 0, y: -3, duration: 0.6)
        haloShape.run(SKAction.repeatForever(SKAction.sequence([floatUp, floatDown])))
        
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPhysics() {
        let pBody = SKPhysicsBody(rectangleOf: CGSize(width: 26, height: 38))
        pBody.isDynamic = true
        pBody.allowsRotation = false
        pBody.restitution = 0.0
        pBody.friction = 0.2
        pBody.mass = 0.18 // Floaty helium feel
        pBody.categoryBitMask = PhysicsCategory.player
        pBody.collisionBitMask = PhysicsCategory.platform
        pBody.contactTestBitMask = PhysicsCategory.clue | PhysicsCategory.forkbot | PhysicsCategory.portal
        self.physicsBody = pBody
    }
    
    func move(dx: CGFloat) {
        guard let pb = self.physicsBody else { return }
        pb.velocity.dx = dx * 280
        
        if dx > 0 {
            self.xScale = 1.0
        } else if dx < 0 {
            self.xScale = -1.0
        }
    }
    
    func jump() {
        guard let pb = self.physicsBody else { return }
        if jumpsLeft > 0 {
            pb.velocity.dy = 420
            jumpsLeft -= 1
            emitHeliumBurst()
        }
    }
    
    func resetJumps() {
        self.jumpsLeft = 2
    }
    
    private func emitHeliumBurst() {
        // Retro particle pulse
        let pulse = SKShapeNode(circleOfRadius: 8)
        pulse.strokeColor = SKColor(red: 0.2, green: 0.85, blue: 1.0, alpha: 0.8)
        pulse.fillColor = SKColor.clear
        pulse.position = CGPoint(x: 0, y: -18)
        self.addChild(pulse)
        
        let expand = SKAction.scale(to: 3.0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        pulse.run(SKAction.sequence([SKAction.group([expand, fade]), remove]))
    }
}
