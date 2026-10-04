import SwiftUI

public struct hiOPWorkspaceView: View {
    @StateObject private var vm = IDEViewModel()

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.05, blue: 0.08).ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Native Toolbar
                toolbarView()

                Divider().background(Color.white.opacity(0.08))

                // 2. Editor Workspace with Sidebar and Tabs
                HStack(spacing: 0) {
                    // Collapsible Sidebar
                    if vm.isSidebarVisible {
                        NativeFileTreeView(vm: vm)
                            .frame(width: 240)

                        Divider().background(Color.white.opacity(0.08))
                    }

                    // Main Editor Area
                    VStack(spacing: 0) {
                        // File Tabs Bar
                        tabsBarView()

                        Divider().background(Color.white.opacity(0.06))

                        // Active Code Editor
                        if let tab = vm.activeTab {
                            NativeCodeEditorView(
                                text: Binding(
                                    get: { tab.content },
                                    set: { vm.updateActiveTabContent($0) }
                                ),
                                onSave: {
                                    vm.saveActiveFile()
                                }
                            )
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "infinity")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(red: 0.0, green: 0.96, blue: 0.83).opacity(0.4))

                                Text("Ningún archivo abierto")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))

                                Button("Abrir Proyecto de Ejemplo (.loop)") {
                                    vm.loadWorkspace()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(red: 0.0, green: 0.96, blue: 0.83))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }

                        // Terminal Drawer
                        if vm.isTerminalVisible {
                            Divider().background(Color.white.opacity(0.08))

                            NativeTerminalPanelView(vm: vm)
                                .frame(height: 200)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RunLoopCode"))) { _ in
            vm.runActiveFile()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SaveLoopCode"))) { _ in
            vm.saveActiveFile()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewLoopFile"))) { _ in
            vm.createNewLoopFile()
        }
    }

    // MARK: - Native Toolbar
    private func toolbarView() -> some View {
        HStack(spacing: 12) {
            // Sidebar Toggle
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    vm.isSidebarVisible.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(vm.isSidebarVisible ? Color(red: 0.0, green: 0.96, blue: 0.83) : .white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help("Alternar barra lateral")

            // Looping Brand Badge
            HStack(spacing: 6) {
                Text("L∞ping")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 0.96, blue: 0.83))

                Text("hiOP IDE Studio")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))

                Text("v2.5 NATIVE")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(Color(red: 0.63, green: 0.52, blue: 1.0))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.63, green: 0.52, blue: 1.0).opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            // Run Button (Primary Action)
            Button {
                vm.runActiveFile()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("EJECUTAR (⌘R)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.0, green: 0.96, blue: 0.83), Color(red: 0.22, green: 0.74, blue: 0.97)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: Color(red: 0.0, green: 0.96, blue: 0.83).opacity(0.4), radius: 6)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("r", modifiers: .command)

            // Target Selector Dropdown
            Menu {
                ForEach(vm.availableTargets, id: \.self) { target in
                    Button(target) {
                        vm.targetPlatform = target
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.0, green: 0.96, blue: 0.83))

                    Text(vm.targetPlatform)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton)

            // Save File Button
            Button {
                vm.saveActiveFile()
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("s", modifiers: .command)
            .help("Guardar archivo activo (⌘S)")

            // Terminal Toggle Button
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    vm.isTerminalVisible.toggle()
                }
            } label: {
                Image(systemName: "terminal")
                    .font(.system(size: 12))
                    .foregroundColor(vm.isTerminalVisible ? Color(red: 0.22, green: 0.74, blue: 0.97) : .white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help("Alternar consola inferior")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(red: 0.03, green: 0.05, blue: 0.08))
    }

    // MARK: - File Tabs Bar
    private func tabsBarView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 1) {
                ForEach(vm.openTabs) { tab in
                    let isActive = (vm.activeTabId == tab.id)

                    Button {
                        vm.activeTabId = tab.id
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "infinity")
                                .font(.system(size: 10))
                                .foregroundColor(isActive ? Color(red: 0.0, green: 0.96, blue: 0.83) : .white.opacity(0.5))

                            Text(tab.title)
                                .font(.system(size: 11, weight: isActive ? .bold : .regular))
                                .foregroundColor(isActive ? .white : .white.opacity(0.65))

                            if tab.isDirty {
                                Circle()
                                    .fill(Color(red: 0.0, green: 0.96, blue: 0.83))
                                    .frame(width: 5, height: 5)
                            }

                            // Close Tab Button
                            Button {
                                vm.closeTab(id: tab.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isActive ? Color(red: 0.05, green: 0.08, blue: 0.13) : Color.clear)
                        .overlay(
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(isActive ? Color(red: 0.0, green: 0.96, blue: 0.83) : Color.clear),
                            alignment: .bottom
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color(red: 0.03, green: 0.05, blue: 0.08))
    }
}
