import SwiftUI

public struct NativeTerminalPanelView: View {
    @ObservedObject var vm: IDEViewModel

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.22, green: 0.74, blue: 0.97))

                    Text("CONSOLA & RUNTIME C++")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }

                // Execution Status Badge
                executionBadge()

                Spacer()

                // Benchmark duration
                if vm.executionDurationMs > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text(String(format: "%.2f ms", vm.executionDurationMs))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.96, blue: 0.83))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }

                // Stop Button
                if case .running = vm.executionState {
                    Button {
                        vm.stopRunningProcess()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 9))
                            Text("Detener")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }

                // Clear Logs Button
                Button {
                    vm.clearTerminal()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("Limpiar consola")

                // Hide Terminal Button
                Button {
                    vm.isTerminalVisible = false
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("Ocultar consola")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(red: 0.04, green: 0.06, blue: 0.09))

            Divider().background(Color.white.opacity(0.08))

            // Live Log Lines Output
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        if vm.terminalLogs.isEmpty {
                            Text("⚡ Consola en espera. Presiona ▶ Run (Cmd+R) para compilar y ejecutar código Looping.")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.35))
                                .padding(12)
                        } else {
                            ForEach(Array(vm.terminalLogs.enumerated()), id: \.offset) { index, line in
                                formatTerminalLine(line)
                                    .id(index)
                            }
                        }
                    }
                    .padding(10)
                }
                .onChange(of: vm.terminalLogs.count) { _, _ in
                    if let last = vm.terminalLogs.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
            .background(Color(red: 0.02, green: 0.04, blue: 0.07))
        }
    }

    private func executionBadge() -> some View {
        Group {
            switch vm.executionState {
            case .idle:
                EmptyView()
            case .compiling:
                Text("COMPILANDO...")
                    .foregroundColor(.yellow)
            case .running(_, let pid):
                Text("EJECUTANDO (PID: \(pid))")
                    .foregroundColor(Color(red: 0.0, green: 0.96, blue: 0.83))
            case .completed(let code, _):
                Text(code == 0 ? "OK (0)" : "ERROR (\(code))")
                    .foregroundColor(code == 0 ? .green : .red)
            case .failed:
                Text("FALLO")
                    .foregroundColor(.red)
            }
        }
        .font(.system(size: 9, weight: .black, design: .monospaced))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    private func formatTerminalLine(_ line: String) -> some View {
        var color = Color.white.opacity(0.85)
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("✅") || trimmed.hasPrefix("[OK]") {
            color = Color(red: 0.0, green: 0.96, blue: 0.83)
        } else if trimmed.hasPrefix("❌") || trimmed.hasPrefix("[ERROR]") {
            color = Color(red: 1.0, green: 0.4, blue: 0.4)
        } else if trimmed.hasPrefix("⚡") || trimmed.hasPrefix("▶") || trimmed.hasPrefix("=") {
            color = Color(red: 0.22, green: 0.74, blue: 0.97)
        } else if trimmed.hasPrefix("[PYTHON") {
            color = Color(red: 1.0, green: 0.75, blue: 0.2)
        } else if trimmed.hasPrefix("[UI]") || trimmed.hasPrefix("[ENTITY]") {
            color = Color(red: 0.75, green: 0.52, blue: 1.0)
        }

        return Text(line)
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(color)
            .textSelection(.enabled)
    }
}
