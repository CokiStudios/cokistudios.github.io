import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 🌿 FORKAR ECO VIEW — FORKAR FOR PC (macOS)
// Dashboard de Sostenibilidad, Métricas de CO2 y Red de Estaciones
// ══════════════════════════════════════════════════════════════════

struct ForkarEcoView: View {
    @EnvironmentObject var manager: SupabaseManager
    @Binding var selectedTab: NavigationTab
    
    @State private var co2SavedKg: Double = 142.8
    @State private var ecoPoints: Int = 1850
    @State private var ridesShared: Int = 24
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header del Eco Hub
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 20))
                                .foregroundColor(ForkarTheme.greenEco)
                            Text("Forkar Eco Hub")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(ForkarTheme.text)
                        }
                        Text("Monitorea tu huella ecológica, rutas compartidas y puntos de reciclaje en tiempo real.")
                            .font(.system(size: 13))
                            .foregroundColor(ForkarTheme.textSub)
                    }
                    
                    Spacer()
                    
                    // Botón para canal CSMS Eco
                    Button(action: {
                        manager.activeCSMSRoomId = "00000000-0000-4000-8000-000000000002"
                        selectedTab = .csms
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Comunidad Eco en CSMS")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(ForkarTheme.greenEco)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Tarjetas de Métricas de Impacto
                HStack(spacing: 16) {
                    EcoMetricCard(
                        icon: "leaf.circle.fill",
                        title: "CO2 Evitado",
                        value: "\(String(format: "%.1f", co2SavedKg)) kg",
                        color: ForkarTheme.greenEco,
                        subtitle: "+12.4 kg este mes"
                    )
                    
                    EcoMetricCard(
                        icon: "bolt.heart.fill",
                        title: "Puntos Eco",
                        value: "\(ecoPoints)",
                        color: Color(hex: "#F59E0B"),
                        subtitle: "Nivel 4: Guardián Verde"
                    )
                    
                    EcoMetricCard(
                        icon: "car.2.fill",
                        title: "Viajes Compartidos",
                        value: "\(ridesShared)",
                        color: ForkarTheme.accent,
                        subtitle: "3 rutas activas"
                    )
                }
                
                // Sección de Estaciones Eco Validadas
                VStack(alignment: .leading, spacing: 14) {
                    Text("Estaciones de Reciclaje y Validación Cercanas")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                    
                    VStack(spacing: 10) {
                        EcoStationRow(
                            name: "Estación Central Unicentro",
                            address: "Av. 15 #124-30 • Bogotá",
                            type: "Plásticos & RAEE",
                            status: "Operativa",
                            distance: "0.8 km"
                        )
                        EcoStationRow(
                            name: "Punto Verde Parque 93",
                            address: "Cra 11A #93A-12 • Bogotá",
                            type: "Vidrio & Aluminio",
                            status: "Operativa",
                            distance: "1.4 km"
                        )
                        EcoStationRow(
                            name: "EcoStation Universidad",
                            address: "Cra 7 #40-62 • Bogotá",
                            type: "Baterías & Multiuso",
                            status: "Mantenimiento",
                            distance: "3.2 km"
                        )
                    }
                }
                .padding(20)
                .background(ForkarTheme.card)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ForkarTheme.border, lineWidth: 1)
                )
            }
            .padding(28)
            .frame(maxWidth: 860)
        }
        .frame(maxWidth: .infinity)
        .background(ForkarTheme.bg)
    }
}

// Tarjeta de Métrica Eco
struct EcoMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(ForkarTheme.text)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ForkarTheme.textSub)
            }
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(color)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ForkarTheme.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ForkarTheme.border, lineWidth: 1)
        )
    }
}

// Fila de Estación Eco
struct EcoStationRow: View {
    let name: String
    let address: String
    let type: String
    let status: String
    let distance: String
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(ForkarTheme.greenEco.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(ForkarTheme.greenEco)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                Text(address)
                    .font(.system(size: 11))
                    .foregroundColor(ForkarTheme.textSub)
            }
            
            Spacer()
            
            Text(type)
                .font(.system(size: 11))
                .foregroundColor(ForkarTheme.textSub)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ForkarTheme.card)
                .cornerRadius(6)
            
            Text(distance)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ForkarTheme.text)
        }
        .padding(.vertical, 6)
    }
}
