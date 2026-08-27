import SwiftUI
import SpriteKit

// MARK: - Game View Container (SwiftUI for macOS & iOS)
public struct HoloGameView: View, HoloGameDelegate {
    @State private var scene: HoloGameScene = {
        let sc = HoloGameScene(size: CGSize(width: 1024, height: 640))
        sc.scaleMode = .aspectFit
        return sc
    }()
    
    @State private var currentLevelTitle: String = "Level 1: The Neon Outskirts"
    @State private var cluesFound: Int = 0
    @State private var totalClues: Int = 3
    @State private var hasWonGame: Bool = false
    @State private var isGameOver: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.09).ignoresSafeArea()
            
            // 1. Native SpriteKit Canvas
            SpriteView(scene: scene)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .onAppear {
                    scene.gameDelegate = self
                }
            
            // 2. Retro HUD & Top Status Bar
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("🎮 HOLO ADVENTURES")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(Color(red: 0.2, green: 0.85, blue: 1.0))
                            
                            Text("by Holo Entertainment CS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Text(currentLevelTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Clues Badge
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                            .font(.system(size: 18))
                        
                        Text("CLUES: \(cluesFound) / \(totalClues)")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // 3. Virtual Controls (for iOS / iPadOS touch screen)
                #if os(iOS)
                HStack(alignment: .bottom) {
                    // Left / Right D-Pad
                    HStack(spacing: 16) {
                        ControlButton(icon: "arrow.left") {
                            scene.moveInput = -1.0
                        } onRelease: {
                            scene.moveInput = 0.0
                        }
                        
                        ControlButton(icon: "arrow.right") {
                            scene.moveInput = 1.0
                        } onRelease: {
                            scene.moveInput = 0.0
                        }
                    }
                    
                    Spacer()
                    
                    // Double Jump Button
                    Button(action: {
                        scene.playerJump()
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                            Text("FLOAT JUMP")
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Color(red: 0.2, green: 0.85, blue: 1.0).opacity(0.3))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(red: 0.2, green: 0.85, blue: 1.0), lineWidth: 2))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                #endif
            }
            
            // 4. Game Win Celebration Overlay
            if hasWonGame {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        Text("👑 MISSION ACCOMPLISHED!")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(Color(red: 0.2, green: 0.9, blue: 0.4))
                        
                        Text("Angel Helium recovered all Holo Clues and escaped the Corrupted Forkbot.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Text("Created with ❤️ by Holo Entertainment by CS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.6, green: 0.8, blue: 1.0))
                            .padding(.top, 8)
                        
                        Button(action: {
                            hasWonGame = false
                            scene.loadLevel(index: 0)
                        }) {
                            Text("PLAY AGAIN")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.2, green: 0.85, blue: 1.0))
                                .cornerRadius(12)
                        }
                        .padding(.top, 12)
                    }
                    .padding(32)
                    .background(Color(red: 0.08, green: 0.12, blue: 0.2))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(red: 0.2, green: 0.85, blue: 1.0).opacity(0.4), lineWidth: 1.5)
                    )
                }
            }
        }
    }
    
    // Delegate callbacks
    public func didUpdateClues(found: Int, total: Int) {
        self.cluesFound = found
        self.totalClues = total
    }
    
    public func didChangeLevel(levelNumber: Int, title: String) {
        self.currentLevelTitle = title
    }
    
    public func didWinGame() {
        self.hasWonGame = true
    }
    
    public func didGameOver() {
        self.isGameOver = true
    }
}

#if os(iOS)
struct ControlButton: View {
    let icon: String
    let onPress: () -> Void
    let onRelease: () -> Void
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(Color.white.opacity(0.12))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}
#endif
