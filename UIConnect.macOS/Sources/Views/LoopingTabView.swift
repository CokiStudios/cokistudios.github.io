import SwiftUI

// MARK: - Looping Engine & Pipeline Operator (|>) Tester View
public struct LoopingTabView: View {
    @ObservedObject var vm: UIConnectViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Section Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("Motor Loop OS v2.5 — REPL & Pipeline")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(UITheme.textPrimary)
                    Text("Ejecución directa de snippets en el compilador C++ con el operador pipeline (|>) y síntesis acústica.")
                        .font(.system(size: 12))
                        .foregroundColor(UITheme.textSecondary)
                }

                // Quick Action Snippet Buttons
                VStack(alignment: .leading, spacing: 10) {
                    Text("Acciones Rápidas del Motor")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(UITheme.primary)

                    HStack(spacing: 10) {
                        QuickSnippetButton(title: "Escanear ADB", icon: "cable.connector", color: UITheme.primary) {
                            vm.refreshDevices()
                        }

                        QuickSnippetButton(title: "Auditar con |>", icon: "flowchart.fill", color: UITheme.purple) {
                            vm.runPipelineAudit()
                        }

                        QuickSnippetButton(title: "Instalar C2 (USB)", icon: "arrow.down.doc.fill", color: UITheme.btnBg) {
                            vm.installSelectedModule()
                        }

                        QuickSnippetButton(title: "Publicar OTA", icon: "cloud.fill", color: UITheme.accent) {
                            vm.publishSelectedModuleOTA()
                        }

                        QuickSnippetButton(title: "Tono APU (880Hz)", icon: "speaker.wave.3.fill", color: UITheme.yellow) {
                            vm.playApuAudioFeedback()
                        }
                    }
                }
                .padding(14)
                .glassCard()

                // Interactive Code Editor
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Editor de Código Looping v2.5")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(UITheme.textPrimary)

                        Spacer()

                        Button(action: {
                            vm.runCustomLoopCode()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                Text("Ejecutar en Loop OS")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(UITheme.green)
                            .foregroundColor(.black)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isBusy)
                    }

                    TextEditor(text: $vm.customLoopCode)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(UITheme.textPrimary)
                        .padding(10)
                        .frame(minHeight: 140)
                        .background(UITheme.logBg)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(UITheme.cardBorder, lineWidth: 1))
                }
                .padding(14)
                .glassCard()
            }
            .padding(18)
        }
    }
}

// MARK: - Quick Snippet Action Button
struct QuickSnippetButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.18))
            .foregroundColor(color)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
