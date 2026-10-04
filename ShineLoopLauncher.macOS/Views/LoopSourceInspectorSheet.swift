import SwiftUI

// MARK: - Live .loop Script Source Inspector & Hot-Reload Sheet
public struct LoopSourceInspectorSheet: View {
    @ObservedObject var vm: LauncherViewModel
    @State private var editedCode: String = ""

    public var body: some View {
        ZStack {
            Color(hex: "020617").opacity(0.96).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "infinity")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "00f5d4"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("CÓDIGO FUENTE LOOPING (.loop)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.white)

                            Text(vm.activeScriptFile)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "38bdf8"))
                        }
                    }

                    Spacer()

                    // Hot Reload Button
                    Button {
                        vm.saveAndReloadScript(editedCode: editedCode)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .bold))
                            Text("RECARGAR UI DESDE .LOOP")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "00f5d4"), Color(hex: "38bdf8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: Color(hex: "00f5d4").opacity(0.4), radius: 6)
                    }
                    .buttonStyle(.plain)

                    // Close Button
                    Button {
                        vm.isSourceEditorOpen = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(hex: "0b1120"))

                Divider().background(Color.white.opacity(0.08))

                // Source Code Editor Area
                TextEditor(text: $editedCode)
                    .font(.system(size: 12.5, design: .monospaced))
                    .foregroundColor(Color(hex: "00f5d4"))
                    .scrollContentBackground(.hidden)
                    .background(Color(hex: "050914"))
                    .padding(12)

                Divider().background(Color.white.opacity(0.08))

                // Footer Info
                HStack {
                    Text("💡 Este launcher se genera 100% dinámicamente interpretando el código .loop mostrado arriba.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("\(editedCode.components(separatedBy: .newlines).count) líneas")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "090e1a"))
            }
        }
        .onAppear {
            self.editedCode = vm.loopEngine.rawScriptSource
        }
    }
}
