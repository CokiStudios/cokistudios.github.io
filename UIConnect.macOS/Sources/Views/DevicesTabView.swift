import SwiftUI

// MARK: - Devices Tab View (Live ADB Devices List & Telemetry)
public struct DevicesTabView: View {
    @ObservedObject var vm: UIConnectViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Section Title
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dispositivos Shine OS Detectados")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(UITheme.textPrimary)
                        Text("Enlace de depuración a ultra-baja latencia vía ADB USB o Wi-Fi.")
                            .font(.system(size: 12))
                            .foregroundColor(UITheme.textSecondary)
                    }
                    Spacer()

                    Button(action: {
                        vm.refreshDevices()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Escanear ADB")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(UITheme.btnBg)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                if vm.devices.isEmpty {
                    // Empty state card
                    VStack(spacing: 14) {
                        Image(systemName: "cable.connector.slash")
                            .font(.system(size: 40))
                            .foregroundColor(UITheme.textSecondary)

                        Text("No se detectaron celulares conectados")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(UITheme.textPrimary)

                        Text("Conecta tu celular Shine (X1, Xa1, f1, i1, A1, Nomad 1) por cable USB con 'Depuración por USB' habilitada, o enlaza vía Wi-Fi con 'adb pair <ip:puerto>'.")
                            .font(.system(size: 12))
                            .foregroundColor(UITheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 500)

                        HStack(spacing: 12) {
                            Button("Escanear Ahora") {
                                vm.refreshDevices()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(UITheme.btnBg)

                            Button("Emitir Tono APU") {
                                vm.playApuAudioFeedback()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .padding(.horizontal, 20)
                    .glassCard()
                } else {
                    // Device Grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 14)], spacing: 14) {
                        ForEach(vm.devices) { device in
                            DeviceCard(device: device, isSelected: vm.selectedDevice?.serial == device.serial) {
                                vm.selectedDevice = device
                            }
                        }
                    }
                }

                // Supported Shine OS Models Banner
                VStack(alignment: .leading, spacing: 8) {
                    Text("Matriz de Compatibilidad Shine OS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(UITheme.primary)

                    HStack(spacing: 12) {
                        ModelBadge(name: "Shine X1 / Xa1", profile: "xUI 240Hz", color: UITheme.primary)
                        ModelBadge(name: "Shine f1 / i1 / fW1", profile: "flUI 120Hz", color: UITheme.purple)
                        ModelBadge(name: "Shine Nomad 1", profile: "Aqua UI", color: UITheme.accent)
                        ModelBadge(name: "Shine A1", profile: "hiUI Lite", color: UITheme.yellow)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
            }
            .padding(18)
        }
    }
}

// MARK: - Individual Device Card
struct DeviceCard: View {
    let device: ADBDevice
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: device.isWiFi ? "wifi" : "cable.connector")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(device.isWiFi ? UITheme.accent : UITheme.primary)

                        Text(device.displayName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(UITheme.textPrimary)
                    }

                    Spacer()

                    Text(device.state.uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(device.state == "device" ? UITheme.green.opacity(0.2) : UITheme.yellow.opacity(0.2))
                        .foregroundColor(device.state == "device" ? UITheme.green : UITheme.yellow)
                        .cornerRadius(4)
                }

                Divider().background(UITheme.cardBorder)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("SERIAL / IP")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(UITheme.textSecondary)
                        Text(device.serial)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(UITheme.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("BATERÍA")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(UITheme.textSecondary)
                        HStack(spacing: 4) {
                            Image(systemName: "battery.100")
                                .font(.system(size: 11))
                                .foregroundColor(UITheme.green)
                            Text(device.batteryLevel)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(UITheme.textPrimary)
                        }
                    }
                }
            }
            .padding(14)
            .glassCard(borderColor: isSelected ? UITheme.primary : UITheme.cardBorder)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supported Model Badge
struct ModelBadge: View {
    let name: String
    let profile: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(UITheme.textPrimary)
            Text(profile)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.3), lineWidth: 1))
    }
}
