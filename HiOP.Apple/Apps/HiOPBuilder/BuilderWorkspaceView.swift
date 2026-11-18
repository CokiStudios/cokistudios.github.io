import HiOPCore
import SwiftUI

struct BuilderWorkspaceView: View {
    @StateObject private var vm = BuilderViewModel()
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var rightTab: Int = 0 // 0=Stage, 1=Code
    @State private var compactMode: Int = 0 // 0=Bloques, 1=Stage, 2=Código

    var body: some View {
        NavigationStack {
            Group {
                if sizeClass == .compact {
                    compactLayout
                } else {
                    wideTabletLayout
                }
            }
            .navigationTitle("hiOP Builder")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Menu {
                        ForEach(BlockLoopCompiler.starterKits) { kit in
                            Button {
                                vm.loadStarterKit(kit)
                            } label: {
                                Label(kit.title, systemImage: "square.stack.3d.up.fill")
                            }
                        }
                    } label: {
                        Label("Plantillas", systemImage: "sparkles")
                    }

                    Button {
                        vm.runBlocksInStage()
                    } label: {
                        Label("Ejecutar Bloques", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                }
            }
        }
        .onDisappear { vm.stopStageLoop() }
    }

    private var wideTabletLayout: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                paletteColumn
                    .frame(width: min(290, max(230, geo.size.width * 0.24)))
                Divider()
                workspaceCanvas
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider()
                previewColumn
                    .frame(width: min(440, max(310, geo.size.width * 0.36)))
            }
        }
    }

    private var compactLayout: some View {
        VStack(spacing: 0) {
            Picker("Vista", selection: $compactMode) {
                Text("Bloques").tag(0)
                Text("Stage").tag(1)
                Text("Código").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()
            if compactMode == 0 {
                VStack(spacing: 0) {
                    workspaceCanvas
                    Divider()
                    compactPaletteStrip
                }
            } else if compactMode == 1 {
                stagePreviewPane
            } else {
                generatedCodePane
            }
        }
    }

    private var paletteColumn: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(BlockCategory.allCases) { cat in
                        Button {
                            vm.selectedCategory = cat
                        } label: {
                            Label(cat.rawValue, systemImage: cat.systemIcon)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(vm.selectedCategory == cat ? colorFromHex(cat.accentHex).opacity(0.22) : Color.secondary.opacity(0.12))
                                .foregroundStyle(vm.selectedCategory == cat ? colorFromHex(cat.accentHex) : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
            Divider()
            List {
                Section(vm.selectedCategory.rawValue) {
                    ForEach(BlockKind.allCases.filter { $0.category == vm.selectedCategory }) { kind in
                        Button {
                            withAnimation(.spring(duration: 0.22)) {
                                vm.addBlock(kind)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(colorFromHex(kind.category.accentHex))
                                    .frame(width: 8, height: 26)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(kind.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text("Tocar para encajar")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(colorFromHex(kind.category.accentHex))
                            }
                            .padding(.vertical, 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var compactPaletteStrip: some View {
        VStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(BlockCategory.allCases) { cat in
                        Button(cat.rawValue) { vm.selectedCategory = cat }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(vm.selectedCategory == cat ? colorFromHex(cat.accentHex).opacity(0.25) : Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BlockKind.allCases.filter { $0.category == vm.selectedCategory }) { kind in
                        Button {
                            vm.addBlock(kind)
                        } label: {
                            Label(kind.title, systemImage: "plus")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(colorFromHex(kind.category.accentHex).opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .background(.bar)
    }

    private var workspaceCanvas: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if vm.blocks.isEmpty {
                    ContentUnavailableView(
                        "Lienzo de Bloques Vacío",
                        systemImage: "puzzlepiece.extension",
                        description: Text("Toca bloques de la paleta o elige una plantilla arriba para empezar.")
                    )
                    .padding(.top, 60)
                } else {
                    ForEach(vm.blocks) { block in
                        blockCard(block, parentID: nil)
                    }
                }
            }
            .padding()
        }
        .background(.background.secondary)
    }

    private func blockCard(_ block: LoopBlock, parentID: UUID?) -> AnyView {
        let accent = colorFromHex(block.kind.category.accentHex)
        return AnyView(VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: block.kind.category.systemIcon)
                    .foregroundStyle(accent)
                Text(block.kind.title)
                    .font(.subheadline.weight(.bold))
                Spacer()
                if parentID == nil {
                    Button { vm.moveBlock(id: block.id, delta: -1) } label: {
                        Image(systemName: "arrow.up")
                    }
                    Button { vm.moveBlock(id: block.id, delta: 1) } label: {
                        Image(systemName: "arrow.down")
                    }
                    Button { vm.duplicateBlock(block) } label: {
                        Image(systemName: "plus.square.on.square")
                    }
                }
                Button(role: .destructive) {
                    vm.removeBlock(id: block.id, parentID: parentID)
                } label: {
                    Image(systemName: "trash")
                }
            }
            .buttonStyle(.borderless)

            if !block.params.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                    ForEach(block.params) { param in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(param.label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            TextField(param.label, text: Binding(
                                get: { param.value },
                                set: { vm.updateParam(blockID: parentID ?? block.id, childID: parentID == nil ? nil : block.id, paramID: param.id, value: $0) }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .font(.caption.monospaced())
                        }
                    }
                }
            }

            if block.kind.isContainer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Dentro del bloque:")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Menu("+ Añadir hijo") {
                            Button("Imprimir (say)") { vm.addChildBlock(.sayLog, to: block.id) }
                            Button("Variable") { vm.addChildBlock(.declareVar, to: block.id) }
                            Button("Tono Audio") { vm.addChildBlock(.playTone, to: block.id) }
                            Button("Fórmula py!()") { vm.addChildBlock(.pyMathFastPath, to: block.id) }
                        }
                        .font(.caption)
                    }
                    ForEach(block.children) { child in
                        blockCard(child, parentID: block.id)
                            .padding(.leading, 14)
                    }
                }
                .padding(8)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accent.opacity(0.65), lineWidth: 1.6)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accent)
                .frame(width: 5)
                .padding(.vertical, 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12)))
    }

    private var previewColumn: some View {
        VStack(spacing: 0) {
            Picker("Panel", selection: $rightTab) {
                Text("Stage en Vivo").tag(0)
                Text("Código .loop").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(10)

            Divider()
            if rightTab == 0 {
                stagePreviewPane
            } else {
                generatedCodePane
            }
        }
    }

    private var stagePreviewPane: some View {
        VStack(spacing: 10) {
            HStack {
                Text(vm.stageSnapshot.is3DMode ? "Quantum 3D" : "Arcade 2D")
                    .font(.caption.weight(.bold))
                Spacer()
                Text("Score: \(vm.stageSnapshot.score) • FPS: \(vm.stageSnapshot.fps)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Button("3D/2D") {
                    vm.engineBridge.toggle3D()
                    vm.tickStage()
                }
                .font(.caption)
            }
            .padding(.horizontal)

            GeometryReader { geo in
                if let cg = vm.stageImage {
                    Image(decorative: cg, scale: 1.0)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    ContentUnavailableView("Pulsa Ejecutar Bloques", systemImage: "play.circle")
                }
            }
            .padding(.horizontal)

            // Virtual iPad Gamepad
            HStack(spacing: 10) {
                gamepadButton("◀", mask: .left)
                gamepadButton("▶", mask: .right)
                gamepadButton("▲", mask: .jump)
                gamepadButton("🔥", mask: .shoot)
                gamepadButton("⚡", mask: .dash)
            }
            .padding(.horizontal)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(vm.consoleLogs.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption2.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
            }
            .frame(height: 110)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .padding(.top, 8)
    }

    private var generatedCodePane: some View {
        ScrollView {
            Text(vm.generatedCode)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(.background.secondary)
    }

    private func gamepadButton(_ title: String, mask: StageInputMask) -> some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(vm.activeInputMask.contains(mask) ? Color.teal : Color.secondary.opacity(0.2))
            .foregroundStyle(vm.activeInputMask.contains(mask) ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in vm.activeInputMask.insert(mask) }
                    .onEnded { _ in vm.activeInputMask.remove(mask) }
            )
    }

    private func colorFromHex(_ hex: String) -> Color {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") { clean.removeFirst() }
        guard clean.count >= 6, let val = UInt64(clean.prefix(6), radix: 16) else { return .teal }
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}
