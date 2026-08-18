import SwiftUI
import WidgetKit

struct ForkarEcoView: View {
    @EnvironmentObject var authManager: SupabaseManager
    @StateObject private var nfcReader = NFCReaderManager()
    
    @State private var co2Saved: Double = UserDefaults.standard.double(forKey: "forkar_co2_saved")
    @State private var ecoPoints: Int = UserDefaults.standard.integer(forKey: "forkar_eco_points")
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""
    @State private var showQRScanner = false
    @State private var showMyQRCode = false
    @State private var qrScanResult: String? = nil
    
    var body: some View {
        MultiplatformNavigationStack {
            ZStack {
                ForkarTheme.bg.ignoresSafeArea()
                XtrapsBackground(strokeColor: Color.emerald, opacity: 0.6, rainbow: true).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Impact Header & Live Consumption
                        VStack(spacing: 8) {
                            Text("🌿 FORKAR ECO HUB")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(Color.emerald)
                                .tracking(1.5)
                            
                            Text("\(co2Saved, specifier: "%.1f") kg")
                                .font(.system(size: 42, weight: .black))
                                .foregroundColor(.white)
                            
                            Text("CO₂ Ahorrado • Monitoreo en Vivo")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ForkarTheme.textSub)
                            
                            HStack(spacing: 16) {
                                Label("\(ecoPoints) Puntos Eco", systemImage: "star.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.top, 4)
                            
                            // Botones de Acción: Escanear QR Nativo, Ver Mi QR, NFC e Isla
                            VStack(spacing: 10) {
                                HStack(spacing: 10) {
                                    Button(action: { showQRScanner = true }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "qrcode.viewfinder")
                                                .font(.system(size: 14, weight: .bold))
                                            Text("Escanear QR")
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.emerald, Color.green.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                        .shadow(color: Color.emerald.opacity(0.4), radius: 8, y: 3)
                                    }
                                    
                                    Button(action: { showMyQRCode = true }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "qrcode")
                                                .font(.system(size: 14, weight: .bold))
                                            Text("Mi Código QR")
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.08))
                                        .foregroundColor(ForkarTheme.text)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                    }
                                }
                                
                                HStack(spacing: 10) {
                                    Button(action: scanNFCTag) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "wave.3.right.circle.fill")
                                            Text("NFC Físico 📶")
                                        }
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.blue.opacity(0.3))
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.4), lineWidth: 1))
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
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.purple.opacity(0.3))
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.4), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.top, 12)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .liquidGlass(cornerRadius: 20, glowColor: Color.emerald)
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
                        .liquidGlass(cornerRadius: 16, glowColor: Color.emerald)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .sheet(isPresented: $showQRScanner) {
                EcoQRScannerView { scannedCode in
                    handleScannedQR(scannedCode)
                }
            }
            .sheet(isPresented: $showMyQRCode) {
                MyEcoQRCodeSheet(
                    userId: authManager.currentUser?.id.uuidString ?? "forkar_guest",
                    userName: authManager.currentUser?.email ?? "Usuario",
                    points: ecoPoints
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenEcoQRScanner"))) { _ in
                showQRScanner = true
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
    
    private func handleScannedQR(_ code: String) {
        if code.contains("RAEE") || code.contains("raee") {
            completeAction(co2: 3.5, pts: 70, title: "Punto RAEE QR")
        } else if code.contains("bici") || code.contains("Bici") || code.contains("bike") {
            completeAction(co2: 1.5, pts: 30, title: "Estación Bici QR")
        } else if code.contains("eco_pts_") {
            let ptsStr = code.replacingOccurrences(of: "eco_pts_", with: "")
            let pts = Int(ptsStr) ?? 50
            completeAction(co2: Double(pts) * 0.05, pts: pts, title: "Cupón Eco QR")
        } else {
            completeAction(co2: 2.0, pts: 40, title: "Punto Verde QR")
        }
    }
    
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

// MARK: - Native QR Scanner Component
struct EcoQRScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    let onScanned: (String) -> Void
    @State private var simulatedCode = "eco_pts_50"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text("Escanear Código QR Eco")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color.emerald)
                }
                .padding()
                
                Spacer()
                
                // Visor del Escáner con animación de radar
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.emerald, Color.white, Color.emerald],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 260, height: 260)
                    
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 120))
                        .foregroundColor(Color.emerald.opacity(0.3))
                    
                    Rectangle()
                        .fill(Color.emerald)
                        .frame(width: 240, height: 2)
                        .shadow(color: Color.emerald, radius: 10)
                }
                
                Text("Apunta la cámara al código QR de la estación verde o reto")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Botón de Escaneo Rápido / Simulación
                Button(action: {
                    onScanned(simulatedCode)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Registrar QR de Estación (+50 pts)")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.emerald)
                    .cornerRadius(14)
                    .shadow(color: Color.emerald.opacity(0.4), radius: 10, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Native QR Code Generator Sheet
struct MyEcoQRCodeSheet: View {
    @Environment(\.presentationMode) var presentationMode
    let userId: String
    let userName: String
    let points: Int
    
    var body: some View {
        ZStack {
            ForkarTheme.bg.ignoresSafeArea()
            XtrapsBackground(strokeColor: Color.emerald.opacity(0.2)).ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Text("Tu Código QR Forkar Eco")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                    Spacer()
                    Button("Listo") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color.emerald)
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .frame(width: 220, height: 220)
                            .shadow(color: Color.emerald.opacity(0.3), radius: 15)
                        
                        Image(systemName: "qrcode")
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 180, height: 180)
                            .foregroundColor(.black)
                    }
                    
                    VStack(spacing: 4) {
                        Text(userName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                        Text("\(points) Puntos Eco Acumulados")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.emerald)
                    }
                }
                .padding(24)
                .liquidGlass(cornerRadius: 24, glowColor: Color.emerald)
                
                Text("Muestra este código en comercios y estaciones aliadas para redimir o acumular puntos.")
                    .font(.system(size: 13))
                    .foregroundColor(ForkarTheme.textSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
        }
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
        .liquidGlass(cornerRadius: 14, glowColor: Color.emerald)
        .padding(.horizontal)
    }
}

extension Color {
    static let emerald = Color(red: 16/255, green: 185/255, blue: 129/255)
}
