import SwiftUI

// MARK: - Reactive Controls & Hardware APU Settings View
public struct ControlsTabView: View {
    @ObservedObject var vm: UIConnectViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("Controles Reactivos & Enlace APU")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(UITheme.textPrimary)
                    Text("Configuración de buffer, latencia de renderizado y sincronización en caliente.")
                        .font(.system(size: 12))
                        .foregroundColor(UITheme.textSecondary)
                }

                // Sliders Box
                VStack(alignment: .leading, spacing: 18) {
                    // Slider 1: ADB Transfer Rate
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tasa de Transferencia ADB (KB/s)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(UITheme.textPrimary)

                            Spacer()

                            Text("\(Int(vm.transferBufferKb)) KB/s")
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(UITheme.primary.opacity(0.18))
                                .foregroundColor(UITheme.primary)
                                .cornerRadius(5)
                        }

                        Slider(value: $vm.transferBufferKb, in: 64...4096, step: 64)
                            .tint(UITheme.primary)

                        HStack {
                            Text("64 KB/s (Bajo consumo)")
                            Spacer()
                            Text("4096 KB/s (Turbo USB 3.2)")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(UITheme.textSecondary)
                    }

                    Divider().background(UITheme.cardBorder)

                    // Slider 2: Hot-Reload Sensitivity
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Sensibilidad de Hot-Reload (ms)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(UITheme.textPrimary)

                            Spacer()

                            Text("\(Int(vm.hotReloadMs)) ms")
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(UITheme.purple.opacity(0.18))
                                .foregroundColor(UITheme.purple)
                                .cornerRadius(5)
                        }

                        Slider(value: $vm.hotReloadMs, in: 50...1000, step: 25)
                            .tint(UITheme.purple)

                        HStack {
                            Text("50 ms (Instantáneo)")
                            Spacer()
                            Text("1000 ms (Ahorro de batería)")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(UITheme.textSecondary)
                    }
                }
                .padding(16)
                .glassCard()

                // Toggles Box
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $vm.autoSyncOnSave) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Sincronización al Guardar en c2-modules/")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(UITheme.textPrimary)
                            Text("Detecta modificaciones en paquetes .c2 y los transfiere inmediatamente al celular.")
                                .font(.system(size: 11))
                                .foregroundColor(UITheme.textSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: UITheme.primary))

                    Divider().background(UITheme.cardBorder)

                    Toggle(isOn: $vm.vulkanApuMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Modo Direct-Vulkan APU Low-Latency (<0.2ms)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(UITheme.textPrimary)
                            Text("Prioriza el frame pacing de 240Hz en Shine X1 eliminando colas de composición intermedias.")
                                .font(.system(size: 11))
                                .foregroundColor(UITheme.textSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: UITheme.accent))
                }
                .padding(16)
                .glassCard()

                // Transmission Progress Box
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Estado del Buffer y Cola de Instalación")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(UITheme.textPrimary)

                        Spacer()

                        Text("\(Int(vm.transmissionProgress))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(UITheme.accent)
                    }

                    ProgressView(value: vm.transmissionProgress, total: 100)
                        .tint(UITheme.accent)
                }
                .padding(16)
                .glassCard()
            }
            .padding(18)
        }
    }
}
