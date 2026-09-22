import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 🌿 FORKAR ECO HUB — FORKAR FOR PC (macOS)
// Dashboard dinámico conectado a Supabase forkman_user_eco
// Puntos reales de Cota, Chía y Bogotá + Registro de Acciones Verdes
// ══════════════════════════════════════════════════════════════════

struct ForkarEcoView: View {
    @EnvironmentObject var manager: SupabaseManager
    @Binding var selectedTab: NavigationTab
    
    @State private var isLoggingAction: Bool = false
    @State private var successToast: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header del Eco Hub con Logo Oficial
                HStack(alignment: .top) {
                    HStack(spacing: 12) {
                        ForkarLogoView(size: 40, showGlow: true)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(ForkarTheme.greenEco)
                                Text("Forkar Eco Hub")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(ForkarTheme.text)
                            }
                            Text("Impacto ambiental verificado y sincronizado con Supabase.")
                                .font(.system(size: 13))
                                .foregroundColor(ForkarTheme.textSub)
                        }
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
                
                if let toast = successToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ForkarTheme.greenEco)
                        Text(toast)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.text)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ForkarTheme.greenEco.opacity(0.15))
                    .cornerRadius(8)
                }
                
                // ─── MÉTRICAS DINÁMICAS DE SUPABASE (forkman_user_eco) ───
                HStack(spacing: 16) {
                    EcoMetricCard(
                        icon: "leaf.circle.fill",
                        title: "CO2 Evitado",
                        value: "\(String(format: "%.1f", manager.userEcoCo2Saved)) kg",
                        color: ForkarTheme.greenEco,
                        subtitle: "Sincronizado con Supabase"
                    )
                    
                    EcoMetricCard(
                        icon: "star.circle.fill",
                        title: "Puntos Verdes",
                        value: "\(manager.userEcoPoints)",
                        color: Color(hex: "#F59E0B"),
                        subtitle: "Nivel Sostenible"
                    )
                    
                    EcoMetricCard(
                        icon: "mappin.and.ellipse",
                        title: "Estaciones Activas",
                        value: "\(manager.ecoStations.count)",
                        color: ForkarTheme.accent,
                        subtitle: "Cota • Chía • Bogotá"
                    )
                }
                
                // ─── ACCIONES ECOLÓGICAS REALES (GUARDAR EN SUPABASE) ───
                VStack(alignment: .leading, spacing: 12) {
                    Text("Registrar Impacto Sostenible")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                    
                    HStack(spacing: 12) {
                        EcoActionButton(
                            title: "Ruta en Bici",
                            impact: "+1.8 kg CO2 • +50 pts",
                            icon: "bicycle",
                            color: ForkarTheme.greenEco,
                            isLoading: isLoggingAction
                        ) {
                            recordEcoAction(title: "Ruta en Bici Cota", co2: 1.8, points: 50)
                        }
                        
                        EcoActionButton(
                            title: "Reciclaje Plásticos",
                            impact: "+3.5 kg CO2 • +100 pts",
                            icon: "arrow.3.trianglepath",
                            color: Color(hex: "#F59E0B"),
                            isLoading: isLoggingAction
                        ) {
                            recordEcoAction(title: "Reciclaje de Plásticos", co2: 3.5, points: 100)
                        }
                        
                        EcoActionButton(
                            title: "Carpooling Forkar",
                            impact: "+5.2 kg CO2 • +150 pts",
                            icon: "car.2.fill",
                            color: ForkarTheme.accent,
                            isLoading: isLoggingAction
                        ) {
                            recordEcoAction(title: "Viaje Compartido Forkar", co2: 5.2, points: 150)
                        }
                    }
                }
                
                // ─── RED DE ESTACIONES REALES ───
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Red de Puntos de Acopio Reales (Cota • Chía • Bogotá)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                        Spacer()
                    }
                    
                    VStack(spacing: 10) {
                        ForEach(manager.ecoStations) { station in
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(ForkarTheme.greenEco.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: station.iconName)
                                            .foregroundColor(ForkarTheme.greenEco)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(station.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(ForkarTheme.text)
                                    Text(station.address)
                                        .font(.system(size: 11))
                                        .foregroundColor(ForkarTheme.textSub)
                                }
                                
                                Spacer()
                                
                                Text(station.type)
                                    .font(.system(size: 11))
                                    .foregroundColor(ForkarTheme.textSub)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ForkarTheme.card)
                                    .cornerRadius(6)
                                
                                Text(station.municipality)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(ForkarTheme.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ForkarTheme.accent.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 6)
                        }
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
        .onAppear {
            Task {
                await manager.fetchUserEcoStats()
            }
        }
    }
    
    private func recordEcoAction(title: String, co2: Double, points: Int) {
        guard manager.isAuthenticated else {
            successToast = "Inicia sesión para registrar tu impacto en la nube."
            return
        }
        
        isLoggingAction = true
        Task {
            do {
                try await manager.logEcoAction(title: title, co2Saved: co2, pointsEarned: points)
                successToast = "¡Acción registrada! +\(points) pts y +\(String(format: "%.1f", co2)) kg CO2 sumados en Supabase."
            } catch {
                successToast = error.localizedDescription
            }
            isLoggingAction = false
        }
    }
}

// Botón de Acción Rápida Eco
struct EcoActionButton: View {
    let title: String
    let impact: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ForkarTheme.textSub)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                
                Text(impact)
                    .font(.system(size: 10))
                    .foregroundColor(color)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ForkarTheme.card)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(ForkarTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
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
