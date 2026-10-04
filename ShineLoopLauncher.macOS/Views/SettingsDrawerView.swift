import SwiftUI

// MARK: - Hardware & System Settings Drawer
public struct SettingsDrawerView: View {
    @ObservedObject var vm: LauncherViewModel

    public var body: some View {
        ZStack(alignment: .trailing) {
            // Semi-transparent backdrop to dismiss
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        vm.isSettingsDrawerOpen = false
                    }
                }

            // Drawer Panel
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "00f5d4"))

                        Text("AJUSTES DE LA CONSOLA")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            vm.isSettingsDrawerOpen = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }

                Divider().background(Color.white.opacity(0.1))

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // 0. Target UI Profile
                        sectionTitle("ARQUITECTURA DE INTERFAZ (SHINE UI / XUI / flUI)")
                        VStack(spacing: 8) {
                            ForEach(TargetUIProfile.allCases) { prof in
                                let isSelected = (vm.targetUIProfile == prof)
                                Button {
                                    vm.setTargetUIProfile(prof)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: prof.iconSymbol)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(prof.primaryColor)
                                            .frame(width: 28, height: 28)
                                            .background(prof.primaryColor.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(prof.displayName)
                                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))

                                                Text("\(prof.targetFps) Hz")
                                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                    .foregroundColor(prof.primaryColor)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 1)
                                                    .background(prof.primaryColor.opacity(0.15))
                                                    .clipShape(Capsule())
                                            }

                                            Text(prof.subtitle)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white.opacity(0.45))
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 15))
                                                .foregroundColor(prof.primaryColor)
                                        }
                                    }
                                    .padding(12)
                                    .background(isSelected ? prof.primaryColor.opacity(0.12) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? prof.primaryColor : Color.white.opacity(0.06), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // 1. Performance Profile
                        sectionTitle("PERFIL DE RENDIMIENTO (APU / FPS)")
                        VStack(spacing: 8) {
                            ForEach(PerformanceProfile.allCases, id: \.self) { prof in
                                let isSelected = (vm.performanceProfile == prof)
                                Button {
                                    vm.performanceProfile = prof
                                    SoundSynthesizer.shared.playActionBlip()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(prof.rawValue)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(isSelected ? .white : .white.opacity(0.7))

                                            Text("Tasa de refresco objetivo: \(prof.targetFps) Hz V-Sync Direct")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white.opacity(0.45))
                                        }

                                        Spacer()

                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 15))
                                                .foregroundColor(prof.badgeColor)
                                        }
                                    }
                                    .padding(12)
                                    .background(isSelected ? prof.badgeColor.opacity(0.15) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? prof.badgeColor : Color.white.opacity(0.06), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // 2. Audio DSP & Tones
                        sectionTitle("AUDIO HARDWARE DSP (ALSA / AV)")
                        VStack(spacing: 12) {
                            HStack {
                                Text("Volumen Master:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))

                                Spacer()

                                Text("\(Int(vm.soundVolume * 100))%")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: "00f5d4"))
                            }

                            Slider(value: $vm.soundVolume, in: 0...1)
                                .accentColor(Color(hex: "00f5d4"))

                            Toggle(isOn: $vm.isSoundMuted) {
                                Text("Silenciar Efectos de Consola")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .toggleStyle(.switch)

                            Button {
                                SoundSynthesizer.shared.playBootChime()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "speaker.wave.3.fill")
                                        .font(.system(size: 12))
                                    Text("Probar Chime Looping (587Hz -> 880Hz)")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(Color(hex: "00f5d4"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(hex: "00f5d4").opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // 3. Display & Aesthetics
                        sectionTitle("PANTALLA Y CHASIS")
                        VStack(spacing: 12) {
                            Toggle(isOn: $vm.isHandheldBezelEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Marco de Consola Shine Loop")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                    Text("Muestra el chasis físico portátil con sticks y botones")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.45))
                                }
                            }
                            .toggleStyle(.switch)

                            Toggle(isOn: $vm.isCrtScanlinesEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Filtro Scanlines CRT Retro")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                    Text("Emula la cuadrícula de fósforo de arcade 90s")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.45))
                                }
                            }
                            .toggleStyle(.switch)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // 4. Storage Telemetry (LoopFS NVMe)
                        sectionTitle("ALMACENAMIENTO NVMe (LOOPFS v2.0)")
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(String(format: "%.1f", vm.storageUsedGb)) GB Usados")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(String(format: "%.0f", vm.totalStorageGb)) GB NVMe")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "00f5d4"), Color(hex: "38bdf8")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * CGFloat(vm.storageUsedGb / vm.totalStorageGb))
                                }
                            }
                            .frame(height: 8)

                            Text("Formato: LoopFS Linux Native • Cifrado Hardware SEP")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "38bdf8"))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(24)
            .frame(width: 380)
            .background(
                Color(hex: "060a16")
                    .background(.ultraThinMaterial)
            )
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(Color.white.opacity(0.1)),
                alignment: .leading
            )
            .transition(.move(edge: .trailing))
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "00f5d4"))
    }
}
