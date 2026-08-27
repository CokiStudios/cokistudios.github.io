import SpriteKit

// MARK: - Game State Delegation
protocol HoloGameDelegate: AnyObject {
    func didUpdateClues(found: Int, total: Int)
    func didChangeLevel(levelNumber: Int, title: String)
    func didWinGame()
    func didGameOver()
}

class HoloGameScene: SKScene, SKPhysicsContactDelegate {
    weak var gameDelegate: HoloGameDelegate?
    
    private var currentLevelIndex: Int = 0
    private var player: AngelHeliumNode!
    private var forkbot: ForkbotNode!
    private var portalNode: SKShapeNode!
    private var clueNodes: [SKShapeNode] = []
    
    private var collectedClueIds: Set<String> = []
    private var lastUpdateTime: TimeInterval = 0
    private var isLevelCompleted: Bool = false
    
    var moveInput: CGFloat = 0.0
    
    override func didMove(to view: SKView) {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        self.physicsWorld.contactDelegate = self
        loadLevel(index: 0)
    }
    
    func loadLevel(index: Int) {
        self.removeAllChildren()
        self.clueNodes.removeAll()
        self.collectedClueIds.removeAll()
        self.isLevelCompleted = false
        self.currentLevelIndex = index
        
        let level = GameLevels.allLevels[index]
        self.backgroundColor = SKColor(rgb: level.bgThemeHex)
        
        gameDelegate?.didChangeLevel(levelNumber: level.levelNumber, title: level.title)
        gameDelegate?.didUpdateClues(found: 0, total: level.clues.count)
        
        // 1. Build Platforms
        for plat in level.platforms {
            let pNode = SKShapeNode(rect: CGRect(origin: .zero, size: plat.rect.size), cornerRadius: 4)
            pNode.position = plat.rect.origin
            pNode.fillColor = SKColor(red: 0.1, green: 0.16, blue: 0.28, alpha: 0.95)
            pNode.strokeColor = SKColor(red: 0.25, green: 0.45, blue: 0.85, alpha: 0.9)
            pNode.lineWidth = 1.5
            pNode.glowWidth = plat.isDisappearing ? 3.0 : 0.0
            
            let pb = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: plat.rect.size))
            pb.categoryBitMask = PhysicsCategory.platform
            pb.friction = 0.4
            pNode.physicsBody = pb
            
            if plat.isMoving {
                let moveRight = SKAction.moveBy(x: plat.moveRange, y: 0, duration: 2.0)
                let moveLeft = SKAction.moveBy(x: -plat.moveRange, y: 0, duration: 2.0)
                pNode.run(SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft])))
            }
            
            if plat.isDisappearing {
                let wait = SKAction.wait(forDuration: 2.5)
                let fadeOut = SKAction.fadeAlpha(to: 0.1, duration: 0.5)
                let togglePhysOff = SKAction.run { pNode.physicsBody = nil }
                let waitHidden = SKAction.wait(forDuration: 2.0)
                let fadeIn = SKAction.fadeAlpha(to: 0.95, duration: 0.5)
                let togglePhysOn = SKAction.run { pNode.physicsBody = pb }
                pNode.run(SKAction.repeatForever(SKAction.sequence([wait, fadeOut, togglePhysOff, waitHidden, fadeIn, togglePhysOn])))
            }
            
            self.addChild(pNode)
        }
        
        // 2. Build Holo Clues
        for clue in level.clues {
            let cNode = SKShapeNode(rectOf: CGSize(width: 20, height: 20), cornerRadius: 4)
            cNode.position = clue.position
            cNode.name = clue.id
            cNode.fillColor = SKColor(red: 0.95, green: 0.8, blue: 0.1, alpha: 0.9)
            cNode.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.4, alpha: 1.0)
            cNode.glowWidth = 6.0
            
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
            let bobUp = SKAction.moveBy(x: 0, y: 5, duration: 0.8)
            let bobDown = SKAction.moveBy(x: 0, y: -5, duration: 0.8)
            cNode.run(SKAction.repeatForever(rotate))
            cNode.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])))
            
            let pb = SKPhysicsBody(circleOfRadius: 12)
            pb.isDynamic = false
            pb.categoryBitMask = PhysicsCategory.clue
            cNode.physicsBody = pb
            
            clueNodes.append(cNode)
            self.addChild(cNode)
        }
        
        // 3. Build Exit Portal (Locked until all clues are found)
        self.portalNode = SKShapeNode(ellipseOf: CGSize(width: 44, height: 70))
        portalNode.position = level.exitPortal
        portalNode.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 0.4)
        portalNode.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 0.8)
        portalNode.lineWidth = 2.0
        
        let portalPb = SKPhysicsBody(circleOfRadius: 28)
        portalPb.isDynamic = false
        portalPb.categoryBitMask = PhysicsCategory.portal
        portalNode.physicsBody = portalPb
        self.addChild(portalNode)
        
        // 4. Spawn Player Angel Helium
        self.player = AngelHeliumNode()
        player.position = level.playerSpawn
        self.addChild(player)
        
        // 5. Spawn Enemy Corrupted Forkbot
        self.forkbot = ForkbotNode()
        forkbot.position = level.forkbotSpawn
        forkbot.patrolRange = level.forkbotPatrolRange
        self.addChild(forkbot)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        player.move(dx: moveInput)
        forkbot.update(targetPos: player.position, deltaTime: dt)
        
        // Pitfall check
        if player.position.y < -50 {
            respawnPlayer()
        }
    }
    
    func playerJump() {
        player.jump()
    }
    
    private func respawnPlayer() {
        let level = GameLevels.allLevels[currentLevelIndex]
        player.position = level.playerSpawn
        player.physicsBody?.velocity = .zero
        player.resetJumps()
    }
    
    // MARK: - Collision Detection
    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Player touched Ground
        if mask == (PhysicsCategory.player | PhysicsCategory.platform) {
            player.resetJumps()
        }
        
        // Player collected Clue
        if mask == (PhysicsCategory.player | PhysicsCategory.clue) {
            let clueBody = contact.bodyA.categoryBitMask == PhysicsCategory.clue ? contact.bodyA : contact.bodyB
            if let cNode = clueBody.node as? SKShapeNode, let id = cNode.name {
                if !collectedClueIds.contains(id) {
                    collectedClueIds.insert(id)
                    
                    // Clue burst animation
                    cNode.run(SKAction.sequence([
                        SKAction.group([SKAction.scale(to: 2.0, duration: 0.2), SKAction.fadeOut(withDuration: 0.2)]),
                        SKAction.removeFromParent()
                    ]))
                    
                    let level = GameLevels.allLevels[currentLevelIndex]
                    gameDelegate?.didUpdateClues(found: collectedClueIds.count, total: level.clues.count)
                    
                    // Unlock portal if all clues collected
                    if collectedClueIds.count == level.clues.count {
                        unlockPortal()
                    }
                }
            }
        }
        
        // Player touched Corrupted Forkbot
        if mask == (PhysicsCategory.player | PhysicsCategory.forkbot) {
            triggerForkbotJumpScare()
        }
        
        // Player entered Portal
        if mask == (PhysicsCategory.player | PhysicsCategory.portal) {
            let level = GameLevels.allLevels[currentLevelIndex]
            if collectedClueIds.count == level.clues.count && !isLevelCompleted {
                isLevelCompleted = true
                nextLevelOrWin()
            }
        }
    }
    
    private func unlockPortal() {
        portalNode.fillColor = SKColor(red: 0.1, green: 0.9, blue: 0.4, alpha: 0.85)
        portalNode.strokeColor = SKColor(red: 0.5, green: 1.0, blue: 0.7, alpha: 1.0)
        portalNode.glowWidth = 10.0
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.4),
            SKAction.scale(to: 0.95, duration: 0.4)
        ])
        portalNode.run(SKAction.repeatForever(pulse))
    }
    
    private func triggerForkbotJumpScare() {
        // Glitch camera shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -8, y: 4, duration: 0.04),
            SKAction.moveBy(x: 8, y: -4, duration: 0.04),
            SKAction.moveBy(x: -4, y: 2, duration: 0.04),
            SKAction.moveBy(x: 4, y: -2, duration: 0.04)
        ])
        self.run(shake)
        respawnPlayer()
    }
    
    private func nextLevelOrWin() {
        if currentLevelIndex + 1 < GameLevels.allLevels.count {
            loadLevel(index: currentLevelIndex + 1)
        } else {
            gameDelegate?.didWinGame()
        }
    }
}

// Color Hex Extension
extension SKColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
