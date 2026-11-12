import SwiftUI

// MARK: - Native Header with Hardware Profile Badges
public struct HeaderView: View {
    @ObservedObject var vm: UIConnectViewModel
    @ObservedObject var sound = SoundSynthesizer.shared

    public var body: some View {
        HStack(spacing: 16) {
            // App Branding & Icon
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(UITheme.neonGradient)
                        .frame(width: 38, height: 38)
                        .shadow(color: UITheme.primary.opacity(0.5), radius: 6, x: 0, y: 0)

                    Image(systemName: "cpu.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#0b0f19"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("✦ UI CONNECT (PC)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(UITheme.primary)

                        Text("v2.5")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(UITheme.primary.opacity(0.18))
                            .foregroundColor(UITheme.primary)
                            .cornerRadius(4)
                    }

                    Text("Shine OS Component 2 (.c2) Native Suite • Coki Studios")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(UITheme.textSecondary)
                }
            }

            Spacer()

            // Hardware & Engine Badges
            HStack(spacing: 10) {
                // Device count badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(vm.devices.isEmpty ? Color.gray : UITheme.green)
                        .frame(width: 8, height: 8)
                        .shadow(color: (vm.devices.isEmpty ? Color.gray : UITheme.green).opacity(0.8), radius: 4)

                    Text(vm.devices.isEmpty ? "Sin Celulares" : "\(vm.devices.count) Conectado(s)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(UITheme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(UITheme.cardBg)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(UITheme.cardBorder, lineWidth: 1))

                // APU Hardware Profile Badge
                HStack(spacing: 6) {
                    Image(systemName: "bolt.badge.clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(UITheme.accent)

                    Text("XUI • 240 FPS Direct-Vulkan")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(UITheme.accent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(UITheme.accent.opacity(0.12))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(UITheme.accent.opacity(0.4), lineWidth: 1))

                // Refresh Button
                Button(action: {
                    vm.refreshAll()
                }) {
                    Image(systemName: vm.isScanning ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(UITheme.textPrimary)
                        .rotationEffect(.degrees(vm.isScanning ? 360 : 0))
                        .animation(vm.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: vm.isScanning)
                        .padding(8)
                        .background(UITheme.cardBg)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(UITheme.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Actualizar dispositivos y módulos")

                // Mute / Sound Toggle
                Button(action: {
                    sound.isMuted.toggle()
                    if !sound.isMuted { sound.playApuChime() }
                }) {
                    Image(systemName: sound.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(sound.isMuted ? UITheme.textSecondary : UITheme.yellow)
                        .padding(8)
                        .background(UITheme.cardBg)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(UITheme.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Silenciar / Reactivar efectos acústicos de hardware")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(UITheme.cardBg.opacity(0.95))
        .overlay(Rectangle().frame(height: 1).foregroundColor(UITheme.cardBorder), alignment: .bottom)
    }
}
