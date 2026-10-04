import SwiftUI

// MARK: - In-Game Looping Execution Overlay
public struct LoopingRunnerSheet: View {
    @ObservedObject var vm: LauncherViewModel
    @State private var autoScroll: Bool = true

    public var body: some View {
        ZStack {
            // Dark Frosted Backdrop
            Color(hex: "020617").opacity(0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header: App Title, PID, Duration & Actions
                HStack(spacing: 16) {
                    // App icon & title
                    if let app = vm.activeLaunchedApp {
                        HStack(spacing: 10) {
                            Image(systemName: app.iconSymbol)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: app.primaryColorHex))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.title)
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundColor(.white)

                                Text("HOLO LOOP OS // C++ RUNTIME ENGINE")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: "00f5d4"))
                            }
                        }
                    }

                    Spacer()

                    // Execution Status Badge
                    statusBadge()

                    // Execution Duration
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))

                        Text(String(format: "%.2f ms", vm.processRunner.currentDurationMs))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "00f5d4"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    // Re-run Button
                    Button {
                        if let app = vm.activeLaunchedApp,
                           case .loopScript(let scriptPath) = app.target {
                            SoundSynthesizer.shared.playLaunchChime()
                            vm.processRunner.execute(scriptPath: scriptPath, appName: app.title)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .bold))
                            Text("Reiniciar")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    // Close / Stop Button [B]
                    Button {
                        vm.closeRunningApp()
                    } label: {
                        HStack(spacing: 5) {
                            Text("B")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(Color(hex: "f43f5e"))
                                .clipShape(Circle())

                            Text("Cerrar")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "f43f5e").opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(hex: "0b1120"))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.white.opacity(0.08)),
                    alignment: .bottom
                )

                // Main Content: Simulated Game HUD on Left + Live Terminal Log on Right
                HStack(spacing: 0) {
                    // Left: Visual Viewport Simulation
                    VStack(spacing: 16) {
                        ZStack {
                            // CRT Mesh Background
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(hex: "00f5d4").opacity(0.4), lineWidth: 1)
                                )

                            // Game canvas presentation
                            VStack(spacing: 14) {
                                Image(systemName: vm.activeLaunchedApp?.iconSymbol ?? "gamecontroller")
                                    .font(.system(size: 54))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "00f5d4"), Color(hex: "38bdf8")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color(hex: "00f5d4").opacity(0.6), radius: 12)

                                Text(vm.activeLaunchedApp?.title ?? "Holo Game")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(.white)

                                Text("MOTOR C++ VULKAN 60HZ // DIRECT BUFFER")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: "00f5d4"))

                                // Simulated in-game score / physics badge
                                HStack(spacing: 16) {
                                    hudMetric(title: "FPS", val: "60.0")
                                    hudMetric(title: "LATENCIA", val: "0.14ms")
                                    hudMetric(title: "ESTADO", val: "ACTIVO")
                                }
                                .padding(.top, 8)
                            }
                            .padding(24)

                            // Retro CRT Scanlines if enabled
                            if vm.isCrtScanlinesEnabled {
                                crtScanlineOverlay()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)

                    Divider()
                        .background(Color.white.opacity(0.08))

                    // Right: Live C++ Engine Output Terminal
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("SALIDA NATIVA STDOUT / LOOPING ENGINE", systemImage: "terminal.fill")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "38bdf8"))

                            Spacer()

                            Text("\(vm.processRunner.outputLines.count) LÍNEAS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                        ScrollViewReader { proxy in
                            ScrollView(.vertical) {
                                LazyVStack(alignment: .leading, spacing: 3) {
                                    ForEach(Array(vm.processRunner.outputLines.enumerated()), id: \.offset) { index, line in
                                        formatConsoleLine(line)
                                            .id(index)
                                    }
                                }
                                .padding(16)
                            }
                            .onChange(of: vm.processRunner.outputLines.count) { _, _ in
                                if autoScroll, let last = vm.processRunner.outputLines.indices.last {
                                    proxy.scrollTo(last, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .frame(width: 460)
                    .background(Color(hex: "030712"))
                }
            }
        }
    }

    private func statusBadge() -> some View {
        Group {
            switch vm.processRunner.state {
            case .idle:
                Text("EN ESPERA")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
            case .launching:
                HStack(spacing: 5) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("INICIANDO...")
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.15))
            case .running(_, let pid):
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("EJECUTANDO (PID: \(pid))")
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
            case .completed(let code, _):
                HStack(spacing: 5) {
                    Circle()
                        .fill(code == 0 ? Color.cyan : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(code == 0 ? "EXITOSO (0)" : "SALIDA (\(code))")
                        .foregroundColor(code == 0 ? Color.cyan : Color.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.cyan.opacity(0.15))
            case .failed(let err):
                Text("ERROR: \(err)")
                    .foregroundColor(Color(hex: "f43f5e"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "f43f5e").opacity(0.15))
            }
        }
        .font(.system(size: 10, weight: .bold, design: .monospaced))
        .clipShape(Capsule())
    }

    private func hudMetric(title: String, val: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
            Text(val)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "00f5d4"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func formatConsoleLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        var color = Color.white.opacity(0.85)

        if trimmed.hasPrefix("[OK]") || trimmed.hasPrefix("✅") {
            color = Color(hex: "00f5d4")
        } else if trimmed.hasPrefix("[ERROR]") || trimmed.hasPrefix("❌") || trimmed.contains("FAILED") {
            color = Color(hex: "f43f5e")
        } else if trimmed.hasPrefix("[EXEC]") || trimmed.hasPrefix("▶") {
            color = Color(hex: "38bdf8")
        } else if trimmed.hasPrefix("[PYTHON") {
            color = Color(hex: "f59e0b")
        } else if trimmed.hasPrefix("[UI]") || trimmed.hasPrefix("[ENTITY]") {
            color = Color(hex: "a855f7")
        } else if trimmed.hasPrefix("[OUTPUT]") {
            color = Color.white
        }

        return Text(line)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(color)
            .textSelection(.enabled)
    }

    private func crtScanlineOverlay() -> some View {
        VStack(spacing: 3) {
            ForEach(0..<60, id: \.self) { _ in
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(height: 1)
                Spacer()
            }
        }
        .allowsHitTesting(false)
    }
}
