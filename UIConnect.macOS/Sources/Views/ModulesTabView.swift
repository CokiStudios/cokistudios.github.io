import SwiftUI

// MARK: - Component 2 (.c2) Modules Gallery & Management View
public struct ModulesTabView: View {
    @ObservedObject var vm: UIConnectViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Top Action Toolbar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Módulos Component 2 (.c2) Activos")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(UITheme.textPrimary)
                        Text("Paquetes modulares en c2-modules/. Listos para empuje USB o despliegue OTA.")
                            .font(.system(size: 12))
                            .foregroundColor(UITheme.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Button(action: {
                            vm.installSelectedModule()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Instalar en Celular (USB)")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(UITheme.btnBg)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.selectedModule == nil || vm.isBusy)

                        Button(action: {
                            vm.publishSelectedModuleOTA()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "cloud.fill")
                                Text("Publicar OTA")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(UITheme.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.selectedModule == nil || vm.isBusy)

                        Button(action: {
                            vm.runPipelineAudit()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.shield.fill")
                                Text("Auditar con |>")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(UITheme.cardBg)
                            .foregroundColor(UITheme.primary)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(UITheme.primary.opacity(0.5), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isBusy)
                    }
                }

                // Grid of Modules
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 380), spacing: 14)], spacing: 14) {
                    ForEach(vm.modules) { module in
                        ModuleCard(module: module, isSelected: vm.selectedModule?.fileName == module.fileName) {
                            vm.selectedModule = module
                        }
                    }
                }

                // Selected Module Detailed Inspector
                if let mod = vm.selectedModule {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Detalles de Paquete: \(mod.fileName)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(UITheme.primary)

                            Spacer()

                            Text("SHA-256 Firmado")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(UITheme.green.opacity(0.15))
                                .foregroundColor(UITheme.green)
                                .cornerRadius(4)
                        }

                        HStack(spacing: 24) {
                            InfoItem(title: "Component ID", value: mod.componentId)
                            InfoItem(title: "Tema de Hardware", value: mod.theme)
                            InfoItem(title: "Target Refresh", value: "\(mod.targetFps) Hz")
                            InfoItem(title: "Tamaño", value: mod.fileSizeFormatted)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Checksum SHA-256:")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(UITheme.textSecondary)
                            Text(mod.sha256Checksum)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(UITheme.textPrimary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(14)
                    .glassCard(borderColor: UITheme.primary.opacity(0.6))
                }
            }
            .padding(18)
        }
    }
}

// MARK: - Individual Module Card
struct ModuleCard: View {
    let module: C2Module
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 14))
                            .foregroundColor(UITheme.primary)

                        Text(module.fileName)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(UITheme.textPrimary)
                    }

                    Spacer()

                    Text(module.badgeText)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(UITheme.accent.opacity(0.18))
                        .foregroundColor(UITheme.accent)
                        .cornerRadius(4)
                }

                Divider().background(UITheme.cardBorder)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("COMPONENTE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(UITheme.textSecondary)
                        Text(module.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(UITheme.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("TAMAÑO")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(UITheme.textSecondary)
                        Text(module.fileSizeFormatted)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(UITheme.textPrimary)
                    }
                }
            }
            .padding(14)
            .glassCard(borderColor: isSelected ? UITheme.primary : UITheme.cardBorder)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helper Info Item
struct InfoItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(UITheme.textSecondary)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(UITheme.textPrimary)
        }
    }
}
