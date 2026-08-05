import SwiftUI
import WidgetKit

struct ForkarEcoView: View {
    @EnvironmentObject var authManager: SupabaseManager
    @StateObject private var nfcReader = NFCReaderManager()
    
    @State private var co2Saved: Double = 0.0
    @State private var ecoPoints: Int = 0
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        MultiplatformNavigationStack {
            ZStack {
                ForkarTheme.bg.ignoresSafeArea()
                XtrapsBackground(strokeColor: Color.emerald, opacity: 0.6, rainbow: true).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Impact Header
                        VStack(spacing: 8) {
                            Text("🌿 FORKAR ECO HUB")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(Color.emerald)
                                .tracking(1.5)
                            
                            Text("\(co2Saved, specifier: "%.1f") kg")
                                .font(.system(size: 42, weight: .black))
                                .foregroundColor(.white)
                            
                            Text("CO₂ Ahorrado en tu perfil Forkar")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ForkarTheme.textSub)
                            
                            HStack(spacing: 16) {
                                Label("\(ecoPoints) Puntos Eco", systemImage: "star.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.top, 4)
                            
                            // Botones de Acción Eco & Dynamic Island
                            HStack(spacing: 12) {
                                Button(action: scanNFCTag) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "wave.3.right.circle.fill")
                                        Text("NFC Físico 📶")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(LinearGradient(colors: [Color.emerald, Color.blue], startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    DynamicIslandEcoManager.shared.startEcoLiveActivity(
                                        co2: co2Saved,
                                        pts: ecoPoints,
                                        userName: authManager.currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "Usuario"
                                    )
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "capsule.portrait.fill")
                                        Text("Activar Isla 🏝️")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.04))
                        .shineInlineCard(borderLineWidth: 2.0, shadowOffset: 4.0, backgroundColor: ForkarTheme.card)
                        .padding(.horizontal)
                        
                        // Retos
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RETOS ECOLÓGICOS FORKAR")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(ForkarTheme.textSub)
                                .padding(.horizontal)
                            
                            EcoActionCard(title: "🚴 Transporte Sostenible", desc: "Usa bici o camina (+1.5 kg CO₂)", pts: 30) {
                                completeAction(co2: 1.5, pts: 30, title: "Transporte Sostenible")
                            }
                            
                            EcoActionCard(title: "♻️ Separación de Residuos", desc: "Usa un punto verde municipal (+2.0 kg CO₂)", pts: 40) {
                                completeAction(co2: 2.0, pts: 40, title: "Separación de Residuos")
                            }
                            
                            EcoActionCard(title: "🔌 Reciclaje RAEE", desc: "Entrega de electrónicos en desuso (+3.5 kg CO₂)", pts: 70) {
                                completeAction(co2: 3.5, pts: 70, title: "Reciclaje RAEE")
                            }
                        }
                        
                        // Puntos de Recolección (Map Preview)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MAPA VERDE DE RECOLECCIÓN (COTA)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(ForkarTheme.textSub)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🟢 Centro de Acopio Municipal").font(.system(size: 13, weight: .bold))
                                Text("🔵 Punto Verde Parque Principal").font(.system(size: 13, weight: .bold))
                                Text("🟠 Punto RAEE Electrónicos").font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(ForkarTheme.text)
                            .font(.subheadline)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .shineInlineCard(borderLineWidth: 1.5, shadowOffset: 2.0, backgroundColor: ForkarTheme.card)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .background {
                    DynamicIslandEcoManager.shared.startEcoLiveActivity(
                        co2: co2Saved,
                        pts: ecoPoints,
                        userName: authManager.currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "Usuario"
                    )
                }
            }
        }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    
    private func scanNFCTag() {
        nfcReader.startScan { tagContent in
            if tagContent.contains("RAEE") || tagContent.contains("raee") {
                completeAction(co2: 3.5, pts: 70, title: "Punto RAEE NFC Físico")
            } else if tagContent.contains("bici") || tagContent.contains("Bici") {
                completeAction(co2: 1.5, pts: 30, title: "Estación Bici NFC Físico")
            } else {
                completeAction(co2: 2.0, pts: 40, title: "Punto Verde NFC Físico")
            }
        }
    }
    
    private func completeAction(co2: Double, pts: Int, title: String) {
        co2Saved += co2
        ecoPoints += pts
        
        UserDefaults.standard.set(co2Saved, forKey: "forkar_co2_saved")
        UserDefaults.standard.set(ecoPoints, forKey: "forkar_eco_points")
        WidgetCenter.shared.reloadAllTimelines()
        
        alertMessage = "¡Reto Registrado! 🌿\nHas registrado \"\(title)\": +\(String(format: "%.1f", co2)) kg CO₂ ahorrados y +\(pts) Puntos Eco."
        showSuccessAlert = true
        
        DynamicIslandEcoManager.shared.updateEcoLiveActivity(co2: co2Saved, pts: ecoPoints)
    }
}

struct EcoActionCard: View {
    let title: String
    let desc: String
    let pts: Int
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(ForkarTheme.textSub)
            }
            Spacer()
            
            Button(action: onComplete) {
                Text("+\(pts) pts")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.emerald)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .shineInlineCard(borderLineWidth: 1.5, shadowOffset: 2.0, backgroundColor: ForkarTheme.card)
        .padding(.horizontal)
    }
}

extension Color {
    static let emerald = Color(red: 16/255, green: 185/255, blue: 129/255)
}
