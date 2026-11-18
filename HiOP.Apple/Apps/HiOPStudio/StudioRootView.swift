import HiOPCore
import SwiftUI
import UniformTypeIdentifiers

struct StudioRootView: View {
    @StateObject private var vm = StudioViewModel()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        NavigationSplitView {
            List(selection: Binding<StudioViewModel.StudioSection?>(
                get: { vm.selectedSection },
                set: { if let val = $0 { vm.selectedSection = val } }
            )) {
                ForEach(StudioViewModel.StudioSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label(section.rawValue, systemImage: section.icon)
                    }
                    .tag(section)
                }
            }
            .navigationTitle("hiOP Studio")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.activeChannel.displayName)
                        .font(.caption.weight(.bold))
                    Text("Arch 3.1A • Zero-Python Core")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
            }
        } detail: {
            detailContent
        }
        .preferredColorScheme(vm.colorSchemePreference == 1 ? .dark : (vm.colorSchemePreference == 2 ? .light : nil))
    }

    @ViewBuilder
    private var detailContent: some View {
        switch vm.selectedSection {
        case .ide:
            IdeStudioView(vm: vm)
        case .stage:
            QuantumStageView(vm: vm)
        case .toolchain:
            ToolchainView(vm: vm)
        case .smiledev:
            SmiledevView(vm: vm)
        case .updates:
            UpdatesView(vm: vm)
        case .settings:
            SettingsView(vm: vm)
        }
    }
}

struct IdeStudioView: View {
    @ObservedObject var vm: StudioViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingImporter = false
    @State private var showingInspector = true

    var body: some View {
        VStack(spacing: 0) {
            actionToolbar
            Divider()
            if sizeClass == .compact {
                VStack(spacing: 0) {
                    editorPane
                    Divider()
                    consolePane.frame(height: 150)
                }
            } else {
                HStack(spacing: 0) {
                    presetsSidebar.frame(width: 210)
                    Divider()
                    VStack(spacing: 0) {
                        tabsStrip
                        Divider()
                        editorPane
                        Divider()
                        consolePane.frame(height: 160)
                    }
                    if showingInspector {
                        Divider()
                        inspectorPane.frame(width: 250)
                    }
                }
            }
        }
        .navigationTitle(vm.activeTab?.title ?? "IDE Studio")
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.plainText, .sourceCode]) { result in
            if case .success(let url) = result, url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                if let text = try? String(contentsOf: url, encoding: .utf8) {
                    vm.openFile(url: url, content: text)
                }
            }
        }
    }

    private var actionToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    ForEach(WorkspaceTemplates.arch31APresets) { preset in
                        Button(preset.title) { vm.openPreset(preset) }
                    }
                } label: {
                    Label("Plantillas", systemImage: "doc.badge.plus")
                }

                Button { showingImporter = true } label: {
                    Label("Abrir", systemImage: "folder")
                }

                Button {
                    vm.runActiveCode(openStageIfVisual: false)
                } label: {
                    Label("Ejecutar", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)

                Button {
                    vm.runActiveCode(openStageIfVisual: true)
                } label: {
                    Label("Stage 3D", systemImage: "cube.transparent")
                }
                .buttonStyle(.bordered)

                Button { vm.formatActiveCode() } label: {
                    Label("FMT", systemImage: "wand.and.stars")
                }
                Button { vm.encodeActiveInvis() } label: {
                    Label("Invis", systemImage: "lock.shield")
                }
                Button { showingInspector.toggle() } label: {
                    Label("AST", systemImage: "list.bullet.indent")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private var presetsSidebar: some View {
        List {
            Section("Proyectos Arch 3.1A") {
                ForEach(WorkspaceTemplates.arch31APresets) { preset in
                    Button {
                        vm.openPreset(preset)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.fileName)
                                .font(.caption.weight(.semibold))
                            Text(preset.summary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var tabsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(vm.tabs) { tab in
                    HStack(spacing: 6) {
                        Text(tab.title)
                            .font(.caption.monospaced())
                        if vm.tabs.count > 1 {
                            Button {
                                vm.closeTab(tab.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tab.id == vm.activeTab?.id ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                    .onTapGesture {
                        vm.activeTabID = tab.id
                        vm.reanalyzeActiveTab()
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
    }

    private var editorPane: some View {
        TextEditor(text: Binding(
            get: { vm.activeTab?.content ?? "" },
            set: { vm.updateActiveCode($0) }
        ))
        .font(.system(.body, design: .monospaced))
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var inspectorPane: some View {
        List {
            Section("Diagnósticos") {
                ForEach(vm.diagnostics) { diag in
                    HStack(alignment: .top, spacing: 6) {
                        Text(diag.severity)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(diag.severity == "Error" ? .red : (diag.severity == "Warning" ? .orange : .green))
                        Text("L\(diag.line): \(diag.message)")
                            .font(.caption2)
                    }
                }
            }
            Section("Árbol AST") {
                ForEach(vm.astNodes) { node in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(node.kind): \(node.name)")
                            .font(.caption.weight(.semibold))
                        ForEach(node.children) { child in
                            Text("  • \(child.kind): \(child.name)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var consolePane: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 3) {
                ForEach(Array(vm.consoleLogs.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)
        }
        .background(.background.secondary)
    }
}

struct QuantumStageView: View {
    @ObservedObject var vm: StudioViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(vm.stageUI.title)
                        .font(.headline)
                    Text("Score: \(vm.stageSnapshot.score) • Vidas: \(vm.stageSnapshot.lives) • \(vm.stageSnapshot.is3DMode ? "3D Z-Buffer" : "2D ASM Stage")")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(vm.isStageRunning ? "Pausar" : "Reanudar") {
                    vm.isStageRunning ? vm.stopStageLoop() : vm.startStageLoop()
                }
                Button("3D / 2D") {
                    vm.engineBridge.toggle3D()
                    vm.tickStage()
                }
                Button("Cámara") {
                    vm.engineBridge.cycleCamera3D()
                    vm.tickStage()
                }
                Button("Reiniciar") {
                    _ = vm.engineBridge.restart()
                    vm.tickStage()
                }
            }
            .padding(.horizontal)

            GeometryReader { geo in
                ZStack {
                    if let cg = vm.stageImage {
                        Image(decorative: cg, scale: 1.0)
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ContentUnavailableView("Stage Inactivo", systemImage: "cube.transparent", description: Text("Pulsa Ejecutar o Stage 3D para renderizar en C++17 Nativo."))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)

            if !vm.stageUI.cards.isEmpty || !vm.stageUI.buttons.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.stageUI.cards) { card in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.title).font(.caption.bold())
                                Text(card.text).font(.caption2).foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        ForEach(vm.stageUI.buttons) { btn in
                            Button(btn.text) {
                                let logs = vm.engineBridge.clickButton(btn.action.isEmpty ? btn.text : btn.action)
                                vm.consoleLogs.append(contentsOf: logs)
                                vm.tickStage()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack(spacing: 12) {
                holdControl("◀", mask: .left)
                holdControl("▶", mask: .right)
                holdControl("▲ Salto", mask: .jump)
                holdControl("🔥 Disparar", mask: .shoot)
                holdControl("⚡ Dash", mask: .dash)
            }
            .padding(.bottom, 10)
        }
        .padding(.top, 10)
        .onAppear {
            if vm.stageImage == nil {
                vm.runActiveCode(openStageIfVisual: false)
            }
        }
        .onDisappear { vm.stopStageLoop() }
    }

    private func holdControl(_ label: String, mask: StageInputMask) -> some View {
        Text(label)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(vm.activeInputMask.contains(mask) ? Color.accentColor : Color.secondary.opacity(0.2))
            .foregroundStyle(vm.activeInputMask.contains(mask) ? .white : .primary)
            .clipShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in vm.activeInputMask.insert(mask) }
                    .onEnded { _ in vm.activeInputMask.remove(mask) }
            )
    }
}

struct ToolchainView: View {
    @ObservedObject var vm: StudioViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button("Doctor") { vm.refreshDoctor() }
                    Button("SelfTest C++17") { vm.runToolchainSelfTest() }
                    Button("Benchmark VM") { vm.runToolchainBench() }
                    Button("Invis Compile LPBN") { vm.encodeActiveInvis() }
                }
                .buttonStyle(.bordered)

                ForEach(vm.doctorChecks) { item in
                    HStack {
                        Text(item.status)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.green.opacity(0.2))
                            .clipShape(Capsule())
                        VStack(alignment: .leading) {
                            Text(item.component).font(.subheadline.weight(.semibold))
                            Text(item.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if !vm.toolchainOutput.isEmpty {
                    Text(vm.toolchainOutput)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
        }
        .navigationTitle("Toolchain Arch 3.1A")
    }
}

struct SmiledevView: View {
    @ObservedObject var vm: StudioViewModel
    @State private var search = ""

    var filtered: [SmileModuleItem] {
        if search.trimmingCharacters(in: .whitespaces).isEmpty { return vm.liveModules }
        let q = search.lowercased()
        return vm.liveModules.filter {
            $0.name.lowercased().contains(q) || ($0.description ?? "").lowercased().contains(q)
        }
    }

    var body: some View {
        List {
            if vm.modulesLoading {
                ProgressView("Consultando repo.cokistudios.com/modules...")
            } else if let err = vm.modulesError {
                Text(err).foregroundStyle(.red)
            } else if filtered.isEmpty {
                Text("Pulsa Actualizar para cargar módulos desde repo.cokistudios.com/modules.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filtered) { mod in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(mod.name).font(.headline)
                            Spacer()
                            if let v = mod.version {
                                Text("v\(v)").font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            if let lang = mod.language {
                                Text(lang).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(.blue.opacity(0.15)).clipShape(Capsule())
                            }
                        }
                        if let desc = mod.description, !desc.isEmpty {
                            Text(desc).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Buscar LoopModules")
        .navigationTitle("Smiledev Registry")
        .toolbar {
            Button("Actualizar") {
                Task { await vm.loadSmiledevModules() }
            }
        }
        .task {
            if vm.liveModules.isEmpty { await vm.loadSmiledevModules() }
        }
    }
}

struct UpdatesView: View {
    @ObservedObject var vm: StudioViewModel

    var body: some View {
        Form {
            Section("Canal Activo") {
                Picker("Canal", selection: $vm.activeChannel) {
                    ForEach(LoopingChannel.allCases) { ch in
                        Text("\(ch.displayName) (\(ch.tierLabel))").tag(ch)
                    }
                }
                .onChange(of: vm.activeChannel) { _, ch in
                    vm.engineBridge.setChannel(ch)
                    vm.refreshDoctor()
                }
            }
            Section("Registro Oficial (engine.cokistudios.com)") {
                Text(vm.updateStatusText).font(.caption)
                if let m = vm.latestManifest {
                    LabeledContent("Versión", value: m.version ?? "-")
                    LabeledContent("Arquitectura", value: m.arch_version ?? "-")
                    LabeledContent("Fecha", value: m.release_date ?? "-")
                    if let notes = m.release_notes {
                        Text(notes).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Button(vm.updatesLoading ? "Comprobando..." : "Comprobar Actualizaciones") {
                    Task { await vm.checkUpdates() }
                }
                .disabled(vm.updatesLoading)
            }
        }
        .navigationTitle("Actualizaciones")
    }
}

struct SettingsView: View {
    @ObservedObject var vm: StudioViewModel

    var body: some View {
        Form {
            Section("Apariencia") {
                Picker("Tema", selection: $vm.colorSchemePreference) {
                    Text("Sistema").tag(0)
                    Text("Oscuro").tag(1)
                    Text("Claro").tag(2)
                }
                .pickerStyle(.segmented)
            }
            Section("Información del Motor") {
                LabeledContent("Motor", value: "CLoopingStageCore C++17 + ASM")
                LabeledContent("Dependencias externas", value: "Ninguna (Zero Python / Zero WebView)")
            }
        }
        .navigationTitle("Ajustes")
    }
}
