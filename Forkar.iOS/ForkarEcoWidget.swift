import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Timeline Provider para Widget de Pantalla de Inicio
struct ForkarEcoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ForkarEcoWidgetEntry {
        ForkarEcoWidgetEntry(date: Date(), co2Saved: 12.5, ecoPoints: 240)
    }

    func getSnapshot(in context: Context, completion: @escaping (ForkarEcoWidgetEntry) -> () ) {
        let entry = ForkarEcoWidgetEntry(date: Date(), co2Saved: 12.5, ecoPoints: 240)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> () ) {
        let co2 = UserDefaults.standard.double(forKey: "forkar_co2_saved")
        let pts = UserDefaults.standard.integer(forKey: "forkar_eco_points")
        let entry = ForkarEcoWidgetEntry(date: Date(), co2Saved: co2 > 0 ? co2 : 8.5, ecoPoints: pts > 0 ? pts : 150)
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct ForkarEcoWidgetEntry: TimelineEntry {
    let date: Date
    let co2Saved: Double
    let ecoPoints: Int
}

// MARK: - Home Screen Widget UI (Small & Medium)
struct ForkarHomeScreenWidgetEntryView : View {
    var entry: ForkarEcoWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.09, blue: 0.16)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("🌿 FORKAR ECO")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color.emerald)
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .foregroundColor(Color.emerald)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.co2Saved, specifier: "%.1f") kg")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                    Text("CO₂ Ahorrado")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Label("\(entry.ecoPoints) pts", systemImage: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.yellow)
                    Spacer()
                }
            }
            .padding()
        }
    }
}

struct ForkarHomeScreenWidget: Widget {
    let kind: String = "ForkarHomeScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ForkarEcoWidgetProvider()) { entry in
            ForkarHomeScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Forkar Eco Hub")
        .description("Mira tu consumo y ahorro de CO₂ directamente en tu Pantalla de Inicio.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Live Activity Widget Configuration para Dynamic Island
struct ForkarEcoActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ForkarEcoActivityAttributes.self) { context in
            // Vista de Pantalla de Bloqueo / Notificaciones
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.emerald.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Text("🌿")
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("FORKAR ECO HUB")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color.emerald)
                    Text("\(context.state.co2Saved, specifier: "%.1f") kg CO₂ ahorrados")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(context.state.ecoPoints) pts")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.yellow)
                    Text("3 min activo")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(red: 0.06, green: 0.09, blue: 0.16))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Vista Expandida de la Dynamic Island (Mantener presionado la isla)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Text("🌿")
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text("FORKAR ECO")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(Color.emerald)
                            Text("\(context.state.co2Saved, specifier: "%.1f") kg CO₂")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("⭐ PUNTOS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("\(context.state.ecoPoints)")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Monitoreando impacto ecológico...")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Isla compacta Izquierda
                HStack(spacing: 4) {
                    Text("🌿")
                        .font(.system(size: 12))
                    Text("\(context.state.co2Saved, specifier: "%.1f")k")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.emerald)
                }
            } compactTrailing: {
                // Isla compacta Derecha
                Text("\(context.state.ecoPoints)p")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.yellow)
            } minimal: {
                // Isla mínima
                Text("🌿")
                    .font(.system(size: 12))
            }
        }
    }
}

// MARK: - Widget Bundle
struct ForkarWidgetBundle: WidgetBundle {
    var body: some Widget {
        ForkarHomeScreenWidget()
        ForkarEcoActivityWidget()
    }
}
