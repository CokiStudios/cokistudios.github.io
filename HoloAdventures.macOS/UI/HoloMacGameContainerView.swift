import SwiftUI
import SpriteKit
import AppKit

// MARK: - Game Coordinator for macOS
public class HoloGameCoordinatorMac: ObservableObject, HoloGameDelegate {
    @Published public var currentLevelTitle: String = "Level 1: The Neon Outskirts"
    @Published public var cluesFound: Int = 0
    @Published public var totalClues: Int = 3
    @Published public var hasWonGame: Bool = false
    @Published public var isGameOver: Bool = false
    
    public init() {}
    
    public func didUpdateClues(found: Int, total: Int) {
        DispatchQueue.main.async {
            self.cluesFound = found
            self.totalClues = total
        }
    }
    
    public func didChangeLevel(levelNumber: Int, title: String) {
        DispatchQueue.main.async {
            self.currentLevelTitle = title
        }
    }
    
    public func didWinGame() {
        DispatchQueue.main.async {
            self.hasWonGame = true
        }
    }
    
    public func didGameOver() {
        DispatchQueue.main.async {
            self.isGameOver = true
        }
    }
}

// MARK: - Mac Keyboard Event Monitor View
struct KeyInputHandlingView: NSViewRepresentable {
    let onKeyDown: (UInt16) -> Void
    let onKeyUp: (UInt16) -> Void
    
    func makeNSView(context: Context) -> KeyInputNSView {
        let view = KeyInputNSView()
        view.onKeyDown = onKeyDown
        view.onKeyUp = onKeyUp
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: KeyInputNSView, context: Context) {}
}

class KeyInputNSView: NSView {
    var onKeyDown: ((UInt16) -> Void)?
    var onKeyUp: ((UInt16) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        onKeyDown?(event.keyCode)
    }
    
    override func keyUp(with event: NSEvent) {
        onKeyUp?(event.keyCode)
    }
}

// MARK: - macOS Game Container
public struct HoloMacGameContainerView: View {
    @StateObject private var coordinator = HoloGameCoordinatorMac()
    @State private var scene: HoloGameScene = {
        let sc = HoloGameScene(size: CGSize(width: 1024, height: 640))
        sc.scaleMode = .aspectFit
        return sc
    }()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.09).ignoresSafeArea()
            
            // 1. Native Keyboard Input Capture
            KeyInputHandlingView(
                onKeyDown: { keyCode in
                    switch keyCode {
                    case 123, 0: // Left Arrow or A
                        scene.moveInput = -1.0
                    case 124, 2: // Right Arrow or D
                        scene.moveInput = 1.0
                    case 49, 126, 13: // Space, Up Arrow, or W
                        scene.playerJump()
                    default:
                        break
                    }
                },
                onKeyUp: { keyCode in
                    switch keyCode {
                    case 123, 0, 124, 2:
                        scene.moveInput = 0.0
                    default:
                        break
                    }
                }
            )
            .frame(width: 0, height: 0)
            
            // 2. SpriteKit Scene
            SpriteView(scene: scene)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .onAppear {
                    scene.gameDelegate = coordinator
                }
            
            // 3. Top Retro Mac HUD
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("🎮 HOLO ADVENTURES [macOS]")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(Color(red: 0.2, green: 0.85, blue: 1.0))
                            
                            Text("by Holo Entertainment CS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Text(coordinator.currentLevelTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Keyboard Hints
                    HStack(spacing: 8) {
                        Text("CONTROLS: [A/D or ◄/►] Move  •  [SPACE / W] Float Jump")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                        
                        // Clues Badge
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                                .font(.system(size: 16))
                            
                            Text("CLUES: \(coordinator.cluesFound) / \(coordinator.totalClues)")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
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
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
            }
            
            // 4. Win Overlay
            if coordinator.hasWonGame {
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
                        
                        Text("Created with ❤️ by Holo Entertainment by CS",)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.6, green: 0.8, blue: 1.0))
                            .padding(.top, 8)
                        
                        Button(action: {
                            coordinator.hasWonGame = false
                            scene.loadLevel(index: 0)
                        }) {
                            Text("PLAY AGAIN")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.2, green: 0.85, blue: 1.0))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
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
}
