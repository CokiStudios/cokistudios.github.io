import SwiftUI
import AppKit

// MARK: - Shine Studio: Developer, Identity & Ecosystem Hub
public struct ShineStudioView: View {
    @ObservedObject var vm: LauncherViewModel

    public init(vm: LauncherViewModel) {
        self.vm = vm
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Banner
                studioHeaderBanner

                // Grid of Studio Modules
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    // 1. hiOP Studio IDE
                    studioCard(
                        icon: "chevron.left.forwardslash.chevron.right",
                        color: "38bdf8",
                        badge: "NATIVO",
                        title: "hiOP IDE Studio",
                        subtitle: "Editor Monaco, compilador Looping C++ en vivo y preview 120Hz.",
                        actionTitle: "ABRIR IDE"
                    ) {
                        vm.launchAppByTitle("hiOP IDE Studio")
                    }

                    // 2. CS ID & Coki Account Manager
                    studioCard(
                        icon: "person.badge.key.fill",
                        color: "00f5d4",
                        badge: "SECURE ENCLAVE",
                        title: "Coki Studios ID",
                        subtitle: "Gestión de identidad universal, passkeys SEP y salas E2EE CSMS.",
                        actionTitle: "GESTIONAR CUENTA"
                    ) {
                        if let url = URL(string: "https://cokistudios.com/cuenta") {
                            NSWorkspace.shared.open(url)
                        }
                    }

                    // 3. Felte App Store
                    studioCard(
                        icon: "bag.fill",
                        color: "ec4899",
                        badge: "STORE",
                        title: "Felte App Store",
                        subtitle: "Tienda descentralizada de aplicaciones y paquetes para Loop OS.",
                        actionTitle: "EXPLORAR APPS"
                    ) {
                        if let url = URL(string: "https://cokistudios.com/felte.html") {
                            NSWorkspace.shared.open(url)
                        }
                    }

                    // 4. Looping Compiler & Benchmark Core
                    studioCard(
                        icon: "cpu.fill",
                        color: "a855f7",
                        badge: "v2.5.0",
                        title: "Looping Engine Core",
                        subtitle: "Compilador dual Looping (.loop) y Ruuping Rust (.ruup).",
                        actionTitle: "INSPECCIONAR FUENTE"
                    ) {
                        vm.isSourceEditorOpen = true
                    }

                    // 5. Cloudflare Workers Edge Bridge
                    studioCard(
                        icon: "cloud.fill",
                        color: "f59e0b",
                        badge: "EDGE LATENCY 12ms",
                        title: "Coki Cloud Edge",
                        subtitle: "Sincronización de rutas, mapas offline y telemetría en tiempo real.",
                        actionTitle: "VER ESTADO NUBE"
                    ) {
                        if let url = URL(string: "https://cokistudios.com/status") {
                            NSWorkspace.shared.open(url)
                        }
                    }

                    // 6. Shine Maps Creator & POI Manager
                    studioCard(
                        icon: "map.fill",
                        color: "10b981",
                        badge: "CARPLAY SYNC",
                        title: "Shine Maps Studio",
                        subtitle: "Editor de rutas y polilíneas de congestión Mapbox Directions GL.",
                        actionTitle: "ABRIR MAPAS"
                    ) {
                        if let url = URL(string: "https://cokistudios.com") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Studio Header Banner
    private var studioHeaderBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("SHINE STUDIO")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("DEVELOPER & CLOUD HUB")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color(hex: "00f5d4"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "00f5d4").opacity(0.15))
                        .clipShape(Capsule())
                }

                Text("Herramientas de ingeniería, identidad criptográfica de hardware y compilación universal.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Button {
                vm.isSourceEditorOpen.toggle()
                SoundSynthesizer.shared.playActionBlip()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 12))
                    Text("CONSOLA / SCRIPT .LOOP")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundColor(Color(hex: "00f5d4"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: "00f5d4").opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "00f5d4").opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Color(hex: "0b1120").opacity(0.7).background(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Studio Card Component
    private func studioCard(
        icon: String,
        color: String,
        badge: String,
        title: String,
        subtitle: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: color).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: color))
                }

                Spacer()

                Text(badge)
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: color))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: color).opacity(0.15))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Button {
                action()
                SoundSynthesizer.shared.playActionBlip()
            } label: {
                HStack(spacing: 4) {
                    Text(actionTitle)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(Color(hex: color))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(hex: color).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(height: 190)
        .background(Color(hex: "0b1120").opacity(0.6).background(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
