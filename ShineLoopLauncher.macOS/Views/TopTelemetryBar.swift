import SwiftUI

// MARK: - Top Telemetry Status Bar
public struct TopTelemetryBar: View {
    @ObservedObject var vm: LauncherViewModel

    public var body: some View {
        HStack(spacing: 16) {
            // Left: Shine Loop Brand & Profile
            HStack(spacing: 12) {
                // Console Logo Emblem
                HStack(spacing: 6) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "00f5d4"), Color(hex: "0284c7")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 14, height: 14)
                        .shadow(color: Color(hex: "00f5d4").opacity(0.6), radius: 6)

                    Text("SHINE LOOP")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "38bdf8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("OS 1.0")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "00f5d4"))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(hex: "00f5d4").opacity(0.15))
                        .clipShape(Capsule())
                }

                Divider()
                    .frame(height: 14)
                    .background(Color.white.opacity(0.2))

                // Active Player Profile
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "38bdf8"))

                    Text("Angel Helium")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Image(systemName: "diamond.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "f59e0b"))
                }
            }

            Spacer()

            // Center: Bubbly Dot Dynamic Island
            BubblyDotView(vm: vm)

            Spacer()

            // Right: Telemetry Indicators (APU, Wi-Fi, Battery, Clock, Settings)
            HStack(spacing: 14) {
                // APU Load
                HStack(spacing: 5) {
                    Image(systemName: "cpu")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "a855f7"))

                    Text("APU \(vm.cpuLoadPercent)%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Wi-Fi Status
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "38bdf8"))

                    Text("\(vm.wifiPingMs)ms")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.75))
                }

                // Battery Status
                HStack(spacing: 4) {
                    Image(systemName: vm.isCharging ? "battery.100.bolt" : "battery.100")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "00f5d4"))

                    Text("\(vm.batteryLevel)%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "00f5d4").opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Clock
                Text(vm.currentTimeString)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Settings Trigger Button
                Button {
                    vm.toggleSettings()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Ajustes del Sistema (Tab / Start)")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Color(hex: "060913").opacity(0.85)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.08)),
            alignment: .bottom
        )
    }
}
