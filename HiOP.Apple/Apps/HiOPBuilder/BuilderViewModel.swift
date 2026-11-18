import Foundation
import HiOPCore
import SwiftUI

@MainActor
public final class BuilderViewModel: ObservableObject {
    @Published public var blocks: [LoopBlock] = []
    @Published public var selectedCategory: BlockCategory = .program
    @Published public var generatedCode: String = ""
    @Published public var consoleLogs: [String] = []
    @Published public var stageSnapshot = StageSnapshot()
    @Published public var stageImage: CGImage?
    @Published public var isStageRunning: Bool = false
    @Published public var activeInputMask: StageInputMask = []

    public let engineBridge = LoopingCoreBridge()
    private var stageTimer: Timer?

    public init() {
        loadStarterKit(BlockLoopCompiler.starterKits[0])
    }

    public func loadStarterKit(_ kit: BlockStarterKit) {
        blocks = kit.blocks
        recompile()
        runBlocksInStage()
    }

    public func addBlock(_ kind: BlockKind) {
        blocks.append(LoopBlock(kind: kind))
        recompile()
    }

    public func addChildBlock(_ kind: BlockKind, to parentID: UUID) {
        guard let idx = blocks.firstIndex(where: { $0.id == parentID }) else { return }
        blocks[idx].children.append(LoopBlock(kind: kind))
        recompile()
    }

    public func updateParam(blockID: UUID, childID: UUID? = nil, paramID: String, value: String) {
        if let childID {
            guard let pIdx = blocks.firstIndex(where: { $0.id == blockID }),
                  let cIdx = blocks[pIdx].children.firstIndex(where: { $0.id == childID }),
                  let paramIdx = blocks[pIdx].children[cIdx].params.firstIndex(where: { $0.id == paramID }) else { return }
            blocks[pIdx].children[cIdx].params[paramIdx].value = value
        } else {
            guard let bIdx = blocks.firstIndex(where: { $0.id == blockID }),
                  let paramIdx = blocks[bIdx].params.firstIndex(where: { $0.id == paramID }) else { return }
            blocks[bIdx].params[paramIdx].value = value
        }
        recompile()
    }

    public func moveBlock(from source: IndexSet, to destination: Int) {
        blocks.move(fromOffsets: source, toOffset: destination)
        recompile()
    }

    public func moveBlock(id: UUID, delta: Int) {
        guard let idx = blocks.firstIndex(where: { $0.id == id }) else { return }
        let target = idx + delta
        guard target >= 0 && target < blocks.count else { return }
        blocks.swapAt(idx, target)
        recompile()
    }

    public func duplicateBlock(_ block: LoopBlock) {
        let copy = LoopBlock(kind: block.kind, params: block.params, children: block.children)
        if let idx = blocks.firstIndex(where: { $0.id == block.id }) {
            blocks.insert(copy, at: idx + 1)
        } else {
            blocks.append(copy)
        }
        recompile()
    }

    public func removeBlock(id: UUID, parentID: UUID? = nil) {
        if let parentID, let pIdx = blocks.firstIndex(where: { $0.id == parentID }) {
            blocks[pIdx].children.removeAll(where: { $0.id == id })
        } else {
            blocks.removeAll(where: { $0.id == id })
        }
        recompile()
    }

    public func recompile() {
        generatedCode = BlockLoopCompiler.compile(blocks)
    }

    public func runBlocksInStage() {
        recompile()
        consoleLogs = ["[hiOP Builder] Compilando \(blocks.count) bloque(s) a Looping Arch 3.1A..."]
        let res = engineBridge.execute(code: generatedCode, channel: .prod)
        if !res.logs.isEmpty {
            consoleLogs.append(contentsOf: res.logs)
        }
        consoleLogs.append(res.ok
            ? String(format: "[OK] Stage activo en %.2f ms", res.elapsedMs)
            : "[ERROR] Revisa los bloques")

        stageSnapshot = engineBridge.snapshot(viewWidth: 560, viewHeight: 340)
        stageImage = engineBridge.renderStageCGImage(snapshot: stageSnapshot, width: 560, height: 340)
        startStageLoop()
    }

    public func startStageLoop() {
        stageTimer?.invalidate()
        isStageRunning = true
        stageTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickStage()
            }
        }
    }

    public func stopStageLoop() {
        stageTimer?.invalidate()
        stageTimer = nil
        isStageRunning = false
    }

    public func tickStage() {
        engineBridge.setInput(activeInputMask)
        let snap = engineBridge.step(dt: 1.0 / 60.0, viewWidth: 560, viewHeight: 340)
        stageSnapshot = snap
        stageImage = engineBridge.renderStageCGImage(snapshot: snap, width: 560, height: 340)
    }
}
