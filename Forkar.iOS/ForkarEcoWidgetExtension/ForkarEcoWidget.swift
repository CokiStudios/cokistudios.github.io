import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Color Extension for Widget
extension Color {
    static let emerald = Color(red: 16/255, green: 185/255, blue: 129/255)
}

// MARK: - Timeline Provider para Widget de Pantalla de Inicio (iOS 17+)
@available(iOS 17.0, macOS 14.0, *)
struct ForkarEcoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ForkarEcoWidgetEntry {
        let co2 = UserDefaults.standard.double(forKey: "forkar_co2_saved")
        let pts = UserDefaults.standard.integer(forKey: "forkar_eco_points")
        return ForkarEcoWidgetEntry(date: Date(), co2Saved: co2, ecoPoints: pts)
    }

    func getSnapshot(in context: Context, completion: @escaping (ForkarEcoWidgetEntry) -> () ) {
        let co2 = UserDefaults.standard.double(forKey: "forkar_co2_saved")
        let pts = UserDefaults.standard.integer(forKey: "forkar_eco_points")
        let entry = ForkarEcoWidgetEntry(date: Date(), co2Saved: co2, ecoPoints: pts)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> () ) {
        let co2 = UserDefaults.standard.double(forKey: "forkar_co2_saved")
        let pts = UserDefaults.standard.integer(forKey: "forkar_eco_points")
        let entry = ForkarEcoWidgetEntry(date: Date(), co2Saved: co2, ecoPoints: pts)
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct ForkarEcoWidgetEntry: TimelineEntry {
    let date: Date
    let co2Saved: Double
    let ecoPoints: Int
}

// MARK: - Pure Liquid Glass Home Screen Widget UI (iOS 17+)
@available(iOS 17.0, macOS 14.0, *)
struct ForkarHomeScreenWidgetEntryView: View {
    var entry: ForkarEcoWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Fondo translúcido profundo Pure Liquid Glass
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            // Refracción y resplandor esmeralda ambiental de cristal
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.emerald.opacity(0.35),
                    Color.purple.opacity(0.15),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 8,
                endRadius: 160
            )
            .ignoresSafeArea()
            
            // Capa de material de cristal ultrafino
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Reflejo especular superior
            VStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 45)
                Spacer()
            }
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                // Header Glass Pill
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 24, height: 24)
                        Circle()
                            .fill(Color.emerald.opacity(0.3))
                            .frame(width: 24, height: 24)
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .frame(width: 24, height: 24)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.emerald)
                            .shadow(color: Color.emerald.opacity(0.8), radius: 4)
                    }
                    
                    Text("FORKAR ECO")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color.emerald)
                        .tracking(1.2)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.emerald)
                        .frame(width: 6, height: 6)
                        .shadow(color: Color.emerald, radius: 4)
                }
                
                Spacer()
                
                // Métrica Principal: CO2
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.co2Saved, specifier: "%.1f")")
                        .font(.system(size: family == .systemSmall ? 28 : 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("kg CO₂ Ahorrados")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.75))
                        .textCase(.uppercase)
                }
                
                // Métrica Secundaria: Puntos Eco
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("\(entry.ecoPoints) pts ganados")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(.ultraThinMaterial))
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                )
            }
            .padding(14)
        }
        .containerBackground(for: .widget) {
            Color.black
        }
    }
}

// MARK: - Home Screen Widget (iOS 17+)
@available(iOS 17.0, macOS 14.0, *)
struct ForkarHomeScreenWidget: Widget {
    let kind: String = "ForkarHomeScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ForkarEcoWidgetProvider()) { entry in
            ForkarHomeScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Forkar Eco Hub")
        .description("Mira tu consumo y ahorro de CO₂ en puro Liquid Glass.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Live Activity Widget Configuration para Dynamic Island (Pure Liquid Glass - iOS 17+)
#if canImport(ActivityKit)
@available(iOS 17.0, macOS 14.0, *)
struct ForkarEcoActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ForkarEcoActivityAttributes.self) { context in
            // Vista de Pantalla de Bloqueo / StandBy / Banner (Pure Liquid Glass)
            HStack(spacing: 14) {
                // Orbe de cristal líquido con hoja esmeralda brillante
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.emerald.opacity(0.4), Color.emerald.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.7), Color.emerald.opacity(0.4), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.4
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(Color.emerald)
                        .shadow(color: Color.emerald.opacity(0.8), radius: 6)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("FORKAR ECO")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color.emerald)
                            .tracking(1.2)
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 9))
                        Text(context.state.statusMessage)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    
                    Text("\(context.state.co2Saved, specifier: "%.1f") kg CO₂ ahorrados")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Cápsula de cristal para Puntos & Nivel
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("\(context.state.ecoPoints) pts")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(
                        Capsule().stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), Color.yellow.opacity(0.35), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    )
                    
                    Text("FORKAR LIQUID GLASS")
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(Color.emerald.opacity(0.85))
                        .tracking(0.5)
                }
            }
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.emerald.opacity(0.06),
                                    Color.black.opacity(0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.65),
                                    Color.emerald.opacity(0.4),
                                    Color.white.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.3
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Vista Expandida de la Dynamic Island (Hardware iPhone 14 Pro+)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 32, height: 32)
                            Circle()
                                .fill(Color.emerald.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.6), Color.emerald.opacity(0.4), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .frame(width: 32, height: 32)
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.emerald)
                                .shadow(color: Color.emerald.opacity(0.8), radius: 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FORKAR ECO")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(Color.emerald)
                                .tracking(1)
                            Text("\(context.state.co2Saved, specifier: "%.1f") kg CO₂")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.yellow)
                            Text("PUNTOS")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.yellow)
                                .tracking(0.8)
                        }
                        Text("\(context.state.ecoPoints) pts")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 4)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.emerald)
                            .frame(width: 6, height: 6)
                            .shadow(color: Color.emerald, radius: 4)
                        Text(context.state.statusMessage)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                    )
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Impacto ecológico en vivo y meta diaria
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "tree.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.emerald)
                                Text("~\(context.state.treesPreserved, specifier: "%.1f") árboles preservados")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            
                            Spacer()
                            
                            Text("\(Int(context.state.dailyGoalProgress * 100))% Meta Diaria")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(Color.emerald)
                        }
                        .padding(.horizontal, 4)
                        
                        // Barra de progreso Liquid Glass
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(height: 5)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.emerald, Color.green.opacity(0.9)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(14, geo.size.width * CGFloat(context.state.dailyGoalProgress)), height: 5)
                                    .shadow(color: Color.emerald.opacity(0.8), radius: 3)
                            }
                        }
                        .frame(height: 5)
                        
                        // Botón de acción rápida: Pure Liquid Glass Capsule Link
                        Link(destination: URL(string: "forkar://ecoscan")!) {
                            HStack(spacing: 7) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Escanear Código QR Eco")
                                    .font(.system(size: 12, weight: .heavy))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.emerald.opacity(0.4),
                                                    Color.emerald.opacity(0.15)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.7),
                                                    Color.emerald.opacity(0.5),
                                                    Color.white.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.2
                                        )
                                }
                            )
                            .shadow(color: Color.emerald.opacity(0.45), radius: 8, y: 2)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, 2)
                }
            } compactLeading: {
                // Hardware Dynamic Island Compact Leading (Izquierda)
                HStack(spacing: 3) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.emerald)
                    Text("\(context.state.co2Saved, specifier: "%.1f")")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.leading, 5)
            } compactTrailing: {
                // Hardware Dynamic Island Compact Trailing (Derecha)
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("\(context.state.ecoPoints)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 5)
            } minimal: {
                // Hardware Dynamic Island Minimal
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.emerald)
            }
            .widgetURL(URL(string: "forkar://ecoscan"))
        }
    }
}
#endif

// MARK: - Widget Bundle (Entry point for Widget Extension)
@main
struct ForkarWidgetBundle: WidgetBundle {
    var body: some Widget {
        ForkarHomeScreenWidget()
        #if canImport(ActivityKit)
        ForkarEcoActivityWidget()
        #endif
    }
}
