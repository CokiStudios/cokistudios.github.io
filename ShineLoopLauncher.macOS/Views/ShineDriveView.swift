import SwiftUI
import AppKit

// MARK: - Shine Drive: In-Car Infotainment & Cockpit Dashboard
public struct ShineDriveView: View {
    @ObservedObject var vm: LauncherViewModel

    // Animation states
    @State private var isPulsingEco: Bool = false
    @State private var selectedPoi: String? = nil

    public init(vm: LauncherViewModel) {
        self.vm = vm
    }

    public var body: some View {
        ZStack {
            if vm.isHudMirrored {
                // Pure OLED Mirrored HUD for Windshield Reflection
                mirroredWindshieldHUD
                    .scaleEffect(x: -1, y: 1) // Inverts horizontally for glass reflection
                    .background(Color.black.ignoresSafeArea())
            } else {
                // Standard Luxury In-Car Infotainment Cockpit
                cockpitDashboard
            }
        }
    }

    // MARK: - Cockpit Dashboard Layout
    private var cockpitDashboard: some View {
        HStack(spacing: 16) {
            // Left Column: Speedometer Cluster & Vehicle Status
            VStack(spacing: 14) {
                speedometerGaugeCluster
                vehicleTelemetryPill
            }
            .frame(width: 380)

            // Center Column: Shine Maps Navigation & Route Guidance
            VStack(spacing: 14) {
                routeManeuverCard
                mapPreviewWidget
                quickPoiCarousel
            }
            .frame(maxWidth: .infinity)

            // Right Column: Infotainment Media, CSMS SOS & Eco Telemetry
            VStack(spacing: 14) {
                mediaPlayerWidget
                forkarEcoSavingsCard
                csmsEmergencyHub
            }
            .frame(width: 320)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    // MARK: - 1. Speedometer Cluster
    private var speedometerGaugeCluster: some View {
        VStack(spacing: 10) {
            ZStack {
                // Outer Glow & Circular Gauge Arc
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 16)
                    .frame(width: 250, height: 250)

                // Speed Arc (0 to 240 km/h mapped to 0.75 circle)
                Circle()
                    .trim(from: 0.15, to: 0.15 + (CGFloat(min(vm.speedKmh, 240)) / 240.0) * 0.70)
                    .stroke(
                        AngularGradient(
                            colors: [Color(hex: "00f5d4"), Color(hex: "38bdf8"), Color(hex: "f59e0b"), Color(hex: "ef4444")],
                            center: .center,
                            startAngle: .degrees(135),
                            endAngle: .degrees(405)
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: 250, height: 250)
                    .shadow(color: Color(hex: "00f5d4").opacity(0.4), radius: 12)

                // Center Digital Readout
                VStack(spacing: 0) {
                    Text("\(Int(vm.speedKmh))")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "38bdf8")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())

                    Text(vm.speedUnit)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "00f5d4"))
                        .tracking(2)

                    // Speed limit badge
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .stroke(Color(hex: "ef4444"), lineWidth: 3)
                                .frame(width: 30, height: 30)
                            Text("\(vm.speedLimit)")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }

                        if vm.speedKmh > Double(vm.speedLimit) {
                            Text("EXCESO")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(Color(hex: "ef4444"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "ef4444").opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 6)
                }

                // HUD Mirrored Mode Quick Toggle Button
                VStack {
                    Spacer()
                    Button {
                        vm.isHudMirrored.toggle()
                        SoundSynthesizer.shared.playActionBlip()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.and.right.mirror")
                                .font(.system(size: 10))
                            Text("MODO PARABRISAS (H)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(Color(hex: "38bdf8"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "0284c7").opacity(0.2))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: "38bdf8").opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 6)
                }
                .frame(height: 250)
            }
            .frame(height: 260)
        }
        .padding(14)
        .background(
            Color(hex: "0b1120").opacity(0.7)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 2. Vehicle Telemetry Pill
    private var vehicleTelemetryPill: some View {
        HStack(spacing: 12) {
            telemetryMetric(icon: "bolt.car.fill", color: "00f5d4", title: "AUTONOMÍA", value: "\(vm.estimatedRangeKm) km")
            Divider().frame(height: 24).background(Color.white.opacity(0.1))
            telemetryMetric(icon: "road.lanes", color: "38bdf8", title: "DISTANCIA", value: String(format: "%.1f km", vm.tripDistanceKm))
            Divider().frame(height: 24).background(Color.white.opacity(0.1))
            telemetryMetric(icon: "gauge.with.needle", color: "f59e0b", title: "ECO SCORE", value: "\(vm.forkarEcoScore)%")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "0b1120").opacity(0.7).background(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func telemetryMetric(icon: String, color: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: color))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 3. Route Maneuver Guidance Card
    private var routeManeuverCard: some View {
        HStack(spacing: 16) {
            // Maneuver Icon Box
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [Color(hex: "0284c7"), Color(hex: "00f5d4")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 58, height: 58)
                    .shadow(color: Color(hex: "00f5d4").opacity(0.4), radius: 8)

                Image(systemName: vm.currentManeuverIcon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("EN \(vm.distanceToNextManeuverMeters) METROS")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color(hex: "00f5d4"))

                    Text("•  ETA \(vm.etaTimeString) (\(vm.remainingMinutes) min)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }

                Text(vm.nextStreetName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Traffic Congestion Color Segment Indicator (Mapbox GL)
                HStack(spacing: 4) {
                    Text("Tráfico:")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 2) {
                        Capsule().fill(Color(hex: "00f5d4")).frame(width: 40, height: 4)
                        Capsule().fill(Color(hex: "00f5d4")).frame(width: 30, height: 4)
                        Capsule().fill(Color(hex: "f59e0b")).frame(width: 25, height: 4)
                        Capsule().fill(Color(hex: "00f5d4")).frame(width: 50, height: 4)
                    }

                    Text("Fluido con desaceleración menor")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "00f5d4"))
                }
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(hex: "0b1120").opacity(0.7).background(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 4. Map Preview Widget (Shine Maps & Forkar Hybrid)
    private var mapPreviewWidget: some View {
        ZStack {
            // Stylized Dark Cyber Map Canvas
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "080e1a"))

            // Abstract Map Grid & Simulated Polyline
            GeometryReader { geo in
                ZStack {
                    // Street Grid Lines
                    Path { path in
                        for x in stride(from: 0, to: geo.size.width, by: 40) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        }
                        for y in stride(from: 0, to: geo.size.height, by: 40) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.03), lineWidth: 1)

                    // Navigation Route Polyline with Congestion colors
                    Path { path in
                        path.move(to: CGPoint(x: 40, y: geo.size.height - 30))
                        path.addCurve(
                            to: CGPoint(x: geo.size.width - 60, y: 40),
                            control1: CGPoint(x: geo.size.width * 0.35, y: geo.size.height * 0.8),
                            control2: CGPoint(x: geo.size.width * 0.55, y: geo.size.height * 0.2)
                        )
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "00f5d4"), Color(hex: "0284c7"), Color(hex: "f59e0b"), Color(hex: "00f5d4")],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .shadow(color: Color(hex: "00f5d4").opacity(0.5), radius: 8)

                    // Current Vehicle Marker (Car Icon with Ripple)
                    Circle()
                        .fill(Color(hex: "00f5d4").opacity(0.25))
                        .frame(width: 32, height: 32)
                        .position(x: 40, y: geo.size.height - 30)

                    Image(systemName: "location.north.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "00f5d4"))
                        .rotationEffect(.degrees(35))
                        .position(x: 40, y: geo.size.height - 30)

                    // Destination Pin
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "ef4444"))
                        .position(x: geo.size.width - 60, y: 40)
                        .shadow(color: Color(hex: "ef4444").opacity(0.6), radius: 6)
                }
            }

            // Map Controls Overlay
            VStack {
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: "00f5d4")).frame(width: 6, height: 6)
                        Text("SHINE MAPS GL // EN VIVO")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())

                    Spacer()

                    Button {
                        // Open full Shine Maps in external app or internal view
                        NSWorkspace.shared.open(URL(string: "https://cokistudios.com")!)
                    } label: {
                        HStack(spacing: 4) {
                            Text("ABRIR MAPA COMPLETO")
                                .font(.system(size: 10, weight: .bold))
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "0284c7").opacity(0.6))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)

                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 5. Quick POI Search Carousel
    private var quickPoiCarousel: some View {
        HStack(spacing: 8) {
            poiPill(icon: "fuelpump.fill", label: "Gasolina", color: "f59e0b")
            poiPill(icon: "bolt.car.fill", label: "Carga EV", color: "00f5d4")
            poiPill(icon: "fork.knife", label: "Comida", color: "ec4899")
            poiPill(icon: "parkingsign.circle.fill", label: "Parking", color: "38bdf8")
            poiPill(icon: "house.fill", label: "Casa", color: "a855f7")
            poiPill(icon: "building.2.fill", label: "Estudio", color: "06b6d4")
        }
    }

    private func poiPill(icon: String, label: String, color: String) -> some View {
        Button {
            selectedPoi = label
            SoundSynthesizer.shared.playActionBlip()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: color))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(hex: "0b1120").opacity(0.8))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 6. Media Player Widget
    private var mediaPlayerWidget: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Album Art
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [Color(hex: "ec4899"), Color(hex: "8b5cf6")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)

                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.mediaTrackTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(vm.mediaArtist)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()
            }

            // Transport Controls
            HStack(spacing: 20) {
                Button {
                    SoundSynthesizer.shared.playActionBlip()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)

                Button {
                    vm.isPlayingMedia.toggle()
                    SoundSynthesizer.shared.playActionBlip()
                } label: {
                    Image(systemName: vm.isPlayingMedia ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "00f5d4"))
                }
                .buttonStyle(.plain)

                Button {
                    SoundSynthesizer.shared.playActionBlip()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(hex: "0b1120").opacity(0.7).background(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 7. Forkar Eco Savings Card
    private var forkarEcoSavingsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "10b981"))
                    Text("FORKAR ECO VALIDATOR")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color(hex: "10b981"))
                }
                Spacer()
                Text("OPTIMIZADO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "10b981"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: "10b981").opacity(0.2))
                    .clipShape(Capsule())
            }

            Text("Has ahorrado 1.8 L de combustible y reducido 4.2 kg de CO2 en esta ruta.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(2)
        }
        .padding(12)
        .background(Color(hex: "064e3b").opacity(0.3).background(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "10b981").opacity(0.3), lineWidth: 1))
    }

    // MARK: - 8. CSMS Emergency & Family Hub
    private var csmsEmergencyHub: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Circle().fill(Color(hex: "00f5d4")).frame(width: 6, height: 6)
                    Text("CSMS E2EE HUB")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "00f5d4"))
                }
                Text("Familia conectada (4 miembros)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Button {
                SoundSynthesizer.shared.playActionBlip()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 11))
                    Text("SOS")
                        .font(.system(size: 11, weight: .black))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(hex: "ef4444"))
                .clipShape(Capsule())
                .shadow(color: Color(hex: "ef4444").opacity(0.5), radius: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(hex: "0b1120").opacity(0.7).background(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 9. Pure OLED Mirrored Windshield HUD
    private var mirroredWindshieldHUD: some View {
        VStack(spacing: 30) {
            Spacer()

            // Giant Neon Speed Readout
            VStack(spacing: 4) {
                Text("\(Int(vm.speedKmh))")
                    .font(.system(size: 150, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "00f5d4"))
                    .shadow(color: Color(hex: "00f5d4").opacity(0.8), radius: 30)

                Text(vm.speedUnit.uppercased())
                    .font(.system(size: 24, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "00f5d4").opacity(0.8))
            }

            // Next Turn Guidance Indicator
            HStack(spacing: 24) {
                Image(systemName: vm.currentManeuverIcon)
                    .font(.system(size: 64, weight: .heavy))
                    .foregroundColor(Color(hex: "38bdf8"))
                    .shadow(color: Color(hex: "38bdf8").opacity(0.8), radius: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vm.distanceToNextManeuverMeters) M")
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Text(vm.nextStreetName.uppercased())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                }
            }

            Spacer()

            // Exit HUD instructions
            Button {
                vm.isHudMirrored = false
                SoundSynthesizer.shared.playActionBlip()
            } label: {
                Text("TOCA O PRESIONA (H) PARA SALIR DEL MODO PARABRISAS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
